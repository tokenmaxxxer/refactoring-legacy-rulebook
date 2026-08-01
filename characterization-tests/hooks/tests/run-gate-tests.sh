#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATE="$SCRIPT_DIR/../methodology-gate.sh"

FAILS=0
TOTAL=0

# run_case builds a tmpdir git repo, optionally drops a characterization
# test fixture file (so the path/exists/non-empty check can pass), writes
# `prior_content` at target_rel, then evaluates a Write of `new_content`.
run_case() {
  local name="$1"
  local target_rel="$2"
  local prior_content="$3"
  local new_content="$4"
  local expected_exit="$5"
  local extra_env="${6:-}"
  local drop_test_fixture="${7:-1}"

  TOTAL=$((TOTAL + 1))

  local tmpdir
  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/char-gate-test.XXXXXX")"
  (
    cd "$tmpdir" || exit 99
    git init -q .

    mkdir -p "$(dirname "$target_rel")"
    if [ -n "$prior_content" ]; then
      printf '%s' "$prior_content" > "$target_rel"
    fi

    if [ "$drop_test_fixture" = "1" ]; then
      mkdir -p test
      printf 'def test_foo():\n    assert True\n' > test/foo_characterization_test.py
    fi

    local json
    json=$(python3 - "$target_rel" "$new_content" <<'PYEOF'
import json, sys
file_path = sys.argv[1]
content = sys.argv[2]
payload = {
    "tool_name": "Write",
    "tool_input": {
        "file_path": file_path,
        "content": content
    },
    "cwd": "."
}
print(json.dumps(payload))
PYEOF
)

    if [ -n "$extra_env" ]; then
      export $extra_env
    fi

    echo "$json" | bash "$GATE" >/dev/null 2>&1
    exit $?
  )
  local actual_exit=$?
  rm -rf "$tmpdir"

  if [ "$actual_exit" -eq "$expected_exit" ]; then
    echo "PASS: $name (exit $actual_exit)"
  else
    echo "FAIL: $name (expected exit $expected_exit, got $actual_exit)"
    FAILS=$((FAILS + 1))
  fi
}

# run_raw evaluates a prebuilt JSON payload against a caller-prepared tmpdir
# (caller owns setup/teardown) — used by the gate-house mandatory cases
# below, which need finer control than run_case's Write-only shape.
run_raw() {
  local name="$1"
  local expected_exit="$2"
  local tmpdir="$3"
  local json="$4"
  local extra_env="${5:-}"

  TOTAL=$((TOTAL + 1))
  local actual_exit
  if [ -n "$extra_env" ]; then
    actual_exit="$(cd "$tmpdir" && printf '%s' "$json" | env "$extra_env" bash "$GATE" >/dev/null 2>&1; echo $?)"
  else
    actual_exit="$(cd "$tmpdir" && printf '%s' "$json" | bash "$GATE" >/dev/null 2>&1; echo $?)"
  fi

  if [ "$actual_exit" -eq "$expected_exit" ]; then
    echo "PASS: $name (exit $actual_exit)"
  else
    echo "FAIL: $name (expected exit $expected_exit, got $actual_exit)"
    FAILS=$((FAILS + 1))
  fi
}

FULL_RECORD="## Seam
We added a characterization test using an object seam to substitute the dependency.

characterization_tests_path: test/foo_characterization_test.py
test_run: PASS (pytest test/foo_characterization_test.py)
"

# Case 1: seam heading + adjacent path/test_run PASS, path exists -> exit 0
run_case \
  "evidence + seam heading + adjacent PASS test_run, path exists" \
  "docs/issue-99/reports/refactoring-legacy.md" \
  "" \
  "$FULL_RECORD" \
  0

# Case 2: missing characterization-test evidence phrase -> exit 2
run_case \
  "missing characterization-test evidence" \
  "docs/issue-99/reports/refactoring-legacy.md" \
  "" \
  "## Seam
We used a seam to substitute the dependency for testing.

characterization_tests_path: test/foo_characterization_test.py
test_run: PASS (pytest test/foo_characterization_test.py)
" \
  2

# Case 3: "seam" mentioned only as a bare word, not under a seam heading -> exit 2
run_case \
  "seam mentioned but not under a seam heading (bare-word loophole closed)" \
  "docs/issue-99/reports/refactoring-legacy.md" \
  "" \
  "## Evidence
We added a characterization test via a seam to capture existing behavior.

characterization_tests_path: test/foo_characterization_test.py
test_run: PASS (pytest test/foo_characterization_test.py)
" \
  2

# Case 4: missing characterization_tests_path field -> exit 2
run_case \
  "missing characterization_tests_path field" \
  "docs/issue-99/reports/refactoring-legacy.md" \
  "" \
  "## Seam
We added a characterization test using a seam to substitute the dependency.
test_run: PASS (pytest)
" \
  2

# Case 5: write to unrelated path -> exit 0 (scope no-op)
run_case \
  "write to unrelated path" \
  "docs/issue-99/proposals/other.md" \
  "" \
  "Nothing relevant here at all." \
  0 \
  "" \
  0

# Case 6: kill switch on -> exit 0
run_case \
  "kill switch on" \
  "docs/issue-99/reports/refactoring-legacy.md" \
  "" \
  "Nothing relevant here at all." \
  0 \
  "CHARACTERIZATION_TESTS_GATE_OFF=1"

# Case 7: characterization_tests_path and test_run present but not adjacent
# (more than 3 lines apart) -> exit 2.
run_case \
  "path and test_run not adjacent (>3 lines apart)" \
  "docs/issue-99/reports/refactoring-legacy.md" \
  "" \
  "## Seam
