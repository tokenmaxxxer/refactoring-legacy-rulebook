---
code_under_review:
  - proposal-norm/hooks/tests/run-gate-tests.sh
  - refactoring-legacy/hooks/tests/run-gate-tests.sh
  - characterization-tests/hooks/tests/run-gate-tests.sh
  - refactoring-steps/hooks/tests/run-gate-tests.sh
  - docs/handbooks/gate-hooks.md
type: refactor
breaking: false
verdict: pass
loop_state: committing
---

# Implementation record — issue #23

## What was done
Adopted the canonical test-env resolution convention
(`docs/specs/test-env-resolution.md`, issue #551, `on-the-record` repo)
in this rulebook's four `run-gate-tests.sh` scripts, per the approved
phase-1 proposal (`docs/issue-23/proposals/test-env-resolution-adoption.md`).
Each script now runs a pre-check, immediately after `SCRIPT_DIR`/`GATE`
are computed and before any test case: if `CLAUDE_PLUGIN_ROOT_CORE`
resolves to a non-empty `hooks/lib/gate-lib.sh`, or a sibling
`../../../core/hooks/lib/gate-lib.sh` exists relative to the runner,
execution falls through unchanged into the existing cases; otherwise the
script prints `SKIP: core plugin unreachable — unverifiable outside
spawn env (see docs/specs/test-env-resolution.md, issue #551)` to
stderr and exits `75`.

Files changed:
- `proposal-norm/hooks/tests/run-gate-tests.sh`
- `refactoring-legacy/hooks/tests/run-gate-tests.sh`
- `characterization-tests/hooks/tests/run-gate-tests.sh`
- `refactoring-steps/hooks/tests/run-gate-tests.sh`
- `docs/handbooks/gate-hooks.md` — documents the new pre-check next to
  the existing exit-code/kill-switch/missing-core-case documentation.

## Why
Per issue #23: outside the spawn env (no `CLAUDE_PLUGIN_ROOT_CORE`, no
reachable core plugin), these test runners previously ran every case
against an unresolvable gate and reported mass spurious `FAIL`s,
indistinguishable from a real regression. The approved proposal's
rationale rejected vendoring/importing the upstream Python
`gates.test_env_resolve` module (not available in this repo, and doing
so would trade one environment assumption for another) in favor of
replicating the convention's three-step resolution order as a small
inline bash guard — mirroring the shape the gate scripts under test
already use for their own core resolution.

## Upstream basis
docs/issue-23/proposals/test-env-resolution-adoption.md

## Verification
Ran all four scripts locally in both states:
- With `CLAUDE_PLUGIN_ROOT_CORE` unset and no sibling `core` checkout:
  all four scripts print the SKIP message and exit `75`, before any
  test case runs.
- With `CLAUDE_PLUGIN_ROOT_CORE` set to the reachable core checkout in
  this session's spawn env: all four scripts run every case unchanged
  — `proposal-norm` 20/20, `refactoring-legacy` 5/5 (incl.
  `manifest-integrity-check.sh`), `characterization-tests` 22/22,
  `refactoring-steps` all PASSED — including each runner's own
  dedicated "missing core: unresolvable `CLAUDE_PLUGIN_ROOT_CORE` fails
  closed" case, which still asserts the gate's own `exit 2`.
- `grep -rn test-env-resolution` across the four scripts and the
  handbook confirms each references the convention doc.

closed_checks:
- outside-spawn-env SKIP contract (all four scripts, exit 75) — code_under_review as above
- core-reachable regression check (all four scripts, unchanged pass) — code_under_review as above
- convention-doc reference grep — code_under_review as above

## What did not work
None.

## Open findings
None.

## Doc placement
- `docs/handbooks/gate-hooks.md` updated in the same commit as the code
  (env/behavior contract change to the four test runners).

## Next steps
None — push and open the phase-2 PR against `main` with `Closes #23`.

## Resolution path
No open findings; none to resolve.
