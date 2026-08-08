# Issue #20 — current-state survey

Scope: what the realized marketplace spec
`roles/specs/refactoring-legacy.spec.json` requires, and what this rulebook
currently has on disk for each of those requirements.

## Spec content (verbatim facts)

- `required_fields`: `refactoring_name` (type `ref`), `motivation` (type
  `string`), `mechanics` (type `string`), `verdict` (type `enum`,
  `[pass, fail]`).
- `reference_resolution`: `refactoring_name` must resolve to an actual
  Fowler-catalog entry (issue-515 invariant 2).
- `recomputation`: `verdict` is recomputed by re-running the test suite
  after `mechanics` is applied — never a standalone asserted field.
- `write_scope`: `docs/issue-<n>/reports/refactoring-legacy.md`.
- `loop_state`: progress `[identifying, applying]`, terminal `[landed]`,
  refusal `[motivation-undeclared]`, error `[tests-unreachable]`.
- `use_when`: a code smell is flagged on the branch AND no
  refactoring-legacy record exists yet for that smell.

## What this rulebook currently has, per spec field

- **`refactoring_name`**: partially present. `refactoring-steps/hooks/methodology-gate.sh`
  already requires "a named Fowler-catalog step as a list item under a
  'refactoring steps' heading" (README `## Doctrine`, `refactoring-steps`
  bullet) — this is the reference-resolution concept, but the record
  carries it as an unlabeled list item under a heading, never as an
  explicit `refactoring_name:` field the spec's field name would grep-match.
  `grep -ri refactoring_name docs/ README.md` currently returns nothing.
- **`motivation`**: absent. No doctrine component, gate check, or directive
  string anywhere in this rulebook asks for a stated *why* behind a
  refactor. `docs/issue-1/proposals/proposal.md`'s deliverable norm (b)
  lists four required components (characterization test, refactoring plan,
  equivalence note, scope boundary) — none is a motivation/rationale-for-
  refactoring field. `grep -ri motivation docs/ README.md` returns nothing.
- **`mechanics`**: partially present under different vocabulary. Doctrine
  (b).2 already requires "a refactoring plan expressed as a sequence of
  small, named refactorings" — this *is* the mechanics of the change, but
  the word "mechanics" itself never appears in README, directive.sh, or
  either gate; the existing vocabulary is "refactoring plan" / "refactoring
  steps". `grep -ri mechanics docs/ README.md` returns nothing.
- **`verdict`**: partially present under different vocabulary and shape.
  `characterization-tests/hooks/methodology-gate.sh` requires an adjacent
  `test_run: PASS (<command>)` field, and the spec's own
  `recomputation` rule ("verdict is recomputed by re-running the test suite
  after mechanics is applied") describes exactly what `test_run:` already
  captures — but `test_run:` is a free-text self-report, not the spec's
  closed `pass`/`fail` enum, and the literal string `verdict` appears
  nowhere in docs/README.
- **`loop_state` vocabulary**: diverges from the spec. Every landed record
  in this repo (`docs/issue-1/reports/refactoring-legacy.md`,
  `docs/issue-10/...`, `docs/issue-13/...`, `docs/issue-16/...`) uses only
  `loop_state: landed` — matching the spec's terminal set. But nothing in
  README, directive.sh, or any gate documents or checks for the spec's
  non-terminal vocabulary (`identifying`, `applying`) or its refusal/error
  states (`motivation-undeclared`, `tests-unreachable`); a record that
  never reaches `landed` has no place in this rulebook's current doctrine
  to say what state it's in or why. There is no
  `docs/specs/record-fields-terminal-states.json` override file in this
  repo, so the terminal-state set for this role's records currently comes
  only from core's generic default plus the informal `landed`-only
  convention observed in every prior record — never written down as an
  explicit enum anywhere in this repo.

## Existing methodology-enforcement surface (where field/state doctrine would attach)

- `README.md` `## Doctrine` — the norm's prose home; already has
  `refactoring-steps`/`characterization-tests`/`proposal-norm` bullets
  naming what each gate structurally checks.
- `refactoring-legacy/hooks/directive.sh` — `core_role_directive` four-string
  call (`YOU DECIDE`/`USE_WHEN`/`PRODUCES`/`HAND-OFF`); `PRODUCES` already
  names the ordered procedure but not spec field names or loop_state.
- `characterization-tests/hooks/methodology-gate.sh` — PreToolUse gate on
  `docs/issue-<n>/reports/refactoring-legacy.md`; structurally checks for a
  characterization-test heading plus adjacent
  `characterization_tests_path:`/`test_run: PASS (<command>)` pair.
- `refactoring-steps/hooks/methodology-gate.sh` — PreToolUse gate on the
  same record; checks for a Fowler-catalog step list item under a
  "refactoring steps" heading and a before/after equivalence note under an
  "equivalence" heading; separately denies `src/**` writes unless
  `characterization_tests_path` is already set.
- `proposal-norm/hooks/methodology-gate.sh` — gates phase-1 proposals only,
  not phase-2 records; out of this issue's field-mapping scope since none
  of the four spec fields are phase-1 concepts.
- No `record-fields.json`/`record-fields-terminal-states.json` exists in
  this repo — loop_state vocabulary for this role is not currently encoded
  as a checked JSON artifact anywhere in this tree.

## Skip-condition note (scout)

This issue is a pure spec-to-doctrine vocabulary mapping: the four field
names and five loop_state values are fixed, verbatim, by
`roles/specs/refactoring-legacy.spec.json` (already read in full above),
and the methodology each field maps onto (Fowler's catalog, Feathers'
characterization-test discipline) is already the adopted, cited source of
this rulebook's doctrine per `docs/issue-1/proposals/proposal.md` — no
external product category or exemplar applies to a spec-conformance
mapping task. A short scout-brief is still written
(`docs/issue-20/reports/implementation/scout-brief.md`) grounding the two
new fields (`motivation`, `verdict`) in Fowler/Feathers' own vocabulary
rather than skipping outright, since that grounding is the one open
judgment call this survey leaves for the proposal to make.
