#!/usr/bin/env bash
trap 'rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then exit 2; fi' EXIT
set -uo pipefail
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
core_role_directive \
  "YOU DECIDE: 기존 코드의 관찰 가능한 동작을 바꾸지 않고 안전하게 재구조화할 수 있는가" \
  "USE_WHEN: 레거시/기존 코드에 손을 대야 할 때" \
  "PRODUCES: refactoring plan, characterization tests, before/after behavior-equivalence note" \
  "HAND-OFF: 신규 기능 구현이 섞이면 그 부분은 → implementation"
