# Issue #1 — Phase 1 proposal: refactoring-legacy proposal and deliverable methodology norms

Status: proposal only — not executed, not approved.

## Context

This rulebook (`refactoring-legacy`) currently has no explicit methodology
doctrine beyond the four-string directive (`YOU DECIDE`/`USE_WHEN`/
`PRODUCES`/`HAND-OFF`) — see
`docs/issue-1/reports/refactoring-legacy/survey.md` for the full audit.
README.md itself flags this: *"fill in doctrine detail ... before treating
it as load-bearing."* Issue #1 asks this repo to decide, based on domain
research rather than gut feel, what methodology phase-1 proposals and
phase-2 deliverables under this role must follow. The scout sweep grounding
the choices below is at
`docs/issue-1/reports/refactoring-legacy/scout-brief.md`.

## (a) Proposal norm — required methodology and sections for this rulebook's own phase-1 documents

Every phase-1 proposal under `refactoring-legacy` must, going forward:

1. Reference a current-state survey document (`reports/<role>/survey.md`)
   written first, per contract v3 s19's rigor floor — establishing what the
   rulebook currently enforces and what's thin/unknown/contested, so the
   scout sweep has a target instead of researching in a vacuum.
2. Reference a scout-brief document (`reports/<role>/scout-brief.md`)
   recording the domain research performed, with an explicit `Sources:`
   list — real URLs if fetched, or a plainly stated "no web access, built
   on named canonical sources as stated assumptions" if not. No fabricated
   citations.
3. State the adopted methodology by name and cite its origin (author/work),
   not just describe it in the proposal's own words — e.g. this document
   cites Fowler's *Refactoring* and Feathers' *Working Effectively with
   Legacy Code* by name in section (c) below, rather than paraphrasing the
   ideas as if self-derived.
4. Present options considered vs. the option chosen, with the logical
   justification for the choice (an ADR/RFC-shaped context → options →
   decision → consequences skeleton, adopted per the scout-brief's finding
   that this is the standard lightweight format and that this repo's own
   prior proposals — issue-2, issue-5 — already converge on the same shape
   without naming it).
5. Include an explicit "Out of scope" section naming what is deliberately
   deferred to phase 2 or excluded entirely.
6. Include phase-2 verification criteria: how a reviewer or gate will later
   confirm the proposal's adopted norms were actually reflected in the
   plugin, once Approved.

This document is itself the first instance required to satisfy points 1–6
— it demonstrates the norm it sets, rather than only prescribing it for
others.

## (b) Deliverable norm — required methodology and components for phase-2 refactoring deliverables

Every phase-2 deliverable produced under this role (matching README's
`produces`: refactoring plan, characterization tests, before/after
behavior-equivalence note) must contain:

1. **A behavior-preservation characterization test, written before any
   structural change is made.** The test records the code's actual
   observed input/output behavior at the point work begins — not a
   post-hoc test written after the refactor to check it still "seems
   right." This is the Feathers characterization-test discipline: legacy
   code is code without test coverage, and the fix for that gap must exist
   *before* the coverage-dependent operation (restructuring) is attempted.
2. **A refactoring plan expressed as a sequence of small, named
   refactorings** — not a monolithic "rewrite module X" description. Each
   named step must be independently completable and independently leave
   the system in a working state, per Fowler's definition of refactoring
   as composed of individually-small, behavior-preserving transformations.
3. **A before/after behavior-equivalence note that cites the passing
   characterization tests as its evidence** — not an unsupported assertion
   that behavior is unchanged. The note must name which characterization
   tests were run and confirm they pass identically before and after the
   full sequence of steps in (2).
4. **An explicit scope boundary stating no behavior or feature changes are
   bundled into the deliverable.** Per Fowler's definition, a change that
   alters observable behavior is not a refactor by definition; any such
   change discovered mid-work must be called out and handed off per this
   role's existing `HAND-OFF` clause (→ `implementation`), not folded
   silently into the refactoring deliverable.

This proposal does not mandate a specific test framework, golden-master
tool, or seam/dependency-breaking technique — per the scout-brief's
adopt/skip call, prescribing implementation tooling here would overfit
doctrine to a stack this role-agnostic rulebook doesn't own. The
requirement is that a characterization test exists, runs first, and passes
before and after — not how it is constructed.

## (c) Rationale

