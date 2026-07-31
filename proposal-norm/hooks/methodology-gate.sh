#!/usr/bin/env bash
set -uo pipefail

# a. Kill switch FIRST.
if [ "${PROPOSAL_NORM_GATE_OFF:-}" = "1" ]; then
    exit 0
fi

# b. Read entire stdin.
INPUT_JSON="$(cat)"

# c-g. Delegate parsing and evaluation to python3; fail-closed on any error.
PY_OUTPUT="$(printf '%s' "$INPUT_JSON" | python3 -c '
import json
import re
import os
import sys

def fail(msg):
    sys.stderr.write(msg + "\n")
    sys.exit(2)

try:
    raw = sys.stdin.read()
    data = json.loads(raw)
except Exception as e:
    fail("proposal-norm gate: DENY — could not parse PreToolUse JSON: %s" % e)

try:
    tool_name = data.get("tool_name", "")
    tool_input = data.get("tool_input", {}) or {}
    cwd = data.get("cwd") or os.getcwd()
    file_path = tool_input.get("file_path")

    if not file_path:
        fail("proposal-norm gate: DENY — tool_input.file_path missing")

    # d. Scope check.
    if not re.search(r"docs/issue-[0-9]+/proposals/.*\.md$", file_path):
        sys.exit(0)

    # e. Compute effective text.
    resolved_path = file_path if os.path.isabs(file_path) else os.path.join(cwd, file_path)
    try:
        with open(resolved_path, "r") as f:
            existing = f.read()
    except Exception:
        existing = ""

    if tool_name == "Write":
        new_text = tool_input.get("content", "") or ""
    elif tool_name == "Edit":
        new_text = tool_input.get("new_string", "") or ""
    elif tool_name == "MultiEdit":
        edits = tool_input.get("edits", []) or []
        new_text = "".join((e.get("new_string", "") or "") for e in edits)
    else:
        new_text = ""

    effective = existing + new_text
    effective_lower = effective.lower()

    missing = []

    # 1. survey.md
    if "survey.md" not in effective_lower:
        missing.append("1 (survey.md reference)")

    # 2. scout-brief.md AND Sources:
    if not ("scout-brief.md" in effective_lower and "sources:" in effective_lower):
        missing.append("2 (scout-brief reference w/ Sources)")

    # 3. methodology citation
    citation_markers = ["feathers", "fowler", "working effectively with legacy code", "refactoring:"]
    if not any(m in effective_lower for m in citation_markers):
        missing.append("3 (methodology citation)")

    # 4. ADR-shaped structure: at least 2 of Context/Option/Decision/Consequence
    adr_markers = ["context", "option", "decision", "consequence"]
    adr_count = sum(1 for m in adr_markers if m in effective_lower)
    if adr_count < 2:
        missing.append("4 (ADR-shaped structure)")

    # 5. out of scope
    if not (re.search(r"out[\s-]?of[\s-]?scope", effective, re.IGNORECASE) or ("범위 밖" in effective)):
        missing.append("5 (out-of-scope)")

    # 6. verification criteria
    if not ("verification criteria" in effective_lower or "검증 기준" in effective):
        missing.append("6 (verification criteria)")

    if missing:
        fail("proposal-norm gate: DENY — missing required element(s): " + ", ".join(missing))

    sys.exit(0)
except SystemExit:
    raise
except Exception as e:
    fail("proposal-norm gate: DENY — internal error during evaluation: %s" % e)
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
