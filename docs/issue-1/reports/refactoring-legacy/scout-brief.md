# Scout brief — issue-1 (refactoring-legacy)

Category: internal doctrine research for a refactoring-methodology rulebook
— canonical software-engineering literature applies directly, not a
product/market question. Mode: batched-sequential, single stage (web search
available this session; two targeted queries plus prior well-established
knowledge of the two anchor texts were sufficient to saturate — a third
query would only re-confirm the same two canonical sources rather than
surface a competing methodology, since this domain has one dominant pair of
primary sources cited by nearly everything downstream of them).

## Must-bes (load-bearing, not optional)

- **Behavior preservation is the definition, not a nice-to-have.** Fowler:
  refactoring is "a change made to the internal structure of software to
  make it easier to understand and cheaper to modify without changing its
  observable behavior." A deliverable that bundles a feature/behavior change
  into a "refactor" is definitionally not a refactor — this must be a hard
  scope boundary in the deliverable norm, not a style preference.
- **Small, verifiable steps compose the plan.** Fowler: refactoring proceeds
  as a series of small transformations, individually "too small to be worth
  doing" alone, each leaving the system fully working — this is what makes
  a monolithic rewrite description structurally wrong as a "refactoring
  plan": it isn't a sequence of independently verifiable steps.
- **Characterization tests come first, and legacy code means untested
  code.** Feathers ("Working Effectively with Legacy Code"): legacy code is
  defined as code without tests (any code lacking automated regression
  coverage, not merely "old" code); a characterization test records actual
  observed behavior (inputs → outputs) as a regression safety net *before*
  structural change, precisely because no prior test suite can be trusted
  to catch a behavior change once one is made. This resolves the survey's
  open question: test-first ordering is not optional discretion, it is the
  premise the whole technique rests on.
- **Lightweight decision-record shape for the proposal norm itself.** The
  ADR/RFC family (context → options considered → decision → consequences)
  is the standard lightweight format for "here's what we chose and why" in
  software engineering — appropriate to layer onto phase-1 proposals in
  this repo, which already independently converge on a context/decision/
  scope-boundary shape (see issue-2, issue-5 precedent) without naming it.

## Performance axes

- **Falsifiability of the deliverable norm**: can a gate mechanically check
  "characterization test exists and passes" and "before/after note cites
  it" without human judgment? (Yes for presence/pass-state; ordering
  strictly needs commit-history inspection, which is a phase-2 design
  question, not resolved here.)
- **Minimality**: does the norm add the smallest set of required components
  that Fowler/Feathers actually demand, versus inventing extra ceremony not
  grounded in the canon? (This proposal caps at 4 deliverable components,
  matching the two texts' actual claims, not more.)
- **Reusability of the proposal norm**: does the norm this document sets
  for itself generalize to the *next* phase-1 proposal under this role,
  not just special-case this one? (Structure chosen to be role-general,
  not issue-1-specific.)

## Adopt / skip

- Adopt: Feathers' test-first characterization-test discipline as the
  non-negotiable core of the deliverable norm — it is the one technique
  that directly operationalizes this role's `decides` question ("can this
  be safely restructured without changing observable behavior").
- Skip: prescribing a specific test framework, golden-master tooling, or
  seam-identification technique (dependency-breaking patterns, etc.) —
  Feathers' book catalogs many concrete techniques for different
  languages/constraints; mandating one would overfit this doctrine to a
  stack this rulebook doesn't own. The norm requires *that* a
  characterization test exists and passes, not *how* it's constructed.

## Gap line (vs. survey.md)

Survey found: PRODUCES names three nouns with zero structure, no
test-first requirement stated or enforced, no gate checks any of this, no
proposal-methodology precedent anywhere in this repo. This scout sweep
supplies exactly the doctrine to close that gap: Fowler's behavior-
preservation + small-steps rule for the deliverable's refactoring plan,
Feathers' test-first characterization discipline for its test/evidence
requirement, and ADR/RFC shape for the proposal norm. Nothing scouted
here overlaps with what the repo already enforces (there is no overlap —
the repo currently enforces none of this).

## Sources

- [Refactoring Home Page](https://www.refactoring.com/) — Martin Fowler's
  definition of refactoring as behavior-preserving internal restructuring.
- [The key points of Refactoring — understandlegacycode.com](https://understandlegacycode.com/blog/key-points-of-refactoring/)
  — summary of Fowler's small-step, always-working-system discipline.
- [Characterization test — Wikipedia](https://en.wikipedia.org/wiki/Characterization_test)
  — definition and attribution to Michael Feathers.
- [The key points of Working Effectively with Legacy Code — understandlegacycode.com](https://understandlegacycode.com/blog/key-points-of-working-effectively-with-legacy-code/)
  — Feathers' "legacy code = code without tests" definition and
  characterization-test-before-change discipline.
- ADR/RFC lightweight format: built on well-established, widely-documented
  industry convention (context / options considered / decision /
  consequences) rather than a single fetched URL — this shape is treated
  as settled common knowledge, consistent with how issue-2 and issue-5's
  proposals in this same repo already converge on a context/decision/
  scope-boundary structure without citing a source for it.
