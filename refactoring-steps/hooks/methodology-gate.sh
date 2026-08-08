#!/usr/bin/env bash
# PreToolUse gate: mechanically enforces refactoring-steps methodology
# (Fowler's catalog + before/after equivalence) on phase-2 refactoring-legacy
# report writes, and blocks src/** structural edits until a
# characterization_tests_path has been recorded (characterize before
# refactor). Migrated onto core's gate-house standard (issue-72,
# reference-adopted per issue-13's precondition — see
# docs/issue-13/proposals/proposal.md).
#
# Kill switch: export REFACTORING_STEPS_GATE_OFF=1
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "methodology-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail

gate_kill_switch_active "${REFACTORING_STEPS_GATE_OFF:-}" || { trap - EXIT; exit 0; }

payload="$(cat 2>/dev/null || true)"

tool_name="$(printf '%s' "$payload" | GATE_LIB_PY="$GATE_LIB_PY" python3 -c '
import importlib.util, os, sys
spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(spec); spec.loader.exec_module(gate_lib)
def deny(m):
    sys.stderr.write("refactoring-steps gate: DENY — " + m + "\n"); sys.exit(2)
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
      *docs/issue-*/reports/refactoring-legacy.md|*src/*|src/*)
        echo "refactoring-steps gate: DENY — a Bash-tool write toward $tok cannot have its resulting content reconstructed by this gate; use Write/Edit/MultiEdit, or run this Bash command outside src/** and docs/issue-<n>/reports/refactoring-legacy.md" >&2
        exit 2
        ;;
    esac
  done <<EOF
$(gate_bash_write_targets "$command_str")
EOF
  exit 0
fi

PY_OUTPUT="$(printf '%s' "$payload" | GATE_LIB_PY="$GATE_LIB_PY" python3 -c '
import importlib.util, os, posixpath, re, subprocess, sys

spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(spec); spec.loader.exec_module(gate_lib)


def deny(msg):
    sys.stderr.write("refactoring-steps gate: DENY — " + msg + "\n")
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
if rel is None:
    sys.exit(0)

# --- BRANCH 1: the phase-2 record itself ---------------------------------
if re.search(r"^docs/issue-[0-9]+/reports/refactoring-legacy\.md$", rel):
    resolved_path = posixpath.join(root.replace("\\", "/"), rel)
    existing = ""
    if os.path.isfile(resolved_path):
        try:
            with open(resolved_path, "r", encoding="utf-8", errors="replace") as f:
                existing = f.read()
        except OSError:
            existing = None

    new_text, ok = gate_lib.gate_reconstruct_write(tool_name, tool_input, existing)
    if not ok:
        deny(
            "cannot determine the resulting content of this %s on %s from "
            "the tool_input given; refusing rather than guessing" % (tool_name, rel)
        )

    effective = new_text
    low = effective.lower()

    HEADING_RE = re.compile(r"^(#{1,3})\s+(.*)$", re.M)
    headings = [(m.start(), len(m.group(1)), m.group(2).strip()) for m in HEADING_RE.finditer(effective)]

    def section_text(idx):
        start, level, _ = headings[idx]
        body_start = effective.find("\n", start)
        body_start = body_start + 1 if body_start >= 0 else len(effective)
        end = len(effective)
        for j in range(idx + 1, len(headings)):
            if headings[j][1] <= level:
                end = headings[j][0]
                break
        return effective[body_start:end]

    steps_heading_re = re.compile(r"refactoring steps|리팩터링\s?단계", re.I)
    # "catalog" alone is dropped: every other term already names a specific,
    # identifiable step; a bare mention of "catalog" names nothing.
    catalog_terms = ["extract method", "extract function", "rename", "inline",
                      "move method", "move function", "refactoring.com/catalog",
                      "strangler"]
    item_re = re.compile(r"^\s*[-*]\s+(.*)$", re.M)

    name_field_re = re.compile(r"^[ \t]*refactoring_name:[ \t]*\S", re.M)

    has_catalog = False
    has_name_field = False
    for i, (_, _, title) in enumerate(headings):
        if steps_heading_re.search(title):
            steps_section = section_text(i)
            for m in item_re.finditer(steps_section):
                item = m.group(1).lower()
                if any(t in item for t in catalog_terms):
                    has_catalog = True
                    break
            if name_field_re.search(steps_section):
                has_name_field = True
        if has_catalog and has_name_field:
            break

    equiv_heading_re = re.compile(r"equivalence|동등성", re.I)
    test_ref_re = re.compile(r"[./\w-]*/[\w.-]+|(?:[Tt]est_[\w.]+|[\w.]*[Tt]est\b)")
    mechanics_field_re = re.compile(r"^[ \t]*mechanics:[ \t]*\S", re.M)
    has_equivalence = False
    has_mechanics = False
    for i, (_, _, title) in enumerate(headings):
        if equiv_heading_re.search(title):
            equiv_section = section_text(i)
            if test_ref_re.search(equiv_section):
                has_equivalence = True
            if mechanics_field_re.search(equiv_section):
                has_mechanics = True
        if has_equivalence and has_mechanics:
            break

    reasons = []
    if not has_catalog:
        reasons.append(
            "no catalog refactoring step found as a list item under a "
            "\"refactoring steps\" heading (e.g. Extract Method, Rename, "
            "Inline, Move Method, strangler)"
        )
    if not has_name_field:
        reasons.append(
            "no refactoring_name: field under the \"refactoring steps\" "
            "heading (spec required field, the catalog step name)"
        )
    if not has_equivalence:
        reasons.append(
            "no before/after equivalence note found under an "
            "\"equivalence\"/동등성 heading naming a concrete test (path-like "
            "or test_/Test-prefixed identifier)"
        )
    if not has_mechanics:
        reasons.append(
            "no mechanics: field under the \"equivalence\" heading (spec "
            "required field, naming the applied step sequence)"
        )

    seam_re = re.compile(r"\bseam\b", re.I)
    if "strangler" in low and not seam_re.search(low):
        reasons.append("strangler-fig mentioned but no stable seam described (\"seam\")")

    if reasons:
        deny("phase-2 record missing required content: " + "; ".join(reasons))
    sys.exit(0)