- **(a).1–2 (survey-then-scout ordering)** follows necessarily from this
  role's `decides` question — "can existing code be safely restructured
  without changing observable behavior" is a factual/technical judgment,
  not a preference, so the proposal answering it must show its evidence
  trail (what's already enforced, what was researched) rather than assert
  a conclusion.
- **(a).3–4 (named methodology + ADR shape)** follows from the issue's own
  explicit ask: "not gut feel" requires citing which established
  methodology was adopted and why it was chosen over alternatives, which
  is exactly what naming Fowler/Feathers and showing an options-vs-decision
  trail accomplishes; the ADR/RFC shape is adopted because it is the
  established lightweight vehicle for exactly this kind of record in
  software engineering, and this repo's own prior proposals already
  approximate it.
- **(a).5–6 (out-of-scope + verification criteria)** follows from contract
  v3's phase-1/phase-2 split itself: a phase-1 document that doesn't say
  what it excludes and how phase-2 will be checked cannot be verified
  later, defeating the purpose of gating phase-2 behind Approve.
- **(b).1 (test-first)** follows directly from Feathers' definition of
  legacy code as *code without tests* — the role's stated purpose is
  restructuring "existing code" (README's `use_when`: "레거시/기존 코드에
  손을 대야 할 때"), and Feathers' whole technique exists because you
  cannot safely restructure code you cannot verify still behaves the same;
  a test written after the fact cannot serve as the safety net during the
  change, only as a post-hoc check — the ordering is not stylistic, it is
  what makes the test a safety net at all.
- **(b).2 (small named steps)** follows directly from Fowler's definition
  of refactoring as composed of individually-small transformations — a
  "refactoring plan" that is one big rewrite step is not a refactoring
  plan under the definition this role is meant to operate by, and cannot
  be independently verified or halted partway if something goes wrong.
- **(b).3 (evidence-citing equivalence note)** follows from README's
  `produces` field literally naming "before/after behavior-equivalence
  note" — a note is only evidence, not assertion, if it points at the
  passing tests from (b).1 that actually establish equivalence.
- **(b).4 (scope boundary)** follows from Fowler's definition combined
  with this role's own existing `HAND-OFF` clause: since a refactor is
  defined as *not* changing observable behavior, anything that does change
  it is by definition outside this role's `produces`, and the rulebook
  already names where it should go instead (`implementation`) — (b).4 just
  makes that boundary an explicit required component of every deliverable
  rather than an implicit assumption.

## (d) Plugin reflection plan (phase 2 — design only, not implemented in this PR)

Pending Approve, phase 2 should:

- **`refactoring-legacy/hooks/directive.sh`**: extend the `PRODUCES` value
  (or add a parallel value the `core_role_directive` call surface accepts)
  to enumerate the three required deliverable components from (b) by name,
  rather than the current unstructured three-noun list — e.g. rendering
  something equivalent to "characterization tests (written first),
  refactoring plan (small named steps), before/after behavior-equivalence
  note (evidence-citing)". Exact rendering mechanism depends on what
  `core_role_directive`'s call shape supports; a phase-2 check against
  `core/hooks/lib/role-directive.sh` is needed before deciding whether this
  requires a core-level change or fits within the existing four-string
  call.
- **Record required-fields**: define an equivalent to a
  `record-fields.json` (or an addition to whatever record-fields
  mechanism core's canon gate reads, per issue-2's conversion) listing
  three required fields for a `refactoring-legacy` record to reach a
  terminal `loop_state`: `characterization_tests_path` (pointer to the
  test file(s) proving pre-change behavior capture),
  `refactoring_steps` (the named small-step sequence from (b).2),
  `behavior_equivalence_note` (citing the passing tests). This is a design
  intent, not a file created in this PR.
- **Gate(s)**: a phase-2 gate (new script, or an extension of the
  core-canon `record-fields-gate.sh` this rulebook already references per
  issue-2) should check, before a record's `loop_state` moves to a
  terminal state, that all three fields above are present and
  non-empty, and — if mechanically feasible — that the
  `characterization_tests_path` file's git history predates the first
  edit to the refactored source path (operationalizing test-first
  ordering, not just presence). The ordering check may not be feasible
  with the tooling core's canon currently exposes; if not, phase 2 should
  fall back to a presence-only check and note the gap explicitly rather
  than silently skip it.

None of the above is implemented in this PR.

## Out of scope

- Any edit to `refactoring-legacy/hooks/directive.sh`,
  `refactoring-legacy/hooks/hooks.json`, or
  `refactoring-legacy/.claude-plugin/plugin.json` — all deferred to phase 2
  pending Approve.
- Any new gate script or record-fields file — described as a plan in (d)
  only, not created here.
- `docs/specs/approvers.md` — untouched.
- Prescribing a specific test framework, golden-master/snapshot tool, or
  seam-identification technique — per the scout-brief's adopt/skip call,
  left to the implementer's judgment per deliverable.
- Re-litigating issue-2/issue-5's already-completed reference-plumbing
  conversions — this proposal is purely additive doctrine on top of that
  existing state.

## References

- `docs/issue-1/reports/refactoring-legacy/survey.md`
- `docs/issue-1/reports/refactoring-legacy/scout-brief.md`
