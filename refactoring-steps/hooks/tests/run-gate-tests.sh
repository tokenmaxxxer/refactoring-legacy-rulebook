#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATE="$SCRIPT_DIR/../methodology-gate.sh"

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

run_case() {
  local name="$1"
  local expected="$2"
  local json="$3"
  local tmpdir="$4"
  local extra_env="${5:-}"

  local actual
  local errfile="${TMPDIR:-/tmp}/gate_test_err"
  if [ -n "$extra_env" ]; then
    actual="$(cd "$tmpdir" && printf '%s' "$json" | env "$extra_env" bash "$GATE" >/dev/null 2>"$errfile"; echo $?)"
  else
    actual="$(cd "$tmpdir" && printf '%s' "$json" | bash "$GATE" >/dev/null 2>"$errfile"; echo $?)"
  fi

  if [ "$actual" = "$expected" ]; then
    echo "PASS: $name"
  else
    echo "FAIL: $name (expected exit $expected, got $actual)"
    cat "$errfile"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

new_tmpdir() {
  local d
  d="$(mktemp -d "${TMPDIR:-/tmp}/refactoring-steps-gate-test.XXXXXX")"
  (cd "$d" && git init -q && git config user.email t@t.com && git config user.name t && git checkout -q -b issue-42/refactoring-legacy)
  echo "$d"
}

json_write() {
  # $1 file_path, $2 content, $3 cwd
  python3 -c '
import json, sys
print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[1],"content":sys.argv[2]},"cwd":sys.argv[3]}))
' "$1" "$2" "$3"
}

FULL_RECORD='## Refactoring steps
- Applied Extract Method to the function.

refactoring_name: Extract Method

## Equivalence
Confirmed behavioral equivalence via test/foo_test.py.

mechanics: extracted the block into a new function and replaced the call site.
'

# Case 1: catalog step (as a list item under a refactoring-steps heading) +
# equivalence note (under an equivalence heading, naming a concrete test).
d="$(new_tmpdir)"
mkdir -p "$d/docs/issue-42/reports"
j="$(json_write "docs/issue-42/reports/refactoring-legacy.md" "$FULL_RECORD" "$d")"
run_case "record: catalog steps + equivalence note present" 0 "$j" "$d"

# Case 2: missing catalog step name
d="$(new_tmpdir)"
mkdir -p "$d/docs/issue-42/reports"
j="$(json_write "docs/issue-42/reports/refactoring-legacy.md" "## Equivalence
Confirmed behavioral equivalence via test/foo_test.py.
" "$d")"
run_case "record: missing catalog step name" 2 "$j" "$d"

# Case 2b: "catalog" bare-word loophole closed — the word alone, even under
# the right heading as a list item, no longer counts as a real step name.
d="$(new_tmpdir)"
mkdir -p "$d/docs/issue-42/reports"
j="$(json_write "docs/issue-42/reports/refactoring-legacy.md" "## Refactoring steps
- Used a catalog approach.

## Equivalence
Confirmed behavioral equivalence via test/foo_test.py.
" "$d")"
run_case "record: bare word catalog no longer satisfies the catalog-step check" 2 "$j" "$d"

# Case 2c: catalog step mentioned but not as a list item under the heading
# (structure upgrade, not just presence-anywhere).
d="$(new_tmpdir)"
mkdir -p "$d/docs/issue-42/reports"
j="$(json_write "docs/issue-42/reports/refactoring-legacy.md" "We applied Extract Method to the function.

## Equivalence
Confirmed behavioral equivalence via test/foo_test.py.
" "$d")"
run_case "record: catalog step mentioned outside a list item under the heading denies" 2 "$j" "$d"

# Case 3: missing equivalence note
d="$(new_tmpdir)"
mkdir -p "$d/docs/issue-42/reports"
j="$(json_write "docs/issue-42/reports/refactoring-legacy.md" "## Refactoring steps
- Applied Extract Method to the function.
" "$d")"
run_case "record: missing equivalence note" 2 "$j" "$d"

# Case 3b: equivalence note present but with no concrete test-name-shaped
# referent (structure upgrade over the bare 'equivalence' substring check).
d="$(new_tmpdir)"
mkdir -p "$d/docs/issue-42/reports"
j="$(json_write "docs/issue-42/reports/refactoring-legacy.md" "## Refactoring steps
- Applied Extract Method to the function.

## Equivalence
Tests pass.
" "$d")"
run_case "record: equivalence note with no named test denies" 2 "$j" "$d"

# Case 4: strangler without seam -> exit 2
d="$(new_tmpdir)"
mkdir -p "$d/docs/issue-42/reports"
j="$(json_write "docs/issue-42/reports/refactoring-legacy.md" "## Refactoring steps
- Used strangler fig migration.

