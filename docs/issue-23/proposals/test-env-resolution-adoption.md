---
status: proposed
files:
  - proposal-norm/hooks/tests/run-gate-tests.sh
  - refactoring-legacy/hooks/tests/run-gate-tests.sh
  - characterization-tests/hooks/tests/run-gate-tests.sh
  - refactoring-steps/hooks/tests/run-gate-tests.sh
  - docs/handbooks/gate-hooks.md
---

## Request
Adopt the canonical test-env resolution convention landed at
`docs/specs/test-env-resolution.md` (issue #551, `on-the-record` repo)
in this rulebook's four `run-gate-tests.sh` scripts, so that outside the
spawn env — no `CLAUDE_PLUGIN_ROOT_CORE`, no reachable core plugin —
each script SKIPs with the convention's explicit message and distinct
exit code (`75`), instead of running every case against an
unresolvable gate and reporting misleading `FAIL`s.

## Constraints
- The convention's resolution order, SKIP message text, and exit code
  (`75`, `EX_TEMPFAIL`) are fixed upstream (issue #551) — not
  renegotiable here.
- No assertion that currently runs correctly when core IS reachable may
  weaken or change its expected outcome (issue #23 acceptance).
- No production gate script's own fail-closed behavior when core is
  genuinely missing at runtime may change — only the *test runner's*
  behavior when core is unresolvable changes.
- Each script must reference the convention doc in text (grep for
  `test-env-resolution`), per the issue's acceptance check.
- No network fetch as a resolution fallback (the convention explicitly
  excludes it from the canonical SKIP contract).

## Rationale
Considered importing/invoking the upstream reference module directly,
per the convention doc's documented "Bash test runner" adoption shape
(`python3 -m gates.test_env_resolve <candidates...>`, branch on exit
code). Rejected: that module lives in the `on-the-record` repo's own
`gates` package and is not vendored into this repo. Using it here would
require either copying the module into this repo (a second copy that
can silently drift from the upstream reference) or depending on the
`on-the-record` sibling checkout's location and PYTHONPATH being set up
correctly at test-run time — itself an environment assumption of
exactly the brittle kind this convention exists to eliminate, and one
this repo cannot guarantee any more than it could guarantee
`CLAUDE_PLUGIN_ROOT_CORE` before this change.

Chosen instead: replicate the convention's three-step resolution order
(env var check → sibling-candidate check → SKIP+`75`+message) as a
small inline bash guard at the top of each `run-gate-tests.sh`, with no
dependency on any other repo's presence. This mirrors how the gate
scripts under test already resolve core themselves (env var, else a
sibling `../../core` relative to the plugin, else fail closed) — same
resolution shape, now applied one directory level up (from the test
runner) and ending in the convention's SKIP contract instead of the
gate's own fail-closed exit `2`.

## What will be done
In each of the four `run-gate-tests.sh` scripts, immediately after
`SCRIPT_DIR`/`GATE(_SCRIPT)` are computed and before any test case
runs:
1. Check whether `CLAUDE_PLUGIN_ROOT_CORE` is set and
   `$CLAUDE_PLUGIN_ROOT_CORE/hooks/lib/gate-lib.sh` exists and is
   non-empty.
2. Else check whether the sibling candidate
   `$SCRIPT_DIR/../../../core/hooks/lib/gate-lib.sh` exists and is
   non-empty (mirrors the gate scripts' own `../../core` candidate,
   one level deeper since the test runner sits in `hooks/tests/`).
3. If neither resolves: print
   `SKIP: core plugin unreachable — unverifiable outside spawn env
   (see docs/specs/test-env-resolution.md, issue #551)` to stderr and
   `exit 75` — before any case runs, so no spurious PASS/FAIL lines are
   produced.
4. If either resolves: fall through unchanged into the existing test
   cases (including each script's own dedicated "missing core:
   unresolvable `CLAUDE_PLUGIN_ROOT_CORE` fails closed" case, which
   deliberately points `CLAUDE_PLUGIN_ROOT_CORE` at a nonexistent path
   for that one subprocess call and still expects the gate's own exit
   `2` — untouched by this change).

`docs/handbooks/gate-hooks.md` documents these same four scripts' exit
codes and is edited-to-stay-true on every prior change to that contract
(issue-13, issue-16, issue-20 all updated it alongside the code) — a
warrant hunt on this proposal confirmed the SKIP/`exit 75` pre-check has
no path there otherwise. Add one short paragraph noting the new
SKIP-outside-spawn-env behavior and its `exit 75` code, next to the
existing exit-code/kill-switch documentation.

This is a pure pre-check addition; no existing case, assertion, or
expected exit code is edited.

## Out of scope
- Changing any production gate script's (`methodology-gate.sh`,
  `refactoring-legacy-progress-gate.sh`,
  `manifest-integrity-check.sh`) own core-resolution or fail-closed
  behavior.
- Vendoring or importing the upstream `gates.test_env_resolve` Python
  module into this repo.
- Adding the convention to `characterization-tests`' own gate kill
  switch or to any pytest suite — this repo has no pytest-shaped test
  runner in scope; all four runners here are bash.
- Any change to `docs/specs/test-env-resolution.md` itself (owned by
  the `on-the-record` repo).

## How you'll know it worked
- With `CLAUDE_PLUGIN_ROOT_CORE` unset and no sibling `../../../core`
  checkout present (this repo's plain-checkout state today), running
  each of the four `run-gate-tests.sh` prints the SKIP message and
  exits `75` — no PASS/FAIL lines, no misleading failure.
- With `CLAUDE_PLUGIN_ROOT_CORE` pointed at a reachable core checkout
  (the current spawn-session state), all four scripts run every case
  unchanged and exit `0`, identical to today's passing behavior.
- `grep -l test-env-resolution` over the four scripts returns all four
  paths.
- If any case's *own* logic (not the core-resolution wrapper) turns out
  broken once core is reachable, that is a real defect and gets
  recorded as a finding, not silently masked by SKIP.
