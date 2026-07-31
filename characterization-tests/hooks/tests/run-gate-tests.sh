#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATE="$SCRIPT_DIR/../methodology-gate.sh"

FAILS=0
TOTAL=0

run_case() {
  local name="$1"
  local target_rel="$2"
  local prior_content="$3"
  local new_content="$4"
  local expected_exit="$5"
  local extra_env="${6:-}"

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

# Case 1: evidence + seam both present -> exit 0
run_case \
  "evidence + seam both present" \
  "docs/issue-99/reports/refactoring-legacy.md" \
  "" \
  "We added a characterization test using an object seam to substitute the dependency.
characterization_tests_path: test/foo_characterization_test.py" \
  0

# Case 2: missing characterization-test evidence -> exit 2
run_case \
  "missing characterization-test evidence" \
  "docs/issue-99/reports/refactoring-legacy.md" \
  "" \
  "We used a seam to substitute the dependency for testing.
characterization_tests_path: test/foo_characterization_test.py" \
  2

# Case 3: missing seam -> exit 2
run_case \
  "missing seam" \
  "docs/issue-99/reports/refactoring-legacy.md" \
  "" \
  "We added a characterization test to capture existing behavior.
characterization_tests_path: test/foo_characterization_test.py" \
  2

# Case 4: missing characterization_tests_path field -> exit 2
run_case \
  "missing characterization_tests_path field" \
  "docs/issue-99/reports/refactoring-legacy.md" \
  "" \
  "We added a characterization test using a seam to substitute the dependency." \
  2

# Case 5: write to unrelated path -> exit 0 (scope no-op)
run_case \
  "write to unrelated path" \
  "docs/issue-99/proposals/other.md" \
  "" \
  "Nothing relevant here at all." \
  0

# Case 6: kill switch on -> exit 0
run_case \
  "kill switch on" \
  "docs/issue-99/reports/refactoring-legacy.md" \
  "" \
  "Nothing relevant here at all." \
  0 \
  "CHARACTERIZATION_TESTS_GATE_OFF=1"

echo "----"
echo "Total: $TOTAL, Failed: $FAILS"

if [ "$FAILS" -gt 0 ]; then
  exit 1
fi
exit 0