## Equivalence
Confirmed equivalence via test/foo_test.py.
" "$d")"
run_case "record: strangler mentioned without seam" 2 "$j" "$d"

# Case 5: strangler with seam -> exit 0
d="$(new_tmpdir)"
mkdir -p "$d/docs/issue-42/reports"
j="$(json_write "docs/issue-42/reports/refactoring-legacy.md" "## Refactoring steps
- Used strangler fig migration behind a stable seam at the API gateway.

refactoring_name: strangler fig migration

## Equivalence
Confirmed equivalence via test/foo_test.py.

mechanics: routed new traffic through the seam while the old path stayed live.
" "$d")"
run_case "record: strangler mentioned with seam" 0 "$j" "$d"

# Case 6: src edit blocked, no characterization_tests_path yet
d="$(new_tmpdir)"
mkdir -p "$d/docs/issue-42/reports" "$d/src"
cat > "$d/docs/issue-42/reports/refactoring-legacy.md" <<'EOF'
# Refactoring record
Applied Extract Method. Confirmed equivalence.
EOF
j="$(json_write "src/foo.py" "def foo(): pass" "$d")"
run_case "src edit blocked, no characterization_tests_path yet" 2 "$j" "$d"

# Case 7: src edit allowed after characterization_tests_path present
d="$(new_tmpdir)"
mkdir -p "$d/docs/issue-42/reports" "$d/src"
cat > "$d/docs/issue-42/reports/refactoring-legacy.md" <<'EOF'
# Refactoring record
characterization_tests_path: test/foo_char_test.py
EOF
j="$(json_write "src/foo.py" "def foo(): pass" "$d")"
run_case "src edit allowed after characterization_tests_path present" 0 "$j" "$d"

# Case 8: unrelated path
d="$(new_tmpdir)"
j="$(json_write "README.md" "arbitrary content" "$d")"
run_case "write to unrelated path" 0 "$j" "$d"

# Case 9: kill switch on
d="$(new_tmpdir)"
mkdir -p "$d/src"
j="$(json_write "src/foo.py" "def foo(): pass" "$d")"
run_case "kill switch on" 0 "$j" "$d" "REFACTORING_STEPS_GATE_OFF=1"

# --- issue-20 spec-vocabulary regression cases ---------------------------

# 9b. missing refactoring_name: field under the refactoring-steps heading
d="$(new_tmpdir)"
mkdir -p "$d/docs/issue-42/reports"
j="$(json_write "docs/issue-42/reports/refactoring-legacy.md" "## Refactoring steps
- Applied Extract Method to the function.

## Equivalence
Confirmed behavioral equivalence via test/foo_test.py.

mechanics: extracted the block into a new function and replaced the call site.
" "$d")"
run_case "record: missing refactoring_name: field denies" 2 "$j" "$d"

# 9c. missing mechanics: field under the equivalence heading
d="$(new_tmpdir)"
mkdir -p "$d/docs/issue-42/reports"
j="$(json_write "docs/issue-42/reports/refactoring-legacy.md" "## Refactoring steps
- Applied Extract Method to the function.

refactoring_name: Extract Method

## Equivalence
Confirmed behavioral equivalence via test/foo_test.py.
" "$d")"
run_case "record: missing mechanics: field denies" 2 "$j" "$d"

# 9c2. first Equivalence heading incomplete, a second Equivalence heading
# carries the test reference and mechanics: field -> must still pass (guards
# against stopping the scan at the first matching heading).
d="$(new_tmpdir)"
mkdir -p "$d/docs/issue-42/reports"
j="$(json_write "docs/issue-42/reports/refactoring-legacy.md" "## Refactoring steps
- Applied Extract Method to the function.

refactoring_name: Extract Method

## Equivalence
Draft notes, not yet complete.

## Equivalence
Confirmed behavioral equivalence via test/foo_test.py.

mechanics: extracted the block into a new function and replaced the call site.
" "$d")"
run_case "record: second Equivalence heading with test+mechanics still passes" 0 "$j" "$d"

# 9d. all spec fields present -> exit 0
d="$(new_tmpdir)"
mkdir -p "$d/docs/issue-42/reports"
j="$(json_write "docs/issue-42/reports/refactoring-legacy.md" "$FULL_RECORD" "$d")"
run_case "record: refactoring_name and mechanics present passes" 0 "$j" "$d"

# --- gate-house-standard mandatory cases (issue-13/issue-72) -------------

