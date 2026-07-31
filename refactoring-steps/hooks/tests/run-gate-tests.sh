#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATE="$SCRIPT_DIR/../methodology-gate.sh"

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

# Case 1: catalog + equivalence present
d="$(new_tmpdir)"
mkdir -p "$d/docs/issue-42/reports"
j="$(json_write "docs/issue-42/reports/refactoring-legacy.md" "Applied Extract Method. Confirmed behavioral equivalence via tests." "$d")"
run_case "record: catalog steps + equivalence note present" 0 "$j" "$d"

# Case 2: missing catalog step name
d="$(new_tmpdir)"
mkdir -p "$d/docs/issue-42/reports"
j="$(json_write "docs/issue-42/reports/refactoring-legacy.md" "Confirmed behavioral equivalence via tests." "$d")"
run_case "record: missing catalog step name" 2 "$j" "$d"

# Case 3: missing equivalence note
d="$(new_tmpdir)"
mkdir -p "$d/docs/issue-42/reports"
j="$(json_write "docs/issue-42/reports/refactoring-legacy.md" "Applied Extract Method to the function." "$d")"
run_case "record: missing equivalence note" 2 "$j" "$d"

# Case 4: strangler without seam
d="$(new_tmpdir)"
mkdir -p "$d/docs/issue-42/reports"
j="$(json_write "docs/issue-42/reports/refactoring-legacy.md" "Applied Extract Method. Confirmed equivalence. Used strangler fig migration." "$d")"
run_case "record: strangler mentioned without seam" 2 "$j" "$d"

# Case 5: strangler with seam
d="$(new_tmpdir)"
mkdir -p "$d/docs/issue-42/reports"
j="$(json_write "docs/issue-42/reports/refactoring-legacy.md" "Applied Extract Method. Confirmed equivalence. Used strangler fig migration behind a stable seam at the API gateway." "$d")"
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

echo "----"
if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "RESULT: $FAIL_COUNT test(s) FAILED"
  exit 1
else
  echo "RESULT: all tests PASSED"
  exit 0
fi
