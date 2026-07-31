#!/usr/bin/env bash
# PreToolUse gate: mechanically enforces characterization-testing methodology
# (Feathers, "Working Effectively with Legacy Code") on phase-2 refactoring-legacy
# report writes. See ../CANON.md for the methodology reference.
set -uo pipefail

# (a) Kill switch first.
if [ "${CHARACTERIZATION_TESTS_GATE_OFF:-}" = "1" ]; then
  exit 0
fi

STDIN_JSON="$(cat)"

RESULT="$(CHARACTERIZATION_GATE_STDIN_JSON="$STDIN_JSON" python3 - <<'PYEOF' 2>/dev/null
import json
import re
import sys
import os

try:
    payload = json.loads(os.environ.get("CHARACTERIZATION_GATE_STDIN_JSON", ""))

    tool_name = payload.get("tool_name", "")
    tool_input = payload.get("tool_input") or {}
    file_path = tool_input.get("file_path")
    cwd = payload.get("cwd") or ""

    if not file_path:
        print("MISSING_FILE_PATH")
        sys.exit(0)

    scope_re = re.compile(r"docs/issue-[0-9]+/reports/refactoring-legacy\.md$")
    if not scope_re.search(file_path):
        print("OUT_OF_SCOPE")
        sys.exit(0)

    # Resolve on-disk path relative to cwd if file_path is relative.
    resolved_path = file_path
    if not os.path.isabs(resolved_path) and cwd:
        resolved_path = os.path.join(cwd, file_path)

    existing = ""
    if os.path.isfile(resolved_path):
        with open(resolved_path, "r", encoding="utf-8", errors="replace") as f:
            existing = f.read()

    new_text = ""
    if tool_name == "Write":
        new_text = tool_input.get("content", "") or ""
    elif tool_name == "Edit":
        new_text = tool_input.get("new_string", "") or ""
    elif tool_name == "MultiEdit":
        edits = tool_input.get("edits") or []
        new_text = "".join((e.get("new_string", "") or "") for e in edits)
    else:
        new_text = tool_input.get("content", "") or tool_input.get("new_string", "") or ""

    effective = existing + new_text
    lower = effective.lower()

    missing = []

    has_evidence = ("characterization test" in lower) or ("특성화 테스트" in effective)
    if not has_evidence:
        missing.append("characterization-test evidence")

    has_seam = "seam" in lower
    if not has_seam:
        missing.append("seam")

    field_re = re.compile(r"characterization_tests_path:\s*\S+")
    has_field = bool(field_re.search(effective))
    if not has_field:
        missing.append("characterization_tests_path field")

    if missing:
        print("DENY:" + ", ".join(missing))
    else:
        print("ALLOW")
except Exception as exc:
    print("ERROR:" + str(exc))
PYEOF
)"
PY_EXIT=$?

if [ $PY_EXIT -ne 0 ]; then
  echo "characterization-tests gate: DENY — internal error running parser (fail-closed)" >&2
  exit 2
fi

case "$RESULT" in
  MISSING_FILE_PATH)
    echo "characterization-tests gate: DENY — missing tool_input.file_path (fail-closed)" >&2
    exit 2
    ;;
  OUT_OF_SCOPE)
    exit 0
    ;;
  ALLOW)
    exit 0
    ;;
  DENY:*)
    echo "characterization-tests gate: DENY — missing: ${RESULT#DENY:}" >&2
    exit 2
    ;;
  ERROR:*)
    echo "characterization-tests gate: DENY — internal error: ${RESULT#ERROR:} (fail-closed)" >&2
    exit 2
    ;;
  *)
    echo "characterization-tests gate: DENY — unrecognized gate result (fail-closed)" >&2
    exit 2
    ;;
esac
