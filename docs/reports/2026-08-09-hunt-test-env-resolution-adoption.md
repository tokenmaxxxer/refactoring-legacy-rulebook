---
proposal: docs/issue-23/proposals/test-env-resolution-adoption.md
---

# Hunt record — test-env-resolution-adoption

## after-proposal — stance 4: assume the write set cannot carry this work — find the path the build will need that the proposal does not list.

Verdict: FINDING — the frozen write set omits docs/handbooks/gate-hooks.md, which self-commits to staying accurate about these four scripts' behavior and will go stale once the new exit-75 SKIP path lands.
Kind: design-error
Seed: docs/issue-23/proposals/test-env-resolution-adoption.md (write set: proposal-norm/hooks/tests/run-gate-tests.sh, refactoring-legacy/hooks/tests/run-gate-tests.sh, characterization-tests/hooks/tests/run-gate-tests.sh, refactoring-steps/hooks/tests/run-gate-tests.sh)
cap_seconds: 120
tier: default
diff_stat_lines: 0 (proposal only, no diff yet)
started_at: 2026-08-09T09:42:47+09:00
ended_at: 2026-08-09T09:52:00+09:00

### Reproduce
```
sed -n '1,20p' docs/handbooks/gate-hooks.md
git log --oneline -3 -- docs/handbooks/gate-hooks.md
```
`docs/handbooks/gate-hooks.md` opens with the literal line "Current state.
Edited from now on to stay true." and then documents, for these same four
`run-gate-tests.sh` scripts, exactly two run-time invocation shapes: plain
`bash <plugin>/hooks/tests/run-gate-tests.sh` (implying pass/fail == exit
0/1) and the "missing-core case ... proving the guard above flips the gate
from fail-open to a clean `exit 2` deny" — i.e. it documents the scripts'
existing behavior/exit-code contract in prose. `git log` on this file shows
every prior change to these scripts' contract (issue-13 gate-house
migration, issue-16 missing-core case, issue-20 spec-vocabulary regression
cases) landed together with an edit to this same handbook file, in keeping
with its own "edited from now on to stay true" promise.

### Observed
The proposal's frozen write set is exactly the four `run-gate-tests.sh`
files; `docs/handbooks/gate-hooks.md` is not in it. After the change lands,
running any of the four scripts outside a resolvable core (this repo's
plain-checkout state, per the proposal's own "How you'll know it worked")
will print a new `SKIP ... exit 75` outcome that the handbook does not
mention anywhere — the handbook's documented contract (pass/fail via plain
invocation, `exit 2` for the "missing-core" *in-gate* case) becomes
incomplete/misleading the moment the change lands, in a doc that
explicitly promises never to drift.

### Expected
Either `docs/handbooks/gate-hooks.md` is added to the write set (with a
line documenting the new SKIP/exit-75 pre-check and its trigger
condition), or the proposal explicitly scopes its exclusion and accepts
that the handbook goes stale until a follow-up — as written, the proposal
does neither.
