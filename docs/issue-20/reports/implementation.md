---
code_under_review: unknown
type: refactor
breaking: false
verdict: pass
loop_state: landed
---

# Phase 2 record — align rulebook with realized refactoring-legacy spec (issue #20)

## Summary of work (what was done, why)

This record documents phase 2 execution of GitHub issue #20, approved via
single-account-mode issue comment `APPROVE issue-20/implementation` on top
of the phase-1 proposal at
`docs/issue-20/proposals/spec-vocabulary-alignment.md` (upstream basis:
that proposal, built on
`docs/issue-20/reports/implementation/survey.md` and
`docs/issue-20/reports/implementation/scout-brief.md`).

Why: the realized marketplace spec `roles/specs/refactoring-legacy.spec.json`
names four required deliverable fields (`refactoring_name`, `motivation`,
`mechanics`, `verdict`) and a five-value `loop_state` vocabulary
(`identifying`, `applying`, `landed`, `motivation-undeclared`,
`tests-unreachable`) that this rulebook's docs/hooks/gates did not use
verbatim. Issue #20 asked to layer that vocabulary onto the existing
methodology, strengthening it rather than replacing it with a parallel
system, per the approved proposal's Rationale.

What was done, exactly as proposed in `## What will be done`:

1. **`README.md`** — added a "Spec field mapping" subsection under
   `## Doctrine` mapping all four required fields onto the existing
   `refactoring-steps`/`characterization-tests` gate behavior, and a
   `loop_state` subsection covering all five spec values with where each
   applies.
2. **`refactoring-legacy/hooks/directive.sh`** — extended the
   `core_role_directive` `PRODUCES` string to name all four spec fields
   verbatim (`motivation:`, `refactoring_name:`, `verdict:`, `mechanics:`)
   and the `loop_state` progression (`identifying -> applying -> landed`,
   plus the `motivation-undeclared`/`tests-unreachable` refusal/error
   states) — folded into the existing string since
   `core_role_directive`'s call shape (four positional args: YOU DECIDE,
   USE_WHEN, PRODUCES, HAND-OFF) has no fifth argument slot, resolved
   during phase 2 by reading the actual call in the pre-existing file
   rather than guessed in the proposal.
3. **`characterization-tests/hooks/methodology-gate.sh`** — added a
   `motivation:` field requirement (deny names the `motivation-undeclared`
   refusal state when absent) and a `verdict: pass|fail` closed-enum
   requirement adjacent to the existing `characterization_tests_path:`/
   `test_run:` pair; `characterization_tests_path` resolution failures now
   deny naming the `tests-unreachable` error state explicitly.
4. **`refactoring-steps/hooks/methodology-gate.sh`** — added a
   `refactoring_name:` field requirement under the "refactoring steps"
   heading (alongside the existing catalog-step-as-list-item check) and a
   `mechanics:` field requirement under the "equivalence" heading
   (alongside the existing test-reference check).
5. **Both gates' `hooks/tests/run-gate-tests.sh`** — added regression
   cases: missing `motivation:` denies (characterization-tests); missing
   `verdict:` denies; all spec fields present passes; missing
   `refactoring_name:`/`mechanics:` each deny (refactoring-steps); all
   spec fields present passes; a record with two "Equivalence" headings
   where only the second is complete still passes (regression test for
   the before-landing hunt finding below).

## Rationale for deviations