We added a characterization test using a seam to substitute the dependency.

characterization_tests_path: test/foo_characterization_test.py



test_run: PASS (pytest)
" \
  2

# Case 8: test_run asserts FAIL, not PASS -> exit 2.
run_case \
  "test_run FAIL denies" \
  "docs/issue-99/reports/refactoring-legacy.md" \
  "" \
  "## Seam
We added a characterization test using a seam to substitute the dependency.

characterization_tests_path: test/foo_characterization_test.py
test_run: FAIL (pytest)
" \
  2

# Case 9: characterization_tests_path names a file that does not exist on
# disk -> exit 2 (fixes the audit's defect-4 existence half).
run_case \
  "characterization_tests_path names a nonexistent file" \
  "docs/issue-99/reports/refactoring-legacy.md" \
  "" \
  "## Seam
We added a characterization test using a seam to substitute the dependency.

characterization_tests_path: test/does_not_exist_test.py
test_run: PASS (pytest)
" \
  2 \
  "" \
  0

# --- gate-house-standard mandatory cases (issue-13/issue-72) -------------

# 10. Edit with replace_all:true against a multiply-occurring old_string.
d="$(mktemp -d)"; (cd "$d" && git init -q)
mkdir -p "$d/docs/issue-99/reports" "$d/test"
printf 'def test_foo():\n    assert True\n' > "$d/test/foo_characterization_test.py"
printf '%s' "$FULL_RECORD" > "$d/docs/issue-99/reports/refactoring-legacy.md"
json="$(python3 -c '
import json
print(json.dumps({"tool_name":"Edit","tool_input":{"file_path":"docs/issue-99/reports/refactoring-legacy.md","old_string":"dependency.","new_string":"dependency, dependency.","replace_all":True},"cwd":"."}))
')"
run_raw "Edit replace_all:true reconstructs full text" 0 "$d" "$json" ""
rm -rf "$d"

# 11. MultiEdit with mixed replace_all true/false — a false-replace_all edit
# that removes the adjacent test_run line must be honored (deny).
d="$(mktemp -d)"; (cd "$d" && git init -q)
mkdir -p "$d/docs/issue-99/reports" "$d/test"
printf 'def test_foo():\n    assert True\n' > "$d/test/foo_characterization_test.py"
printf '%s' "$FULL_RECORD" > "$d/docs/issue-99/reports/refactoring-legacy.md"
json="$(python3 -c '
import json
print(json.dumps({"tool_name":"MultiEdit","tool_input":{"file_path":"docs/issue-99/reports/refactoring-legacy.md","edits":[
    {"old_string":"test_run: PASS (pytest test/foo_characterization_test.py)\n","new_string":"","replace_all":False},
    {"old_string":"object seam","new_string":"an object seam, twice, an object seam","replace_all":True}
]},"cwd":"."}))
')"
run_raw "MultiEdit mixed replace_all denies on removed test_run" 2 "$d" "$json" ""
rm -rf "$d"

# 12. Malformed JSON (truncated) -> fail closed.
d="$(mktemp -d)"; (cd "$d" && git init -q)
run_raw "malformed JSON (truncated) denies" 2 "$d" '{"tool_name":"Write","tool_in' ""
rm -rf "$d"

# 13. Malformed JSON (non-object top level) -> fail closed.
d="$(mktemp -d)"; (cd "$d" && git init -q)
run_raw "malformed JSON (non-object) denies" 2 "$d" '"just a string"' ""
rm -rf "$d"

# 14. Malformed JSON (empty payload) -> fail closed.
d="$(mktemp -d)"; (cd "$d" && git init -q)
run_raw "malformed JSON (empty) denies" 2 "$d" '' ""
rm -rf "$d"

# 15. Kill switch set to an unrecognized value must stay ACTIVE.
run_case \
  "kill switch unrecognized value stays active" \
  "docs/issue-99/reports/refactoring-legacy.md" \
  "" \
  "Nothing relevant here at all." \
  2 \
  "CHARACTERIZATION_TESTS_GATE_OFF=bogus"

# 16. Absolute file_path matches the same scope a relative fixture matches,
# plus a ./-prefixed variant.
d="$(mktemp -d)"; (cd "$d" && git init -q)
mkdir -p "$d/docs/issue-99/reports"
json="$(python3 -c "
import json
print(json.dumps({'tool_name':'Write','tool_input':{'file_path':'$d/docs/issue-99/reports/refactoring-legacy.md','content':'nothing here'},'cwd':'.'}))
")"
run_raw "absolute file_path matches the same scope" 2 "$d" "$json" ""
json="$(python3 -c '
import json
print(json.dumps({"tool_name":"Write","tool_input":{"file_path":"./docs/issue-99/reports/refactoring-legacy.md","content":"nothing here"},"cwd":"."}))
')"
run_raw "./-prefixed file_path matches the same scope" 2 "$d" "$json" ""
rm -rf "$d"

# 17. A Bash-tool write reaching the same target a Write-tool call would
# hit is denied outright (opaque to reconstruction).
d="$(mktemp -d)"; (cd "$d" && git init -q)
mkdir -p "$d/docs/issue-99/reports"
json="$(python3 -c '
import json
print(json.dumps({"tool_name":"Bash","tool_input":{"command":"cat > docs/issue-99/reports/refactoring-legacy.md <<EOF\nnothing here\nEOF"},"cwd":"."}))
')"
run_raw "Bash-tool write to in-scope path is denied" 2 "$d" "$json" ""
rm -rf "$d"

echo "----"
echo "Total: $TOTAL, Failed: $FAILS"

if [ "$FAILS" -gt 0 ]; then
  exit 1
fi
exit 0
