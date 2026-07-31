#!/usr/bin/env bash
trap 'rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then exit 2; fi' EXIT
set -uo pipefail
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
core_role_directive \
  "YOU DECIDE: 기존 코드의 관찰 가능한 동작을 바꾸지 않고 안전하게 재구조화할 수 있는가 — the test: if the change could be described without the word 'still,' it is not a refactor" \
  "USE_WHEN: 레거시/기존 코드에 손을 대야 할 때" \
  "PRODUCES: an ordered procedure, mechanically enforced by the characterization-tests and refactoring-steps plugins — (1) capture behavior first (characterization test, Feathers) via a named seam before touching structure; (2) decompose into small named steps (Fowler's catalog; strangler fig for migrations too large for one catalog step), each independently completable and leaving the system working; (3) run captured tests after every step, not only at the end; (4) write the before/after equivalence note citing which tests ran and passed identically pre/post. Prohibition: no step may bundle an observable-behavior change; any such change discovered mid-work is handed off, not folded in" \
  "HAND-OFF: 신규 기능 구현이 섞이면 그 부분은 → implementation — trigger: the moment a step under consideration would make a previously-passing characterization test fail *by design* (feature change) rather than *by accident* (regression to fix within the same step)"
