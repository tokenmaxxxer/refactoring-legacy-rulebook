# Issue #20 — scout brief

Mode: no web access exercised; this is a spec-conformance mapping task
(see survey.md "Skip-condition note") — grounding drawn from the two
canonical works this rulebook already cites and adopted per
`docs/issue-1/proposals/proposal.md`, plus the spec file itself. Stated as
assumptions, not fetched claims, per the scout directive's fallback for
unavailable search.

## Must-bes, grounded in the already-adopted sources

- **`refactoring_name` must be a catalog entry, not free text** — Fowler,
  *Refactoring* (catalog of named refactorings): every entry has a fixed
  name (e.g. "Extract Function", "Rename Variable"). This is already this
  rulebook's `refactoring-steps` gate behavior (a named catalog step); the
  gap is only that the record never carries the literal field label
  `refactoring_name:`. Source: `docs/issue-1/proposals/proposal.md` §(b).2,
  which already cites Fowler by name for this exact requirement.
- **`motivation` precedes mechanics in a well-formed refactoring record** —
  Fowler's own catalog entries are structured as motivation → mechanics for
  every single refactoring (why you'd do it, then how) — this is the
  standard shape of a Fowler catalog entry, not an invented field. Assumed
  from the cited work's well-known structure (no web fetch performed to
  re-confirm; this is the same catalog already adopted as this rulebook's
  methodology source).
- **`verdict` as a closed pass/fail, recomputed from re-running tests** —
  matches Feathers' characterization-test discipline exactly: a
  characterization test's purpose is to be re-run and re-checked, not
  asserted once. The existing `test_run: PASS (<command>)` field already
  captures this idea in free-text form; the spec's contribution is
  narrowing it to an enum and naming it `verdict`.

## Performance axes (what a compliant record now competes on)

1. Field-name grep-ability — spec's acceptance check is literally `grep -ri
   <field> docs/`, so doctrine prose and gate error messages must use the
   spec's literal field names, not just the equivalent concept in
   different words.
2. loop_state enum tightness — no stale/extra states beyond the five the
   spec names.

## Adopt / skip

- **Adopt**: renaming/aliasing existing doctrine vocabulary to the spec's
  literal field names (`refactoring_name`, `motivation`, `mechanics`,
  `verdict`) everywhere it is already conceptually present, per issue #20's
  own instruction to "strengthen existing content, never delete
  methodology."
- **Skip**: inventing new enforcement machinery (e.g. a
  `record-fields.json`) beyond what's needed to make the four field names
  and five loop_state values appear and be checked — issue #20 asks for
  vocabulary alignment, not a new methodology.

## Gap line

Already met: the *concepts* behind all four fields and the terminal
loop_state (`landed`) already exist in doctrine/gates. Missing: the
spec's literal vocabulary (grep-matchable field names) for all four
fields, and the non-terminal/refusal/error loop_state vocabulary
(`identifying`, `applying`, `motivation-undeclared`, `tests-unreachable`),
which has no doctrine home at all today.

Sources: `docs/issue-1/proposals/proposal.md` (already-adopted Fowler/
Feathers citations, this repo); `roles/specs/refactoring-legacy.spec.json`
(the spec itself, read in full in survey.md).
