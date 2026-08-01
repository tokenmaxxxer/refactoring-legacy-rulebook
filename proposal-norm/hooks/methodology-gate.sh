#!/usr/bin/env bash
# PreToolUse gate: mechanically enforces the proposal-norm methodology (six
# required elements of an ADR-shaped proposal) on phase-1 refactoring-legacy
# proposal writes. Migrated onto core's gate-house standard (issue-72,
# reference-adopted per issue-13's precondition — see
# docs/issue-13/proposals/proposal.md). Content (which six elements, which
# aliases) stays this rulebook's own logic; trap/kill-switch/JSON-parse/
# path-normalize/write-reconstruction are gate-lib's.
#
# Kill switch: export PROPOSAL_NORM_GATE_OFF=1
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
gate_trap_fail_closed
set -uo pipefail

gate_kill_switch_active "${PROPOSAL_NORM_GATE_OFF:-}" || { trap - EXIT; exit 0; }

payload="$(cat 2>/dev/null || true)"

# Bash-tool coverage: a Bash write to an in-scope path is opaque to
# reconstruction, so it is refused outright rather than approximated.
tool_name="$(printf '%s' "$payload" | GATE_LIB_PY="$GATE_LIB_PY" python3 -c '
import importlib.util, json, os, sys
spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(spec); spec.loader.exec_module(gate_lib)
def deny(m):
    sys.stderr.write("proposal-norm gate: DENY — " + m + "\n"); sys.exit(2)
event = gate_lib.gate_parse_json_or_deny(sys.stdin.read(), deny)
print(event.get("tool_name") or "")
')"

if [ "$tool_name" = "Bash" ]; then
  command_str="$(printf '%s' "$payload" | python3 -c '
import json, sys
try:
    event = json.loads(sys.stdin.read())
except Exception:
    print("")
    sys.exit(0)
