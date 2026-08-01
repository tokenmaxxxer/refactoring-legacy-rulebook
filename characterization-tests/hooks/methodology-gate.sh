#!/usr/bin/env bash
# PreToolUse gate: mechanically enforces characterization-testing methodology
# (Feathers, "Working Effectively with Legacy Code") on phase-2 refactoring-legacy
# report writes. See ../CANON.md for the methodology reference. Migrated onto
# core's gate-house standard (issue-72, reference-adopted per issue-13's
# precondition — see docs/issue-13/proposals/proposal.md).
#
# Kill switch: export CHARACTERIZATION_TESTS_GATE_OFF=1
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
gate_trap_fail_closed
set -uo pipefail

gate_kill_switch_active "${CHARACTERIZATION_TESTS_GATE_OFF:-}" || { trap - EXIT; exit 0; }

payload="$(cat 2>/dev/null || true)"

tool_name="$(printf '%s' "$payload" | GATE_LIB_PY="$GATE_LIB_PY" python3 -c '
import importlib.util, os, sys
spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(spec); spec.loader.exec_module(gate_lib)
def deny(m):
    sys.stderr.write("characterization-tests gate: DENY — " + m + "\n"); sys.exit(2)
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
      *docs/issue-*/reports/refactoring-legacy.md)
        echo "characterization-tests gate: DENY — a Bash-tool write toward $tok cannot have its resulting content reconstructed by this gate; use Write/Edit/MultiEdit for docs/issue-<n>/reports/refactoring-legacy.md, or run this Bash command outside that scope" >&2
        exit 2
        ;;
    esac
  done <<EOF
$(gate_bash_write_targets "$command_str")
EOF
  exit 0
fi

PY_OUTPUT="$(printf '%s' "$payload" | GATE_LIB_PY="$GATE_LIB_PY" python3 -c '
import importlib.util, os, posixpath, re, sys

spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
gate_lib = importlib.util.module_from_spec(spec); spec.loader.exec_module(gate_lib)


def deny(msg):
    sys.stderr.write("characterization-tests gate: DENY — " + msg + "\n")
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
if rel is None or not re.search(r"^docs/issue-[0-9]+/reports/refactoring-legacy\.md$", rel):
    sys.exit(0)

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
        "cannot determine the resulting content of this %s on %s from the "
        "tool_input given; refusing rather than guessing" % (tool_name, rel)
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


missing = []

has_evidence = ("characterization test" in low) or ("특성화 테스트" in effective)
if not has_evidence:
    missing.append("characterization-test evidence")

seam_alias = re.compile(r"\bseam\b", re.I)
has_seam_heading = any(seam_alias.search(title) for _, _, title in headings)
if not has_seam_heading:
    missing.append("a heading naming the seam (\"seam\" in a heading title, not a bare mention)")

# characterization_tests_path: and test_run: must be adjacent (within 3
# lines of each other) so a path and a claimed run result cannot be stated
# in unrelated parts of the record.
path_m = re.search(r"^[ \t]*characterization_tests_path:[ \t]*(\S+)[ \t]*$", effective, re.M)
run_m = re.search(r"^[ \t]*test_run:[ \t]*(PASS|FAIL)\b.*$", effective, re.M)

if not path_m:
    missing.append("characterization_tests_path field")
if not run_m:
    missing.append("test_run: <PASS|FAIL> (<command>) field")

if path_m and run_m:
    path_line = effective.count("\n", 0, path_m.start())
    run_line = effective.count("\n", 0, run_m.start())
    if abs(path_line - run_line) > 3:
        missing.append("characterization_tests_path and test_run must be within 3 lines of each other")
    elif run_m.group(1) != "PASS":
        missing.append("test_run must assert PASS, not %s" % run_m.group(1))
    else:
        tests_path = path_m.group(1)
        rel_tests = gate_lib.gate_normalize_path(root, tests_path)
        if rel_tests is None:
            missing.append("characterization_tests_path resolves outside the repo root")
        else:
            abs_tests = posixpath.join(root.replace("\\", "/"), rel_tests)
            if not (os.path.isfile(abs_tests) and os.path.getsize(abs_tests) > 0):
                missing.append(
                    "characterization_tests_path (%s) must resolve to a file that exists on disk and is non-empty" % tests_path
                )

if missing:
    deny("missing/invalid: " + "; ".join(missing))

sys.exit(0)
' 2>&1 1>/dev/null)"
PY_EXIT=$?

if [ $PY_EXIT -ne 0 ]; then
  if [ -n "$PY_OUTPUT" ]; then
    echo "$PY_OUTPUT" >&2
  else
    echo "characterization-tests gate: DENY — internal error running methodology gate" >&2
  fi
  exit 2
fi

exit 0
