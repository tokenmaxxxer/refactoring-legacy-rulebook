# Proposal — core canon 참조 전환 (issue #2)

Phase 1 only — this PR is proposal + survey + scout brief. No execution.

## Request (paraphrased)

core landed a single canon for the warrant-hunt agent (core #63) and the
three role-agnostic gates + shared directive boilerplate (core #66). This
rulebook (`refactoring-legacy`) still vendors its own pre-canon copies of
all four, plus a full standalone `directive.sh`. Convert to referencing core
canon; keep only what is genuinely role-unique.

## Frozen contract (shared shape, from core canon — not designed here)

- `refactoring-legacy/hooks/directive.sh` becomes exactly:
  ```bash
  #!/usr/bin/env bash
  trap 'rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then exit 2; fi' EXIT
  set -uo pipefail
  . "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
  core_role_directive \
    "YOU DECIDE: 기존 코드의 관찰 가능한 동작을 바꾸지 않고 안전하게 재구조화할 수 있는가" \
    "USE_WHEN: 레거시/기존 코드에 손을 대야 할 때" \
    "PRODUCES: refactoring plan, characterization tests, before/after behavior-equivalence note" \
    "HAND-OFF: 신규 기능 구현이 섞이면 그 부분은 → implementation"
  ```
  (the trap/`set -uo pipefail` pair stays in the rulebook's own file — a trap
  inside the sourced function does not catch the sourcing script's own exit,
  per core's own issue-66 record.)
- `refactoring-legacy/hooks/{trailer-gate.sh,record-fields-gate.sh,
  handbook-trigger-gate.sh}` deleted outright; their `hooks.json` entries
  removed. Core's `core/hooks/hooks.json` already fires the canon versions for
  every plugin install once `core` is installed alongside this rulebook.
- `refactoring-legacy/agents/warrant-hunter.md` deleted; the `warrant` core
  plugin installed instead (ships the agent + `hunt-guard.sh`/`hunt-state.sh`
  as one unit — this rulebook currently has neither of those guard files, so
  nothing else to remove there).
- `docs/issue-2/reports/implementation/stub-check.sh`-class check: copy
  core's `core/hooks/tests/stub-check.sh` verbatim into
  `refactoring-legacy/hooks/tests/stub-check.sh` (this repo currently has no
  `hooks/tests/` directory at all — new, not a copy of an existing local
  test).
- README.md's install section gains the four core plugins
  (`core`, `terse`, `freelunch`, `scout`) plus `warrant`, matching the
  install-alongside pattern implementation-rulebook's README documents (minus
  `warrant`, which that repo has not yet added either — this rulebook would be
  ahead of that sibling on that one point, per the survey).

## Independently producible units (freelunch width tally)

Width = 1: every file above is a single mechanical stub/deletion pass over one
frozen contract (core's own canon files), no sub-decomposition benefits from
splitting, well under the ~100-line/unit threshold in aggregate (net change is
deletions plus one ~10-line stub file). Lean solo; no fan-out.

## What will be done (phase 2, pending Approve)

1. Delete `refactoring-legacy/agents/warrant-hunter.md`.
2. Delete `refactoring-legacy/hooks/{trailer-gate.sh,record-fields-gate.sh,
   handbook-trigger-gate.sh}`; strip their entries from
   `refactoring-legacy/hooks/hooks.json` (keep the dangling
   `refactoring-legacy-progress-gate.sh` entry untouched — pre-existing,
   outside this issue's 5 items, see survey).
3. Replace `refactoring-legacy/hooks/directive.sh` with the stub above.
4. Add `refactoring-legacy/hooks/tests/stub-check.sh` (verbatim copy from
   core) and run it against `refactoring-legacy/`, recording pass/fail in the
   phase-2 record (issue item 5).
5. Add `.claude-plugin/marketplace.json`/README install instructions for
   `core`, `terse`, `freelunch`, `scout`, `warrant` alongside
   `refactoring-legacy` (closes the gap noted in the survey — otherwise the
   stub references a plugin path nothing installs).
6. `RECORD_FIELDS_TERMINAL_STATES`: **no override** — this role's directive
   and existing record shape name no non-`landed` terminal `loop_state`
   value; default suffices (item 4, resolved as "not applicable" rather than
   configured, since there is no evidence of divergence to preserve).

## Out of scope

- `refactoring-legacy-progress-gate.sh`'s dangling reference (pre-existing,
  not one of the 5 listed items).
- Any change to `roles.json`/produces/write_scope semantics — this issue is a
  reference-plumbing change, not a doctrine change.
- Rulebook-maturation phase 2 (this repo's own future issue) — the issue's
  순서 제약 requires this conversion land first.

## How it will be verified (phase 2)

- `refactoring-legacy/hooks/tests/stub-check.sh` run against
  `refactoring-legacy/` exits 0.
- `find refactoring-legacy/hooks -maxdepth 3 -name 'trailer-gate.sh' -o -name
  'record-fields-gate.sh' -o -name 'handbook-trigger-gate.sh' -o -name
  'warrant-hunter.md'` returns nothing.
- Manual read of the new `directive.sh` against `role-directive.sh`'s
  documented call shape.

## Open question for the approver

Confirm no role-specific terminal `loop_state` exists for
`refactoring-legacy` beyond `landed` (point 6 above) — if a maturation
decision elsewhere already named one (e.g. an early "plan-approved" state),
say so and phase 2 will set `RECORD_FIELDS_TERMINAL_STATES` accordingly
instead of leaving the default.