print((event.get("tool_input") or {}).get("command") or "")
')"
  while IFS= read -r tok; do
    [ -n "$tok" ] || continue
    case "$tok" in
      *docs/issue-*/proposals/*.md)
        echo "proposal-norm gate: DENY — a Bash-tool write toward $tok cannot have its resulting content reconstructed by this gate; use Write/Edit/MultiEdit for docs/issue-<n>/proposals/*.md, or run this Bash command outside that scope" >&2
        exit 2
        ;;
    esac
  done <<EOF
$(gate_bash_write_targets "$command_str")
EOF
  exit 0
fi

PY_OUTPUT="$(printf '%s' "$payload" | GATE_LIB_PY="$GATE_LIB_PY" python3 -c '
import importlib.util, json, os, posixpath, re, sys

spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(spec); spec.loader.exec_module(gate_lib)


def deny(msg):
    sys.stderr.write("proposal-norm gate: DENY — " + msg + "\n")
    sys.exit(2)


event = gate_lib.gate_parse_json_or_deny(sys.stdin.read(), deny)
tool_name = event.get("tool_name", "")
tool_input = event.get("tool_input") or {}
cwd = event.get("cwd") or os.getcwd()
file_path = tool_input.get("file_path")

if not file_path or not isinstance(file_path, str):
    deny("tool_input.file_path missing")

root = os.path.abspath(cwd)
rel = gate_lib.gate_normalize_path(root, file_path)
if rel is None or not re.search(r"^docs/issue-[0-9]+/proposals/.*\.md$", rel):
    sys.exit(0)

resolved_path = posixpath.join(root.replace("\\", "/"), rel)
existing = None
if os.path.isfile(resolved_path):
    try:
        with open(resolved_path, "r", encoding="utf-8", errors="replace") as f:
            existing = f.read()
    except OSError:
        existing = None
else:
    existing = ""

new_text, ok = gate_lib.gate_reconstruct_write(tool_name, tool_input, existing)
if not ok:
    deny(
        "cannot determine the resulting content of this %s on %s from the "
        "tool_input given (e.g. an Edit old_string not present in the "
        "current file); refusing rather than guessing" % (tool_name, rel)
    )

effective = new_text
low = effective.lower()

# --- section/adjacency structure, not bare substring-anywhere -----------
HEADING_RE = re.compile(r"^(#{1,3})\s+(.*)$", re.M)
headings = [(m.start(), len(m.group(1)), m.group(2).strip()) for m in HEADING_RE.finditer(effective)]


def section_text(idx):
    """Body text following heading `idx`, up to the next heading of the
    same or shallower level (or EOF)."""
    start, level, _ = headings[idx]
    body_start = effective.find("\n", start)
    body_start = body_start + 1 if body_start >= 0 else len(effective)
    end = len(effective)
    for j in range(idx + 1, len(headings)):
        if headings[j][1] <= level:
            end = headings[j][0]
            break
    return effective[body_start:end]


front_matter = effective[: headings[0][0]] if headings else effective
# A proposal opens with `# Title` and its Basis/citation line lives in that
# top heading own body (before the first H2) — also eligible as "front
# matter", distinct from the pre-heading text (which is empty whenever the
# document starts with its own top-level heading, as every proposal here
# does).
title_body = section_text(0) if headings and headings[0][1] == 1 else ""


def under_alias(alias_re, needle_subs):
    """True if needle_subs (any-of, lowercased) appear either in the
    document front matter (before the first heading, or in the top-level
    title own body, where a proposal opening Basis/citation line
    conventionally lives) or in the body of a heading whose title matches
    alias_re."""
    if any(s in front_matter.lower() for s in needle_subs):
        return True
    if any(s in title_body.lower() for s in needle_subs):
        return True
    for i, (_, _, title) in enumerate(headings):
        if alias_re.search(title):
            body = section_text(i).lower()
            if any(s in body for s in needle_subs):
                return True
    return False


missing = []

survey_alias = re.compile(r"survey|basis|근거", re.I)
if not under_alias(survey_alias, ["survey.md"]):
    missing.append("1 (survey.md reference under a survey/basis heading or front matter)")

scout_alias = re.compile(r"survey|basis|근거|scout", re.I)
if not (under_alias(scout_alias, ["scout-brief.md"]) and under_alias(scout_alias, ["sources:"])):
    missing.append("2 (scout-brief.md reference w/ Sources: under a scout/basis heading or front matter)")

citation_alias = re.compile(r"survey|basis|근거|methodology|citation", re.I)
citation_markers = ["feathers", "fowler", "working effectively with legacy code", "refactoring:"]
if not under_alias(citation_alias, citation_markers):
    missing.append("3 (methodology citation under a basis/methodology heading or front matter)")

# ADR shape: >=2 of Context/Options/Decision/Consequences as HEADING TITLES
# themselves (not body text anywhere) — singular or plural, case-insensitive.
adr_markers = [r"context", r"options?", r"decisions?", r"consequences?"]
adr_hit = sum(1 for pat in adr_markers if any(re.search(r"\b%s\b" % pat, title, re.I) for _, _, title in headings))
if adr_hit < 2:
    missing.append("4 (ADR-shaped structure: >=2 of Context/Options/Decision/Consequences as headings)")

if not any(re.search(r"out[\s-]?of[\s-]?scope|범위\s?밖", title, re.I) for _, _, title in headings):
    missing.append("5 (out-of-scope heading)")

if not any(re.search(r"verification|검증", title, re.I) for _, _, title in headings):
    missing.append("6 (verification-criteria heading)")

if missing:
    deny("missing required element(s): " + ", ".join(missing))

sys.exit(0)
' 2>&1 1>/dev/null)"
PY_EXIT=$?

if [ $PY_EXIT -ne 0 ]; then
  if [ -n "$PY_OUTPUT" ]; then
    echo "$PY_OUTPUT" >&2
  else
    echo "proposal-norm gate: DENY — internal error running methodology gate" >&2
  fi
  exit 2
fi

exit 0
