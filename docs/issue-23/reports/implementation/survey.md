# Current-state survey — issue #23

## Scope of the issue
Adopt the canonical test-env resolution convention landed at
`docs/specs/test-env-resolution.md` (issue #551, in the sibling
`on-the-record` repo) across this rulebook's gate-test scripts, so that
outside the spawn env (no `CLAUDE_PLUGIN_ROOT_CORE`, no reachable core
plugin) they SKIP with an explicit message and a distinct exit code
instead of failing misleadingly.

## The convention (read from the landed doc)
Source: `/home/jwjung/.tokenmaxxxer/work/on-the-record-issue-551-implementation/docs/specs/test-env-resolution.md`
(this repo has no local copy — the doc lives in the `on-the-record` repo
and is referenced, not vendored).

Resolution order:
1. `$CLAUDE_PLUGIN_ROOT_CORE`, if set and it contains a non-empty
   `hooks/lib/gate-lib.sh`.
2. The first caller-supplied sibling-checkout candidate path (e.g.
   `../core`) that contains a non-empty `hooks/lib/gate-lib.sh`.
   Candidates are supplied by the caller, never hardcoded in a shared
   module.
3. Otherwise: SKIP, not a failure — print
   `SKIP: core plugin unreachable — unverifiable outside spawn env` to
   stderr, exit `75` (`EX_TEMPFAIL`, distinct from a gate's own
   `0`/`1`/`2`).

Adoption note for a bash test runner: invoke the reference module as a
CLI (`python3 -m gates.test_env_resolve <candidates...>`) and branch on
exit code — but that module lives in the `on-the-record` repo's own
`gates` package, is not vendored into this repo, and is not importable
from here. A consumer with no Python package to import replicates the
same three-step order directly (env var check, sibling-candidate check,
SKIP+75+message) — the convention doc treats the CLI/import forms as two
worked adoption shapes for consumers that *do* have the module
available, not as the only legal implementation.

## This repo's write surface
Four plugins, each with one `hooks/tests/run-gate-tests.sh` that invokes
its plugin's own gate script (`methodology-gate.sh` or
`refactoring-legacy-progress-gate.sh`) as a subprocess, feeding it
constructed JSON on stdin and asserting the exit code:

- `proposal-norm/hooks/tests/run-gate-tests.sh` (20 cases)
- `refactoring-legacy/hooks/tests/run-gate-tests.sh` (5 cases; also
  covers `manifest-integrity-check.sh`, which needs no core)
- `characterization-tests/hooks/tests/run-gate-tests.sh` (22 cases)
- `refactoring-steps/hooks/tests/run-gate-tests.sh` (many cases)

Every gate script under test already resolves core itself, independent
of these test runners:
```
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" \
    || { echo "...: cannot source gate-lib.sh" >&2; exit 2; }
```
i.e. env var, else a sibling `../../core` relative to the plugin's
`hooks/` dir, else **fail closed with exit 2** (no distinct SKIP
signal — this is the gate's own production behavior, and every runner
already has one dedicated case asserting exactly this: "missing core:
unresolvable CLAUDE_PLUGIN_ROOT_CORE fails closed").

## The actual defect
When `CLAUDE_PLUGIN_ROOT_CORE` is unset AND no sibling `../../core`
checkout exists (a plain `main` checkout run directly, outside the
spawn session that sets the env var), the gate script's own guarded
source now fails for *every* invocation — not just the one case that
deliberately tests missing-core. Every other case in the runner, which
assumes core resolves and expects exit `0`/`2` based on the gate's real
logic, instead gets the gate's fail-closed exit `2` from the unrelated
sourcing failure. Each such case then reports `FAIL (expected exit 0,
got 2)`, and the runner's overall exit code is `1` ("tests failed") —
indistinguishable from a real regression in the gate itself. This is
exactly the ambiguity issue #551 / `test-env-resolution.md` exists to
remove.

Verified locally: with `CLAUDE_PLUGIN_ROOT_CORE` unset and no sibling
core (this repo has none), running any of the four `run-gate-tests.sh`
scripts today produces mass spurious `FAIL` lines and exit `1`; with
`CLAUDE_PLUGIN_ROOT_CORE` set to the reachable core checkout in this
session's spawn env, all cases in all four scripts pass and exit `0`.

## Existing skip precedent in this codebase
None — no `run-gate-tests.sh` here currently distinguishes "core
unreachable" from "gate regressed." `characterization-tests`' own gate
(under test, not the test runner) has an env-driven kill switch
(`CHARACTERIZATION_TESTS_GATE_OFF`), which is a different mechanism
(assertions off) from a SKIP verdict (assertions unrunnable) — not
reusable for this purpose.

## What will change
Only the four `run-gate-tests.sh` files. No production gate script
(`methodology-gate.sh`, `refactoring-legacy-progress-gate.sh`,
`manifest-integrity-check.sh`) changes — their fail-closed behavior when
core is genuinely missing at runtime is correct and is exactly what the
"missing core" test case in each runner already asserts and must keep
asserting unchanged.

## Skip-condition note
Scouting (product-comparison sweep) is skipped for this issue: the spec
(the landed `test-env-resolution.md` convention) leaves no open design
decision — the resolution order, SKIP message, and exit code are fully
specified upstream; this repo's job is adoption, not design.