None from `## What will be done` in scope or direction. One in-flight
correction, caught by the mandatory before-landing warrant hunt rather
than shipped: my first pass at `refactoring-steps/hooks/methodology-gate.sh`'s
equivalence-heading scan added an unconditional `break` after the first
matching "Equivalence" heading, regardless of whether that heading
satisfied the check — a regression from the pre-existing gate, which only
broke on success and kept scanning on failure. The hunter's stance-3
("assume the rule as written cannot hold — find the state nothing
maintains") reproduced a denial on a record whose *second* Equivalence
section carried the required test reference and `mechanics:` field while
the first did not. Fixed by breaking only when both `has_equivalence` and
`has_mechanics` are true, and by keeping the same discipline for the
`refactoring_name:` steps-heading scan (which already accumulated across
matching headings correctly and needed no change). A dedicated regression
case ("record: second Equivalence heading with test+mechanics still
passes") now guards this.

## What did not work

- Wrote `if has_catalog and has_name_field: break` / an unconditional
  `break` after the first matching "Equivalence" heading in
  `refactoring-steps/hooks/methodology-gate.sh`, without noticing the
  equivalence-heading `break` was unconditional rather than
  success-gated. Expected: scanning would continue past an incomplete
  early heading to find a later complete one, same as the pre-existing
  gate. Actual: the before-landing warrant hunt (stance 3) reproduced a
  denial on a record whose second Equivalence heading satisfied the
  requirement while the first did not — the gate stopped scanning after
  the first match. Fixed by gating the `break` on `has_equivalence and
  has_mechanics` (see Rationale for deviations above).

## Doc-placement ladder outcomes

- [x] `README.md` `## Doctrine` — spec field mapping + loop_state
  subsection added (config/doctrine-shaped change, same turn as the gate
  changes it documents).
- [x] `refactoring-legacy/hooks/directive.sh` — spec vocabulary folded
  into the existing `PRODUCES` string (role directive, same turn).
- No `docs/issue-20/decisions/` entry: no library/format choice or
  public-signature/wire-format change was made — this is a doc/gate
  vocabulary alignment inside an already-approved design, not a new
  decision.
- No `docs/issue-20/reports/` benchmark/investigation entry beyond this
  record itself: no benchmark or investigation numbers were produced.

## Open findings

None open. The before-landing warrant hunt's one finding (unconditional
`break` in the equivalence-heading scan) was fixed in this same delivery
and is recorded as closed below, not carried forward.

## Closed checks

- `closed_checks: characterization-tests/hooks/tests/run-gate-tests.sh
  (22/22 pass)` — code_under_review: unknown (working tree at delivery
  time, pre-commit).
- `closed_checks: refactoring-steps/hooks/tests/run-gate-tests.sh
  (27/27 pass, including the equivalence-heading regression case)` —
  code_under_review: unknown.
- `closed_checks: proposal-norm/hooks/tests/run-gate-tests.sh (20/20
  pass, unmodified — regression guard only)` — code_under_review: unknown.
- `closed_checks: refactoring-legacy/hooks/tests/run-gate-tests.sh (5/5
  pass, unmodified)` and
  `refactoring-legacy/hooks/tests/manifest-integrity-check.sh (clean)` —
  code_under_review: unknown.
- `closed_checks: acceptance grep criteria` — `grep -ri refactoring_name
  docs/ README.md`, `grep -ri motivation docs/ README.md`, `grep -ri
  mechanics docs/ README.md`, `grep -ri verdict docs/ README.md` each
  return >=1 hit; `grep -rE
  "identifying|applying|landed|motivation-undeclared|tests-unreachable"
  README.md refactoring-legacy/hooks/directive.sh` finds all five values
  and no other loop_state value in those two files — verified directly
  this session, before commit.

## Hunt cadence

- After-proposal hunt: recorded in the approved proposal (see its "Open
  finding from after-proposal hunt" section) and
  `docs/reports/2026-08-09-hunt-spec-vocabulary-alignment.md`'s first
  section — a pre-existing gate-independence gap, out of this proposal's
  scope, not re-litigated here.
- Before-landing hunt: dispatched at stance index 3 ("assume the rule as
  written cannot hold"), 120s cap, size bucket `21-200 lines`. One
  finding, reproduced and fixed (see Rationale for deviations / What did
  not work above); recorded in
  `docs/reports/2026-08-09-hunt-spec-vocabulary-alignment.md`'s
  before-landing section.

## Out of scope (unchanged from the proposal)

- No new `record-fields.json`/JSON-schema artifact.
- `proposal-norm/hooks/methodology-gate.sh` untouched (gates phase-1
  proposals only).
- No core-repo changes.
- `refactoring_name`'s Fowler-catalog reference-resolution mechanism
  itself, unchanged.
- No automated `verdict` recomputation (spec marks this `checked_by:
  TBD`, deferred per issue-521).
- `identifying`/`applying` progress-state gate enforcement beyond doc
  mention — no per-step progress-tracking mechanism existed to attach a
  mechanical check to.
