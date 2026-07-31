# Current-state survey — issue-1 (refactoring-legacy)

## Question

What does this rulebook currently say or enforce about (a) the methodology
phase-1 proposals must follow, and (b) the methodology/components phase-2
deliverables must follow?

## What exists today

- `refactoring-legacy/hooks/directive.sh` — sources core's
  `role-directive.sh` and supplies exactly four strings: `YOU DECIDE`,
  `USE_WHEN`, `PRODUCES` (`refactoring plan, characterization tests,
  before/after behavior-equivalence note`), `HAND-OFF`. This is the entire
  doctrine surface. It names the three PRODUCES nouns but says nothing about
  *what makes a valid instance* of any of them — no required internal
  structure, no ordering constraint (e.g. must tests exist before the
  structural change, or is that undefined), no format.
- `refactoring-legacy/hooks/hooks.json` — wires `directive.sh` to
  `SessionStart` and a `refactoring-legacy-progress-gate.sh` to `PreToolUse`
  on `Bash`. That gate script **does not exist in this repo** (confirmed by
  `ls refactoring-legacy/hooks/` — only `directive.sh` and `hooks.json`
  present; the progress-gate entry is dangling, a pre-existing gap noted
  independently in issue-2's survey.md and out of scope there too). No gate
  currently checks for the presence, ordering, or content of a
  characterization test, a refactoring plan, or a behavior-equivalence note.
- `refactoring-legacy/.claude-plugin/plugin.json` — one-line role
  description matching the directive strings; no methodology content.
- `README.md` — states `decides`/`use_when`/`produces`/`write_scope`/
  `hand-off` (mirrors directive.sh) and documents the core-canon install/
  layout (issue #2, #5 outcomes). It explicitly says: *"This is scaffolding,
  not a finished rulebook: fill in doctrine detail, handoff enforcement, and
  any role-specific progress gate before treating it as load-bearing."* —
  i.e. the repo itself flags that doctrine is missing.
- `docs/specs/approvers.md` — lists the Approve-authority login only; no
  methodology content (out of scope to touch, per task).
- No prior `docs/issue-*` in this repo addresses proposal methodology or
  deliverable methodology; issue-2 and issue-5 were reference-plumbing
  conversions (structural, not doctrinal) and used a proposal/scout-brief/
  survey document *shape* worth reusing stylistically, but neither one
  articulates a general methodology norm — each is scoped to its own narrow
  mechanical change.

## Gap, stated plainly

There is currently **no explicit methodology doctrine** in this rulebook
beyond the one-line `PRODUCES` string. Nothing defines:

- what sections a phase-1 proposal document must contain, or what counts as
  adequate evidence/citation for an adopted methodology choice;
- what "a refactoring plan" must look like structurally (a single paragraph
  intent statement would technically satisfy today's directive text);
- whether a characterization test must exist *before* or *after* a
  structural change is made (the directive's PRODUCES lists it as an
  output, not as a precondition — this is genuinely undefined, not just
  underspecified);
- what a "before/after behavior-equivalence note" must cite as evidence
  (test IDs? test run output? nothing is specified);
- any gate enforcing presence of these three components on a record before
  it reaches a terminal `loop_state`.

## What's thin / unknown / contested (steers the scout sweep)

- **Thin**: the PRODUCES list names three nouns with zero internal
  structure specified for any of them.
- **Unknown**: whether "test-first" (characterization test written before
  any structural edit) is intended by this role's `decides` framing
  ("without changing observable behavior") or left to author discretion.
  This is the single most consequential open question — resolving it is
  the point of the scout sweep below, since the answer determines whether
  the phase-2 gate can even mechanically check test-first ordering (e.g.
  via git history) or only presence.
- **Contested-by-omission**: no proposal-methodology norm exists anywhere
  in this repo (issue-2/issue-5 are structural conversions, not general
  precedent for *content* methodology), so there is no established citation
  format for "why was this choice adopted" — this proposal must set that
  norm for itself and for future phase-1 work under this role, not just
  for phase-2 deliverables.

## Sources

- `refactoring-legacy/hooks/directive.sh`, `hooks.json`,
  `.claude-plugin/plugin.json` (read directly, this repo).
- `README.md` (read directly, this repo).
- `docs/issue-2/reports/implementation/survey.md`,
  `docs/issue-5/proposals/proposal.md` (read for document-shape precedent
  only, not methodology precedent — neither addresses doctrine content).