# --- BRANCH 2: src/** structural edit ------------------------------------
if re.match(r"^src/", rel) or "/src/" in ("/" + rel):
    branch_dir = cwd if cwd else "."
    try:
        out = subprocess.run(["git", "-C", branch_dir, "symbolic-ref", "--short", "HEAD"],
                              capture_output=True, text=True)
        current_branch = out.stdout.strip() if out.returncode == 0 else ""
        if not current_branch:
            out = subprocess.run(["git", "-C", branch_dir, "rev-parse", "--abbrev-ref", "HEAD"],
                                  capture_output=True, text=True)
            current_branch = out.stdout.strip() if out.returncode == 0 else ""
    except Exception:
        current_branch = ""

    m = re.match(r"^issue-([0-9]+)/", current_branch)
    if not m:
        deny("cannot determine issue number from branch name to locate phase-2 record")
    issue_num = m.group(1)

    try:
        out = subprocess.run(["git", "-C", branch_dir, "rev-parse", "--show-toplevel"],
                              capture_output=True, text=True)
        repo_root = out.stdout.strip() if out.returncode == 0 else ""
    except Exception:
        repo_root = ""
    if not repo_root:
        deny("cannot determine repo root")

    record_path = posixpath.join(repo_root.replace("\\", "/"), "docs/issue-%s/reports/refactoring-legacy.md" % issue_num)
    if os.path.isfile(record_path):
        with open(record_path, "r", encoding="utf-8", errors="replace") as f:
            record_text = f.read()
        if re.search(r"characterization_tests_path:\s*\S+", record_text):
            sys.exit(0)
    deny(
        "structural src/** edit blocked: no characterization_tests_path "
        "recorded yet in docs/issue-%s/reports/refactoring-legacy.md "
        "(characterize before refactor)" % issue_num
    )

sys.exit(0)
' 2>&1 1>/dev/null)"
PY_EXIT=$?

if [ $PY_EXIT -ne 0 ]; then
  if [ -n "$PY_OUTPUT" ]; then
    echo "$PY_OUTPUT" >&2
  else
    echo "refactoring-steps gate: DENY — internal error running methodology gate" >&2
  fi
  exit 2
fi

exit 0
