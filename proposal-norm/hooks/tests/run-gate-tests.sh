#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATE_SCRIPT="$SCRIPT_DIR/../methodology-gate.sh"

# test-env resolution (docs/specs/test-env-resolution.md, issue #551):
# SKIP with exit 75 when core is unreachable, instead of running every
# case against an unresolvable gate and reporting misleading FAILs.
CORE_CANDIDATE="$SCRIPT_DIR/../../../core/hooks/lib/gate-lib.sh"
if { [ -n "${CLAUDE_PLUGIN_ROOT_CORE:-}" ] && [ -s "$CLAUDE_PLUGIN_ROOT_CORE/hooks/lib/gate-lib.sh" ]; } \
  || [ -s "$CORE_CANDIDATE" ]; then
  :
else
  echo "SKIP: core plugin unreachable — unverifiable outside spawn env (see docs/specs/test-env-resolution.md, issue #551)" >&2
  exit 75
fi

FAIL_COUNT=0
TOTAL_COUNT=0

# Full content with all six elements present, structurally (headings, not
# bare substrings): survey/scout-brief/citation sit in the title's own
# body (the front-matter alias location); out-of-scope and verification
# criteria are their own headings, matching gate's section-anchored checks.
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

## Out of scope
Unrelated modules.

## Verification criteria
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

## Out of scope
Unrelated modules.

## Verification criteria
This proposal includes verification criteria for success.
'
run_case "missing element 4 (ADR structure)" 2 "docs/issue-99/proposals/test.md" "$CONTENT_NO_ADR" "" ""

# 6. Missing element 5 (out-of-scope) — no heading matching out-of-scope.
CONTENT_NO_SCOPE="${FULL_CONTENT//$'\n''## Out of scope'$'\n''Unrelated modules.'$'\n'/$'\n'}"
run_case "missing element 5 (out-of-scope)" 2 "docs/issue-99/proposals/test.md" "$CONTENT_NO_SCOPE" "" ""

# 7. Missing element 6 (verification criteria) — no heading matching verification.
CONTENT_NO_VERIFY="${FULL_CONTENT//$'\n''## Verification criteria'$'\n''This proposal includes verification criteria for success.'$'\n'/$'\n'}"
run_case "missing element 6 (verification criteria)" 2 "docs/issue-99/proposals/test.md" "$CONTENT_NO_VERIFY" "" ""

# 10. Bare-word loophole closed: "catalog"-style single stray keyword
# mention anywhere in the body, with no matching heading, must still deny —
# proves the section/adjacency upgrade, not just a renamed substring check.
LOOPHOLE_CONTENT='# Proposal

survey.md scout-brief.md Sources: x Fowler context option decision consequence
out of scope verification criteria mentioned in passing, not as headings.
'
run_case "bare-word mentions with no matching headings still deny" 2 "docs/issue-99/proposals/test.md" "$LOOPHOLE_CONTENT" "" ""

# 8. Write to unrelated path — out of scope, allow.
run_case "write to unrelated path" 0 "src/foo.py" "print('hello world')" "" ""

# 9. Kill switch on — content missing everything, but gate should be off.
run_case "kill switch on" 0 "docs/issue-99/proposals/test.md" "nothing here" "" "PROPOSAL_NORM_GATE_OFF=1"

# --- gate-house-standard mandatory cases (issue-13/issue-72) -------------