# 10. Edit with replace_all:true against a multiply-occurring old_string.
d="$(new_tmpdir)"
mkdir -p "$d/docs/issue-42/reports"
printf '%s' "$FULL_RECORD" > "$d/docs/issue-42/reports/refactoring-legacy.md"
j="$(python3 -c '
import json
print(json.dumps({"tool_name":"Edit","tool_input":{"file_path":"docs/issue-42/reports/refactoring-legacy.md","old_string":"test/foo_test.py","new_string":"test/foo_test.py and test/foo_test.py","replace_all":True},"cwd":"."}))
')"
run_case "Edit replace_all:true reconstructs full text" 0 "$j" "$d"

# 11. MultiEdit with mixed replace_all true/false — a false-replace_all edit
# that removes the equivalence heading must be honored (deny).
d="$(new_tmpdir)"
mkdir -p "$d/docs/issue-42/reports"
printf '%s' "$FULL_RECORD" > "$d/docs/issue-42/reports/refactoring-legacy.md"
j="$(python3 -c '
import json
print(json.dumps({"tool_name":"MultiEdit","tool_input":{"file_path":"docs/issue-42/reports/refactoring-legacy.md","edits":[
    {"old_string":"## Equivalence\nConfirmed behavioral equivalence via test/foo_test.py.\n","new_string":"","replace_all":False},
    {"old_string":"Extract Method","new_string":"Extract Method, Extract Method","replace_all":True}
]},"cwd":"."}))
')"
run_case "MultiEdit mixed replace_all denies on removed equivalence section" 2 "$j" "$d"

# 12. Malformed JSON (truncated) -> fail closed.
d="$(new_tmpdir)"
run_case "malformed JSON (truncated) denies" 2 '{"tool_name":"Write","tool_in' "$d"

# 13. Malformed JSON (non-object top level) -> fail closed.
d="$(new_tmpdir)"
run_case "malformed JSON (non-object) denies" 2 '"just a string"' "$d"

# 14. Malformed JSON (empty payload) -> fail closed.
d="$(new_tmpdir)"
run_case "malformed JSON (empty) denies" 2 '' "$d"

# 15. Kill switch set to an unrecognized value must stay ACTIVE.
d="$(new_tmpdir)"
mkdir -p "$d/src"
j="$(json_write "src/foo.py" "def foo(): pass" "$d")"
run_case "kill switch unrecognized value stays active" 2 "$j" "$d" "REFACTORING_STEPS_GATE_OFF=bogus"

# 16. Absolute file_path matches the same scope a relative fixture matches,
# plus a ./-prefixed variant.
d="$(new_tmpdir)"
mkdir -p "$d/docs/issue-42/reports"
j="$(python3 -c "
import json
print(json.dumps({'tool_name':'Write','tool_input':{'file_path':'$d/docs/issue-42/reports/refactoring-legacy.md','content':'nothing here'},'cwd':'.'}))
")"
run_case "absolute file_path matches the same scope" 2 "$j" "$d"
j="$(json_write "./docs/issue-42/reports/refactoring-legacy.md" "nothing here" "$d")"
run_case "./-prefixed file_path matches the same scope" 2 "$j" "$d"

# 17. A Bash-tool write reaching the same target a Write-tool call would
# hit is denied outright.
d="$(new_tmpdir)"
mkdir -p "$d/docs/issue-42/reports"
j="$(python3 -c '
import json
print(json.dumps({"tool_name":"Bash","tool_input":{"command":"cat > docs/issue-42/reports/refactoring-legacy.md <<EOF\nnothing here\nEOF"},"cwd":"."}))
')"
run_case "Bash-tool write to record path is denied" 2 "$j" "$d"

d="$(new_tmpdir)"
mkdir -p "$d/src"
j="$(python3 -c '
import json
print(json.dumps({"tool_name":"Bash","tool_input":{"command":"sed -i s/x/y/ src/foo.py"},"cwd":"."}))
')"
run_case "Bash-tool write to src/** path is denied" 2 "$j" "$d"

# 18. Missing core: CLAUDE_PLUGIN_ROOT_CORE points at a nonexistent path and
# no sibling ../../core is present (issue-16 defect 1) -> guarded source
# fails closed, exit 2.
d="$(new_tmpdir)"
mkdir -p "$d/src"
j="$(json_write "src/foo.py" "def foo(): pass" "$d")"
run_case "missing core: unresolvable CLAUDE_PLUGIN_ROOT_CORE fails closed" 2 "$j" "$d" "CLAUDE_PLUGIN_ROOT_CORE=/nonexistent-core-path-xyz"

echo "----"
if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "RESULT: $FAIL_COUNT test(s) FAILED"
  exit 1
else
  echo "RESULT: all tests PASSED"
  exit 0
fi
