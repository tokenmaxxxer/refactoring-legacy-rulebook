#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATE="$SCRIPT_DIR/../refactoring-legacy-progress-gate.sh"

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

FAILS=0
TOTAL=0

run_raw() {
  local name="$1"
  local expected_exit="$2"
  local tmpdir="$3"
  local extra_env="${4:-}"

  TOTAL=$((TOTAL + 1))
  local actual_exit
  if [ -n "$extra_env" ]; then
    actual_exit="$(cd "$tmpdir" && env "$extra_env" bash "$GATE" </dev/null >/dev/null 2>&1; echo $?)"
  else
    actual_exit="$(cd "$tmpdir" && bash "$GATE" </dev/null >/dev/null 2>&1; echo $?)"
  fi

  if [ "$actual_exit" -eq "$expected_exit" ]; then
    echo "PASS: $name (exit $actual_exit)"
  else
    echo "FAIL: $name (expected exit $expected_exit, got $actual_exit)"
    FAILS=$((FAILS + 1))
  fi
}

d="$(mktemp -d)"; (cd "$d" && git init -q)

# 1. Normal call, core resolvable -> allow (exit 0). This is the
# ghost-file-to-real-code flip issue-16 defect 2 requires: before this
# file existed, a missing hook command was a silent Claude-Code no-op;
# now real code runs and exits 0 deliberately, not by absence.
run_raw "normal call, core resolvable, allows" 0 "$d"

# 2. Kill switch on -> allow (exit 0).
run_raw "kill switch on" 0 "$d" "REFACTORING_LEGACY_PROGRESS_GATE_OFF=1"

# 3. Missing core: CLAUDE_PLUGIN_ROOT_CORE points at a nonexistent path and
# no sibling ../../core is present -> guarded source fails closed, exit 2.
run_raw "missing core: unresolvable CLAUDE_PLUGIN_ROOT_CORE fails closed" 2 "$d" "CLAUDE_PLUGIN_ROOT_CORE=/nonexistent-core-path-xyz"

rm -rf "$d"

# 4. Manifest-integrity check: real repo state is clean (exit 0) — no
# hooks.json in this repo references a command file absent from disk.
TOTAL=$((TOTAL + 1))
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd -P)"
if bash "$SCRIPT_DIR/manifest-integrity-check.sh" "$REPO_ROOT" >/dev/null 2>&1; then
  echo "PASS: manifest-integrity-check: real repo state is clean (exit 0)"
else
  echo "FAIL: manifest-integrity-check: real repo state should be clean, was not"
  FAILS=$((FAILS + 1))
fi

# 5. Manifest-integrity check fixture: an injected ghost command entry
# (issue-16 verification criteria #4) must fail loudly, not silently pass.
TOTAL=$((TOTAL + 1))
fd="$(mktemp -d)"
mkdir -p "$fd/ghost-plugin/hooks"
cat > "$fd/ghost-plugin/hooks/hooks.json" <<'EOF'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/does-not-exist.sh" }
        ]
      }
    ]
  }
}
EOF
if bash "$SCRIPT_DIR/manifest-integrity-check.sh" "$fd" >/dev/null 2>&1; then
  echo "FAIL: manifest-integrity-check fixture should fail loudly on ghost entry, silently passed"
  FAILS=$((FAILS + 1))
else
  echo "PASS: manifest-integrity-check fixture fails loudly on injected ghost entry"
fi
rm -rf "$fd"

echo "----"
echo "Total: $TOTAL, Failed: $FAILS"

if [ "$FAILS" -gt 0 ]; then
  exit 1
fi
exit 0
