#!/usr/bin/env bash
set -uo pipefail

if [ "${REFACTORING_STEPS_GATE_OFF:-}" = "1" ]; then
  exit 0
fi

STDIN_JSON="$(cat)"

PARSED="$(python3 - "$STDIN_JSON" <<'PYEOF' 2>"${TMPDIR:-/tmp}/refactoring_steps_gate_pyerr"
import json, sys

try:
    data = json.loads(sys.argv[1])
except Exception:
    print("PARSE_ERROR")
    sys.exit(0)

tool_name = data.get("tool_name", "")
tool_input = data.get("tool_input", {}) or {}
cwd = data.get("cwd", "")
file_path = tool_input.get("file_path", "")

if not file_path:
    print("PARSE_ERROR")
    sys.exit(0)

new_text_parts = []
if tool_name == "Write":
    new_text_parts.append(tool_input.get("content", "") or "")
elif tool_name == "Edit":
    new_text_parts.append(tool_input.get("new_string", "") or "")
elif tool_name == "MultiEdit":
    for e in (tool_input.get("edits", []) or []):
        new_text_parts.append(e.get("new_string", "") or "")

new_text = "\n".join(new_text_parts)

print("OK")
print(file_path)
print(cwd)
print(json.dumps(new_text))
PYEOF
)"

PY_STATUS=$?

if [ $PY_STATUS -ne 0 ]; then
  echo "refactoring-steps gate: DENY — failed to parse PreToolUse JSON" >&2
  exit 2
fi

FIRST_LINE="$(printf '%s\n' "$PARSED" | sed -n '1p')"

if [ "$FIRST_LINE" != "OK" ]; then
  echo "refactoring-steps gate: DENY — failed to parse PreToolUse JSON or missing file_path" >&2
  exit 2
fi

FILE_PATH="$(printf '%s\n' "$PARSED" | sed -n '2p')"
CWD="$(printf '%s\n' "$PARSED" | sed -n '3p')"
NEW_TEXT_JSON="$(printf '%s\n' "$PARSED" | sed -n '4,$p')"

if [ -z "$FILE_PATH" ]; then
  echo "refactoring-steps gate: DENY — missing file_path" >&2
  exit 2
fi

# BRANCH 1: phase-2 record
if printf '%s' "$FILE_PATH" | grep -Eq 'docs/issue-[0-9]+/reports/refactoring-legacy\.md$'; then
  RESOLVED_PATH="$FILE_PATH"
  case "$FILE_PATH" in
    /*) RESOLVED_PATH="$FILE_PATH" ;;
    *)
      if [ -n "$CWD" ]; then
        RESOLVED_PATH="$CWD/$FILE_PATH"
      else
        RESOLVED_PATH="$FILE_PATH"
      fi
      ;;
  esac

  ON_DISK=""
  if [ -f "$RESOLVED_PATH" ]; then
    ON_DISK="$(cat "$RESOLVED_PATH" 2>/dev/null || true)"
  fi

  RESULT="$(python3 - "$ON_DISK" "$NEW_TEXT_JSON" <<'PYEOF2' 2>"${TMPDIR:-/tmp}/refactoring_steps_gate_pyerr2"
import json, sys, re

on_disk = sys.argv[1]
new_text = json.loads(sys.argv[2])

effective = on_disk + "\n" + new_text
low = effective.lower()

catalog_terms = ["extract method", "extract function", "rename", "inline",
                 "move method", "move function", "refactoring.com/catalog", "catalog"]
has_catalog = any(t in low for t in catalog_terms)

has_equivalence = ("equivalence" in low) or ("동등성" in effective)

reasons = []
if not has_catalog:
    reasons.append("no catalog refactoring step name found (e.g. Extract Method, Rename, Inline, Move Method, refactoring.com/catalog, or 'catalog')")
if not has_equivalence:
    reasons.append("no before/after equivalence note found ('equivalence' or Korean '동등성')")

if "strangler" in low:
    if "seam" not in low:
        reasons.append("strangler-fig mentioned but no stable seam described ('seam')")

if reasons:
    print("DENY")
    for r in reasons:
        print(r)
else:
    print("OK")
PYEOF2
)"
  PY2_STATUS=$?
  if [ $PY2_STATUS -ne 0 ]; then
    echo "refactoring-steps gate: DENY — internal error evaluating phase-2 record" >&2
    exit 2
  fi

  RFIRST="$(printf '%s\n' "$RESULT" | sed -n '1p')"
  if [ "$RFIRST" = "OK" ]; then
    exit 0
  else
    echo "refactoring-steps gate: DENY — phase-2 record missing required content:" >&2
    printf '%s\n' "$RESULT" | sed -n '2,$p' >&2
    exit 2
  fi
fi

# BRANCH 2: src/** structural edit
if printf '%s' "$FILE_PATH" | grep -Eq '(^src/|/src/)'; then
  BRANCH_DIR="$CWD"
  if [ -z "$BRANCH_DIR" ]; then
    BRANCH_DIR="."
  fi

  CURRENT_BRANCH="$(git -C "$BRANCH_DIR" symbolic-ref --short HEAD 2>/dev/null || git -C "$BRANCH_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  ISSUE_NUM="$(printf '%s' "$CURRENT_BRANCH" | sed -nE 's#^issue-([0-9]+)/.*#\1#p')"

  if [ -z "$ISSUE_NUM" ]; then
    echo "refactoring-steps gate: DENY — cannot determine issue number from branch name to locate phase-2 record" >&2
    exit 2
  fi

  REPO_ROOT="$(git -C "$BRANCH_DIR" rev-parse --show-toplevel 2>/dev/null || true)"
  if [ -z "$REPO_ROOT" ]; then
    echo "refactoring-steps gate: DENY — cannot determine repo root" >&2
    exit 2
  fi

  RECORD_PATH="$REPO_ROOT/docs/issue-$ISSUE_NUM/reports/refactoring-legacy.md"

  if [ -f "$RECORD_PATH" ] && grep -Eq 'characterization_tests_path:[[:space:]]*[^[:space:]]+' "$RECORD_PATH" 2>/dev/null; then
    exit 0
  else
    echo "refactoring-steps gate: DENY — structural src/** edit blocked: no characterization_tests_path recorded yet in docs/issue-$ISSUE_NUM/reports/refactoring-legacy.md (characterize before refactor)" >&2
    exit 2
  fi
fi

# BRANCH 3: out of scope
exit 0
