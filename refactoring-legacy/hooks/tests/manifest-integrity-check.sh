#!/usr/bin/env bash
# Manifest-integrity check (issue-16 defect 2/4): scans every plugin's
# hooks.json in this repo for `"command"` entries of the shape
# `${CLAUDE_PLUGIN_ROOT}/<rel-path>` and hard-fails if the referenced file
# is absent from disk. This is the permanent regression guard: without it,
# a `hooks.json` matcher pointing at a nonexistent command file is a silent
# Claude-Code no-op forever (the exact issue-16 defect 2 shape) — this
# check turns that silence into a loud, CI-visible failure.
#
# Usage: manifest-integrity-check.sh [repo-root]
set -uo pipefail

repo_root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)}"
rc=0

manifests="$(find "$repo_root" -maxdepth 3 -type f -name 'hooks.json' 2>/dev/null || true)"
if [ -z "$manifests" ]; then
  echo "manifest-integrity-check: no hooks.json files found under $repo_root — nothing to check"
  exit 0
fi

while IFS= read -r manifest; do
  [ -n "$manifest" ] || continue
  plugin_root="$(cd "$(dirname "$manifest")/.." && pwd -P)"

  missing="$(python3 - "$manifest" "$plugin_root" <<'PYEOF'
import json, os, sys

manifest_path, plugin_root = sys.argv[1], sys.argv[2]
with open(manifest_path) as f:
    data = json.load(f)

missing = []


def walk(node):
    if isinstance(node, dict):
        cmd = node.get("command")
        if isinstance(cmd, str) and "${CLAUDE_PLUGIN_ROOT}" in cmd:
            rel = cmd.replace("${CLAUDE_PLUGIN_ROOT}", "").lstrip("/")
            path = os.path.join(plugin_root, rel)
            if not os.path.isfile(path):
                missing.append(f"{cmd} -> {path}")
        for v in node.values():
            walk(v)
    elif isinstance(node, list):
        for v in node:
            walk(v)


walk(data)
print("\n".join(missing))
PYEOF
)"

  if [ -n "$missing" ]; then
    echo "manifest-integrity-check: FAIL — $manifest:" >&2
    while IFS= read -r m; do
      [ -n "$m" ] || continue
      echo "  - references a command file absent from disk: $m" >&2
    done <<< "$missing"
    rc=1
  else
    echo "manifest-integrity-check: ok — $manifest"
  fi
done <<< "$manifests"

exit "$rc"
