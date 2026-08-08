---
status: proposed
files:
  - README.md
  - refactoring-legacy/hooks/directive.sh
  - characterization-tests/hooks/methodology-gate.sh
  - characterization-tests/hooks/tests/run-gate-tests.sh
  - refactoring-steps/hooks/methodology-gate.sh
  - refactoring-steps/hooks/tests/run-gate-tests.sh
---

# Issue #20 — proposal: align rulebook vocabulary with `refactoring-legacy.spec.json`

References #20. Built on
`docs/issue-20/reports/implementation/survey.md` and
`docs/issue-20/reports/implementation/scout-brief.md`.

## Request

Layer the realized marketplace spec's four required deliverable fields
(`refactoring_name`, `motivation`, `mechanics`, `verdict`) and its five
`loop_state` values (`identifying`, `applying`, `landed`,
`motivation-undeclared`, `tests-unreachable`) onto this rulebook's
existing methodology docs and gates — strengthening what's already there,
deleting nothing.

## Constraints

- Every spec field name must appear in the rulebook docs after phase 2,
  checkable via `grep -ri <field> docs/ README.md`.
- The rulebook's loop_state vocabulary must match the spec's five values
  exactly — no stale or extra states.
- No existing methodology content may be deleted; only strengthened
  (per issue #20's own instruction).
- Any spec field with no natural home must be called out explicitly with
  reasoning, not silently dropped.
- `refactoring_name` must remain a Fowler-catalog reference, matching the
  spec's own `reference_resolution` rule — this rulebook's
  `refactoring-steps` gate already enforces exactly this constraint.

## Rationale

**Alternative considered and rejected: introduce a new
`record-fields.json`/JSON schema artifact to carry the four fields and
five states, machine-checked from scratch.** Rejected because the survey
found every spec concept already has a doctrine/gate home under different
vocabulary (`refactoring-steps`'s named catalog step ≈ `refactoring_name`;
the (b).2 refactoring plan ≈ `mechanics`; `test_run: PASS` ≈ `verdict`);
building new JSON-schema machinery would duplicate what the two existing
`hooks/methodology-gate.sh` scripts already structurally check, and issue
#20 explicitly asks to strengthen existing content, not add a parallel
enforcement system. The chosen approach — renaming/aliasing to the spec's
literal field names inside the existing gates and docs — satisfies the
acceptance grep check with less surface area and no new failure mode for
a JSON file to go stale against.

**Alternative considered and rejected: leave `motivation` and the four
non-`landed` loop_state values entirely unaddressed, since the survey
found no existing doctrine placeholder for them.** Rejected per the
issue's own "empty state" acceptance clause — a spec field with no
natural home must be given one with stated reasoning, not skipped. The
scout-brief grounds `motivation` in Fowler's own catalog-entry shape
(motivation precedes mechanics in every catalog entry this rulebook
already cites), so it has a defensible home: the same
`characterization-tests` gate that already requires a `test_run:` field
adjacent to test evidence, since motivation is the *why* half of the
record the gate already partially covers.

## What will be done

1. **`README.md` `## Doctrine`** — add a "Spec field mapping" subsection
   under the existing bullets, stating the four-field grep-matchable
   mapping (`refactoring_name`, `motivation`, `mechanics`, `verdict`) onto
   the already-described `refactoring-steps`/`characterization-tests`
   bullets, and a loop_state subsection listing all five spec values with
   one line each on where they apply (progress: while a record is open
   but not yet landed; refusal: `motivation-undeclared` when no
   `motivation:` field is present; error: `tests-unreachable` when the
   characterization test command cannot be run at all, distinct from
   `verdict: fail` which means the tests ran and failed).

2. **`refactoring-legacy/hooks/directive.sh`** — extend the
   `core_role_directive` `PRODUCES` string to name the four required
   record fields explicitly by their spec field names (currently the
   ordered-procedure prose never uses the words "motivation", "mechanics",
   or "verdict" verbatim), and add the loop_state vocabulary as a fifth
   `core_role_directive` argument if the call shape supports a fifth
   string, else fold it into `PRODUCES` — resolved against
   `core/hooks/lib/role-directive.sh`'s actual signature during phase 2,
   not guessed here.

3. **`characterization-tests/hooks/methodology-gate.sh`** — extend the
   existing structural check (currently: characterization-test heading +
   adjacent `characterization_tests_path:`/`test_run: PASS (<command>)`
   pair) to also require a `motivation:` field adjacent to that pair, and
   to accept/require `verdict: pass`/`verdict: fail` as the closed-enum
   companion to the existing free-text `test_run:` line (both present:
   `test_run:` keeps the human-readable command evidence, `verdict:`
   supplies the spec's checkable enum). Missing `motivation:` denies the
   write with a message naming the `motivation-undeclared` refusal state;
   a `characterization_tests_path` file that fails to resolve/is
   unreadable denies with a message naming the `tests-unreachable` error
   state — both states become real gate outcomes, not just doc prose.

4. **`refactoring-steps/hooks/methodology-gate.sh`** — extend the
   existing Fowler-catalog-step-as-list-item check to also require the
   step be labeled with an explicit `refactoring_name:` field (the catalog
   name), and extend the existing equivalence-note check to require a
   `mechanics:` field naming the applied step sequence, adjacent to the
   existing "equivalence" heading requirement.

5. **Both gates' `hooks/tests/run-gate-tests.sh`** — add regression cases
   for: a record missing `motivation:` is denied (characterization-tests);
   a record missing `refactoring_name:` or `mechanics:` is denied
   (refactoring-steps); a record with all spec fields present and a valid
   `verdict:` value passes.

## Out of scope

- Any new JSON schema/`record-fields.json` artifact — per Rationale above.
- `proposal-norm/hooks/methodology-gate.sh` — it gates phase-1 proposals,
  which carry none of the four phase-2 deliverable fields; untouched.
- The core-canon `record-fields-gate.sh`/`role-directive.sh` files
  themselves — this rulebook references core, it doesn't vendor or edit
  it; any core-side signature change needed for directive.sh's fifth
  argument is a core-repo change, reported as a finding here if phase 2
  discovers it's required, not made in this write set.
- `refactoring_name`'s Fowler-catalog reference-resolution mechanism
  itself — already correctly enforced by `refactoring-steps`'s existing
  "named Fowler-catalog step" check; this proposal only adds the literal
  field label, not new resolution logic.
- Recomputation enforcement (spec: "`verdict` is recomputed by re-running
  the test suite after `mechanics` is applied") — the spec itself marks
  this `checked_by: TBD`, a deferred cross-role follow-up per issue-521;
  this proposal adds the `verdict:` field's presence/enum-shape check
  only, not automated re-execution.
- `identifying`/`applying` progress-state gate enforcement beyond doc
  mention — the survey found no existing per-step progress-tracking
  mechanism in this rulebook to attach a mechanical check to (README
  already notes this as open, unchanged from issue #13's Out-of-scope
  call); phase 2 documents these two states in README/directive.sh only.

## How you'll know it worked

- `grep -ri refactoring_name docs/ README.md`,
  `grep -ri motivation docs/ README.md`, `grep -ri mechanics docs/
  README.md`, and `grep -ri verdict docs/ README.md` each return at least
  one hit after phase 2.
- `grep -rE "identifying|applying|landed|motivation-undeclared|tests-unreachable" docs/ README.md refactoring-legacy/hooks/directive.sh`
  finds all five values, and no other loop_state value is introduced
  anywhere in the same files.
- `characterization-tests/hooks/tests/run-gate-tests.sh` and
  `refactoring-steps/hooks/tests/run-gate-tests.sh` both pass, including
  the new regression cases from item 5 above.
- `pytest`/`tests/*.sh` run clean if present; the acceptance criterion's
  `unverifiable: no test suite present` fallback applies only if neither
  exists after phase 2 (it will — the two `run-gate-tests.sh` scripts are
  the test suite here).
