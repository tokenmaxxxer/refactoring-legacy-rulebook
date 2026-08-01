# Phase-2 record — issue #16 (refactoring-legacy)

loop_state: landed

## What was done

Implemented the Approved proposal (`docs/issue-16/proposals/refactoring-legacy.md`,
`APPROVE issue-16/refactoring-legacy`, single-account mode): closed all
four residual defects the 2026-08-01 re-audit named against issue-13's
delivered gate A+ state.

1. **Source guard (Defect 1, reference-adopt core #75 verbatim).** Added
   core issue-75's exact `||` guard, matching
   `core/hooks/approval-gate.sh:38`'s structure, to the unguarded
   `gate-lib.sh` source line in all three methodology-enforcement gates:
   `proposal-norm/hooks/methodology-gate.sh:11`,
   `characterization-tests/hooks/methodology-gate.sh:9`,
   `refactoring-steps/hooks/methodology-gate.sh:11`. No other line in any
   of the three files changed. `refactoring-legacy/hooks/directive.sh:4`'s
   unguarded `role-directive.sh` source was left as-is, per the proposal's
   explicit Out-of-scope call (different file, outside
   `compliance-check.sh`'s pattern).
2. **`hooks.json` ghost-file matcher (Defect 2), shape (a) chosen.** Built
   `refactoring-legacy/hooks/refactoring-legacy-progress-gate.sh` — real,
   minimal backing code for the previously-ghost `Bash` matcher entry: it
   fails closed (`exit 2`) on missing core (same guard shape as the other
   three gates) and otherwise allows, since no per-step progress-tracking
   methodology check is designed or approved for it (unchanged from
   issue-13's Out-of-scope call). Added
   `refactoring-legacy/hooks/tests/manifest-integrity-check.sh` as a
   permanent regression guard: scans every plugin's `hooks.json` for
   `${CLAUDE_PLUGIN_ROOT}`-relative `command` entries and hard-fails if the
   referenced file is absent from disk — so a future ghost-matcher
   mismatch (this one or any other plugin's) fails loudly instead of
   silently passing forever.
3. **Missing-core test coverage + full suite green (Defect 3).** Added one
   new missing-core case (`CLAUDE_PLUGIN_ROOT_CORE` pointed at a
   nonexistent path, no `../../core` sibling present so the fallback also
   fails to resolve) to each of the three existing
   `hooks/tests/run-gate-tests.sh` suites, plus a new
   `refactoring-legacy/hooks/tests/run-gate-tests.sh` (3 cases: normal
   allow, kill switch, missing-core) and its own
   `manifest-integrity-check.sh` fixture cases (2 more: real-repo-clean,
   injected-ghost-fails-loudly). All four suites green:
   - `proposal-norm/hooks/tests/run-gate-tests.sh`: 20/20 passed (was 19/19)
   - `characterization-tests/hooks/tests/run-gate-tests.sh`: 19/19 passed (was 18/18)
   - `refactoring-steps/hooks/tests/run-gate-tests.sh`: 23/23 passed (was 22/22)
   - `refactoring-legacy/hooks/tests/run-gate-tests.sh`: 5/5 passed (new)
4. **Compliance-check re-run recorded.**
   `core/hooks/tests/compliance-check.sh` (core `main`, commit
   `52bdc15ff02fcf38aa6c65284996e69a5ddc9c82` — the same commit issue-75
   landed at) run against all four plugins' `hooks/` dirs, all `ok`, zero
   `FAIL`: `compliance-check: ok — proposal-norm/hooks/methodology-gate.sh`,
   `compliance-check: ok — characterization-tests/hooks/methodology-gate.sh`,
   `compliance-check: ok — refactoring-steps/hooks/methodology-gate.sh`,
   `compliance-check: ok — refactoring-legacy/hooks/refactoring-legacy-progress-gate.sh`.
   Supersedes the stale `docs/issue-13/reports/refactoring-legacy.md`
   record (run against pre-issue-75 core PR #74, which lacked the
   source-guard check).
5. **README/manifest cleanup (Defect 4).** `README.md:92-96,127-129,143-145`
   updated from "remains dangling"/"unenforced" prose to describe the now-
   real, enforced state (the new gate + the manifest-integrity regression
   guard), and now states explicitly that a compliance-check-clean record
   is a point-in-time claim against a specific core commit, not a standing
   guarantee. Re-ran the issue-13 survey §7 spot-check: no new drift; no
   file/path/plugin referenced in README or any `plugin.json` is absent
   from the delivered tree. No old-role-name string exists anywhere in
   this repo (confirmed via full git history, survey §4) — recorded as an
   absence finding, not a remediation, so a future audit does not re-ask.

## Why

A 2026-08-01 re-audit of this rulebook's gate A+ closure (issue-13's
delivered state) found four residual defects, gated on two preconditions
(core issue #75, on-the-record issue #182) both confirmed landed to
`main` before this proposal was written. Issue #16 required the fix to
reference-apply core #75's finalized guard/rule rather than re-derive a
local version — the same reference-adopt precedent issue-13 itself set
against core issue #72.

## Upstream basis

- `docs/issue-16/proposals/refactoring-legacy.md` (this role's own
  Approved proposal), citing
  `docs/issue-16/reports/refactoring-legacy/survey.md` (defect map) and
  `docs/issue-16/reports/refactoring-legacy/scout-brief.md` (core #75's
  and on-the-record #182's landed shapes).
- `tokenmaxxxer-core` issue #75 (`hooks/lib/gate-lib.sh` source guard,
  `compliance-check.sh` detection), merged to `main` at commit
  `52bdc15ff02fcf38aa6c65284996e69a5ddc9c82` (PR #77).
- `docs/issue-13/reports/refactoring-legacy.md` (the prior gate-house
  migration this issue remediates residual defects against).

## Seam

The missing-core case added to each suite is the characterization seam
for Defect 1: a subprocess invocation with `CLAUDE_PLUGIN_ROOT_CORE`
pointed at a nonexistent path (no `../../core` sibling present) isolates
the exact fail-open-on-missing-core behavior from the rest of the gate,
capturing the before state (unguarded source, undefined
`gate_kill_switch_active`, non-`2` exit per bash's "command not found"
semantics) and the after state (guarded source, `exit 2`) in one
re-runnable case per suite, rather than a one-off manual transcript.

characterization_tests_path: characterization-tests/hooks/tests/run-gate-tests.sh
test_run: PASS (bash characterization-tests/hooks/tests/run-gate-tests.sh)

## Refactoring steps

- Extract Method (guard clause): added core #75's `||` guard verbatim to
  the three existing `gate-lib.sh` source lines (Fowler's catalog,
  applied against core's own already-landed shape, not re-derived).
- Move Method: `refactoring-legacy-progress-gate.sh`'s guard/kill-switch
  shape is moved in verbatim from the other three gates' already-landed
  pattern, not re-derived, closing the ghost-file gap without redesigning
  the deferred full progress-tracking methodology.
- Rename: `hooks.json`'s dangling matcher target now names a file that
  actually exists with the same name, turning a dangling reference into a
  resolved one.
- Extract Method: `manifest-integrity-check.sh`'s find/parse/exists-on
  -disk check was added as its own independently-testable step, before
  any `hooks.json` prose changed, per the proposal's sequencing.

## Equivalence

Before (issue-13's delivered state) vs. after (this closure): every case
that passed in all three methodology-enforcement suites still passes
unchanged — the guard only adds a fallback path for the already-broken
missing-core case, it does not touch the already-succeeding source path.
Confirmed re-run totals: `proposal-norm` 20/20 (was 19/19, +1 new case),
`characterization-tests` 19/19 (was 18/18, +1), `refactoring-steps` 23/23
(was 22/22, +1), `refactoring-legacy` 5/5 (new suite, no baseline). No
previously-passing case newly fails; no fixture had to be reshaped (no
existing fixture exercised a missing-core condition, as the proposal
anticipated).

## Verification criteria (phase-2, per the proposal)

1. `compliance-check.sh` (core `main`, `52bdc15ff02fcf38aa6c65284996e69a5ddc9c82`)
   reports zero violations for all three methodology-enforcement plugins —
   confirmed, transcript in `## What was done` item 4.
2. Each of the three plugins' `run-gate-tests.sh` (extended with the new
   missing-core case) exits 0 — confirmed, 20/20, 19/19, 23/23.
3. The missing-core characterization test demonstrably flips from an
   unguarded, non-`2` exit before the fix to a guarded `exit 2` deny after
   — confirmed on the post-fix side for all four suites (each suite's new
   case passes at exit 2, transcript in `## What was done` item 3); the
   pre-fix side is derived from documented bash semantics (an unguarded
   failed `source` leaves `gate_kill_switch_active` undefined, "command
   not found", not exit 2) rather than independently re-executed in this
   sandbox — a standalone env-prefixed reproduction script was blocked by
   this session's own approval gate; named here rather than silently
   claimed as directly observed.
4. Whichever hard-error shape defect 2/4 chose, a fixture exercising the
   ghost-file/matcher-mismatch condition demonstrably fails loudly post-fix
   — confirmed: `refactoring-legacy/hooks/tests/run-gate-tests.sh` case 5
   injects a synthetic ghost `hooks.json` entry into a tmpdir and confirms
   `manifest-integrity-check.sh` fails loudly against it (`PASS:
   manifest-integrity-check fixture fails loudly on injected ghost entry`).
5. `README.md` and the four `plugin.json` manifests contain no reference
   to a file/path/plugin absent from the delivered tree, and no
   old-role-name string is introduced or left present — confirmed, spot
   -check re-run in `## What was done` item 5; `manifest-integrity-check.sh`
   now makes the `hooks.json` half of this a permanently re-checkable,
   automated claim rather than a one-time manual spot-check.

## Open findings

- `refactoring-legacy/hooks/directive.sh:4`'s unguarded `role-directive.sh`
  source shares Defect 1's fail-open-on-missing-core risk class but is
  outside `compliance-check.sh`'s specific `gate-lib\.sh"$` pattern and
  outside this issue's four named defects (proposal's explicit
  Out-of-scope call) — flagged for a future issue, not fixed here.
- A compliance-check-clean record remains a point-in-time claim against a
  specific core commit (`52bdc15`); it is not re-verified on any cadence.
  README's Doctrine section now states this explicitly; a future re-audit
  should re-run `compliance-check.sh` against current core `main` rather
  than trust this record, closing the exact staleness gap this issue's
  Defect 1 named for the issue-13 record.
- `refactoring-legacy-progress-gate.sh` is intentionally minimal (fails
  closed on missing core, otherwise allows) — full per-step
  progress-tracking methodology enforcement for it remains open, matching
  issue-13's Out-of-scope call; this issue closed only the ghost-file gap,
  not that design question.
