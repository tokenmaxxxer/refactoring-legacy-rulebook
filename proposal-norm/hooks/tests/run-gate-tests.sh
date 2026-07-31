#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATE_SCRIPT="$SCRIPT_DIR/../methodology-gate.sh"

FAIL_COUNT=0
TOTAL_COUNT=0

# Full content with all six elements present.
FULL_CONTENT='# Proposal

See survey.md for the survey and scout-brief.md for scouting.

Sources: https://example.com/a, https://example.com/b

Methodology citation: Fowler, Refactoring: Improving the Design of Existing Code.

## Context
We have legacy code.

## Options
A, B, C.

## Decision
We chose B.

## Consequences
Some tradeoffs.

Out of scope: unrelated modules.

This proposal includes verification criteria for success.
'

run_case() {
    local case_name="$1"
    local expected_exit="$2"
    local file_path="$3"
    local content="$4"
    local prior_content="$5"
    local extra_env="$6"

    TOTAL_COUNT=$((TOTAL_COUNT + 1))

    local tmpdir
    tmpdir="$(mktemp -d)"
    (cd "$tmpdir" && git init -q)

    if [ -n "$prior_content" ]; then
        mkdir -p "$tmpdir/$(dirname "$file_path")"
        printf '%s' "$prior_content" > "$tmpdir/$file_path"
    fi

    local json
    json="$(python3 -c '
import json, sys
file_path, content = sys.argv[1], sys.argv[2]
print(json.dumps({
    "tool_name": "Write",
    "tool_input": {"file_path": file_path, "content": content},
    "cwd": "."
}))
' "$file_path" "$content")"

    local actual_exit
    local out_file err_file
    out_file="$(mktemp)"
    err_file="$(mktemp)"
    if [ -n "$extra_env" ]; then
        (cd "$tmpdir" && env "$extra_env" bash -c "printf '%s' \"\$1\" | \"$GATE_SCRIPT\"" _ "$json" >"$out_file" 2>"$err_file")
        actual_exit=$?
    else
        (cd "$tmpdir" && printf '%s' "$json" | bash "$GATE_SCRIPT" >"$out_file" 2>"$err_file")
        actual_exit=$?
    fi
    rm -f "$out_file" "$err_file"

    rm -rf "$tmpdir"

    if [ "$actual_exit" -eq "$expected_exit" ]; then
        echo "PASS $case_name"
    else
        echo "FAIL $case_name (expected exit $expected_exit, got $actual_exit)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

# 1. All six elements present.
run_case "all six elements present" 0 "docs/issue-99/proposals/test.md" "$FULL_CONTENT" "" ""

# 2. Missing element 1 (survey).
CONTENT_NO_SURVEY="${FULL_CONTENT//survey.md for the survey and /}"
run_case "missing element 1 (survey)" 2 "docs/issue-99/proposals/test.md" "$CONTENT_NO_SURVEY" "" ""

# 3. Missing element 2 (scout-brief/Sources).
CONTENT_NO_SCOUT="${FULL_CONTENT//scout-brief.md for scouting/}"
CONTENT_NO_SCOUT="${CONTENT_NO_SCOUT//Sources: https:\/\/example.com\/a, https:\/\/example.com\/b/}"
run_case "missing element 2 (scout-brief/Sources)" 2 "docs/issue-99/proposals/test.md" "$CONTENT_NO_SCOUT" "" ""

# 4. Missing element 3 (methodology citation).
CONTENT_NO_CITATION="${FULL_CONTENT//Methodology citation: Fowler, Refactoring: Improving the Design of Existing Code./Methodology citation removed.}"
run_case "missing element 3 (methodology citation)" 2 "docs/issue-99/proposals/test.md" "$CONTENT_NO_CITATION" "" ""

# 5. Missing element 4 (ADR structure) — fewer than 2 of Context/Option/Decision/Consequence.
CONTENT_NO_ADR='# Proposal

See survey.md for the survey and scout-brief.md for scouting.

Sources: https://example.com/a

Methodology citation: Fowler, Refactoring: Improving the Design of Existing Code.

Out of scope: unrelated modules.

This proposal includes verification criteria for success.
'
run_case "missing element 4 (ADR structure)" 2 "docs/issue-99/proposals/test.md" "$CONTENT_NO_ADR" "" ""

# 6. Missing element 5 (out-of-scope).
CONTENT_NO_SCOPE="${FULL_CONTENT//Out of scope: unrelated modules./}"
run_case "missing element 5 (out-of-scope)" 2 "docs/issue-99/proposals/test.md" "$CONTENT_NO_SCOPE" "" ""

# 7. Missing element 6 (verification criteria).
CONTENT_NO_VERIFY="${FULL_CONTENT//This proposal includes verification criteria for success./}"
run_case "missing element 6 (verification criteria)" 2 "docs/issue-99/proposals/test.md" "$CONTENT_NO_VERIFY" "" ""

# 8. Write to unrelated path — out of scope, allow.
run_case "write to unrelated path" 0 "src/foo.py" "print('hello world')" "" ""

# 9. Kill switch on — content missing everything, but gate should be off.
run_case "kill switch on" 0 "docs/issue-99/proposals/test.md" "nothing here" "" "PROPOSAL_NORM_GATE_OFF=1"

echo ""
echo "Summary: $((TOTAL_COUNT - FAIL_COUNT))/$TOTAL_COUNT passed"

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
fi
exit 0