run_raw() {
    local case_name="$1"
    local expected_exit="$2"
    local tmpdir="$3"
    local json="$4"
    local extra_env="$5"

    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    local actual_exit
    if [ -n "$extra_env" ]; then
        actual_exit="$(cd "$tmpdir" && printf '%s' "$json" | env "$extra_env" bash "$GATE_SCRIPT" >/dev/null 2>&1; echo $?)"
    else
        actual_exit="$(cd "$tmpdir" && printf '%s' "$json" | bash "$GATE_SCRIPT" >/dev/null 2>&1; echo $?)"
    fi

    if [ "$actual_exit" -eq "$expected_exit" ]; then
        echo "PASS $case_name"
    else
        echo "FAIL $case_name (expected exit $expected_exit, got $actual_exit)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

# 10. Edit with replace_all:true against a multiply-occurring old_string —
# every occurrence must be reconstructed (not just the first).
d="$(mktemp -d)"; (cd "$d" && git init -q)
mkdir -p "$d/docs/issue-99/proposals"
printf '%s' "$FULL_CONTENT" > "$d/docs/issue-99/proposals/test.md"
json="$(python3 -c '
import json
print(json.dumps({"tool_name":"Edit","tool_input":{"file_path":"docs/issue-99/proposals/test.md","old_string":"tradeoffs.","new_string":"tradeoffs, tradeoffs.","replace_all":True},"cwd":"."}))
')"
run_raw "Edit replace_all:true reconstructs full text" 0 "$d" "$json" ""
rm -rf "$d"

# 11. MultiEdit with mixed replace_all true/false edits, each honored
# independently — deny one required element via a false-replace_all edit
# that only removes the first occurrence.
d="$(mktemp -d)"; (cd "$d" && git init -q)
mkdir -p "$d/docs/issue-99/proposals"
printf '%s' "$FULL_CONTENT" > "$d/docs/issue-99/proposals/test.md"
json="$(python3 -c '
import json
print(json.dumps({"tool_name":"MultiEdit","tool_input":{"file_path":"docs/issue-99/proposals/test.md","edits":[
    {"old_string":"## Out of scope\nUnrelated modules.\n","new_string":"","replace_all":False},
    {"old_string":"Some tradeoffs.","new_string":"Some tradeoffs, still some tradeoffs.","replace_all":True}
]},"cwd":"."}))
')"
run_raw "MultiEdit mixed replace_all denies on removed out-of-scope heading" 2 "$d" "$json" ""
rm -rf "$d"

# 12. Malformed JSON (truncated) on stdin — fail closed.
d="$(mktemp -d)"; (cd "$d" && git init -q)
run_raw "malformed JSON (truncated) denies" 2 "$d" '{"tool_name":"Write","tool_in' ""
rm -rf "$d"

# 13. Malformed JSON (non-object top level) — fail closed.
d="$(mktemp -d)"; (cd "$d" && git init -q)
run_raw "malformed JSON (non-object) denies" 2 "$d" '"just a string"' ""
rm -rf "$d"

# 14. Malformed JSON (empty payload) — fail closed.
d="$(mktemp -d)"; (cd "$d" && git init -q)
run_raw "malformed JSON (empty) denies" 2 "$d" '' ""
rm -rf "$d"

# 15. Kill switch set to an unrecognized value must stay ACTIVE (the
# issue-72-confirmed fail-open bug: any unrecognized value used to disable).
run_case "kill switch unrecognized value stays active" 2 "docs/issue-99/proposals/test.md" "nothing here" "" "PROPOSAL_NORM_GATE_OFF=bogus"

# 16. Absolute file_path matching the same scope a relative fixture
# matches, plus a ./-prefixed variant.
d="$(mktemp -d)"; (cd "$d" && git init -q)
mkdir -p "$d/docs/issue-99/proposals"
json="$(python3 -c "
import json
print(json.dumps({'tool_name':'Write','tool_input':{'file_path':'$d/docs/issue-99/proposals/test.md','content':'nothing here'},'cwd':'.'}))
")"
run_raw "absolute file_path matches the same scope" 2 "$d" "$json" ""
json="$(python3 -c '
import json
print(json.dumps({"tool_name":"Write","tool_input":{"file_path":"./docs/issue-99/proposals/test.md","content":"nothing here"},"cwd":"."}))
')"
run_raw "./-prefixed file_path matches the same scope" 2 "$d" "$json" ""
rm -rf "$d"

# 17. A Bash-tool write reaching the same target a Write-tool call would
# hit is denied (opaque to reconstruction), not silently passed through.
d="$(mktemp -d)"; (cd "$d" && git init -q)
mkdir -p "$d/docs/issue-99/proposals"
json="$(python3 -c '
import json
print(json.dumps({"tool_name":"Bash","tool_input":{"command":"cat > docs/issue-99/proposals/test.md <<EOF\nnothing here\nEOF"},"cwd":"."}))
')"
run_raw "Bash-tool write to in-scope path is denied" 2 "$d" "$json" ""
rm -rf "$d"

# 18. Missing core: CLAUDE_PLUGIN_ROOT_CORE points at a nonexistent path and
# no sibling ../../core is present (issue-16 defect 1) -> guarded source
# fails closed, exit 2.
run_case "missing core: unresolvable CLAUDE_PLUGIN_ROOT_CORE fails closed" 2 "docs/issue-99/proposals/test.md" "nothing here" "" "CLAUDE_PLUGIN_ROOT_CORE=/nonexistent-core-path-xyz"

echo ""
echo "Summary: $((TOTAL_COUNT - FAIL_COUNT))/$TOTAL_COUNT passed"

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
fi
exit 0
