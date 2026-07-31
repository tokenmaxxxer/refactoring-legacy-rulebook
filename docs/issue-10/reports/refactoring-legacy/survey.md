# Current-state survey — issue-10 (refactoring-legacy)

## Question

What does this rulebook currently enforce mechanically (not just document)
for its own phase-1 proposals and phase-2 deliverables, and what would an
"implementation-rulebook-level" hook machine require on top of that?

## What exists today

- `refactoring-legacy/hooks/directive.sh` — enriched by issue-1 phase 2:
  `PRODUCES` now names the three deliverable components with their
  attribution (characterization tests written first — Feathers; small
  named refactoring steps — Fowler; evidence-citing before/after
  equivalence note). Still a `SessionStart` string only — read once,
  never re-checked, never enforced against an actual write.
- `README.md` — has a `## Doctrine` section (issue-1) stating the same
  proposal norm (a) and deliverable norm (b) as prose, plus an explicit
  **"Enforcement gap, stated plainly"** paragraph: core's
  `record-fields-gate.sh` only checks the generic contract §20 fields
  (what-was-done/why/upstream-basis/loop_state/open-findings); core's
  contract table (role-handoff-contract.md §2) hardcodes required fields
  per role for nine canonical roles only, and `refactoring-legacy` is not
  one of them, with no mechanism to register custom fields into core's
  gate. Issue-1 phase 2 explicitly declined to vendor a bespoke gate,
  calling that scope beyond what issue #1 asked.
- `refactoring-legacy/hooks/hooks.json` — wires `directive.sh` to
  `SessionStart` and a `refactoring-legacy-progress-gate.sh` to
  `PreToolUse`/`Bash`. **That file still does not exist** — the same
  dangling entry flagged independently by issue-1, issue-2, and issue-5's
  surveys, still unresolved three issues later.
- No `tests/` directory anywhere in this repo. No gate has ever been
  exercised as a subprocess here.
- No `agents/` directory. No checklist file.
- `docs/issue-1/proposals/proposal.md` — the adopted methodology-norms
  document; still the only doctrine source. It already ends with a
  "Plugin reflection plan (phase 2 — design only)" section (d) that names
  three candidate record fields (`characterization_tests_path`,
  `refactoring_steps`, `behavior_equivalence_note`) and flags that
  test-first *ordering* (not just presence) may not be mechanically
  checkable — but stops at "design intent," never implemented.
- Sibling rulebooks in the same monorepo family already carry a working
  local methodology gate of the exact shape issue #10 asks for:
  `pricing-rulebook/pricing/hooks/methodology-gate.sh` — a
  `PreToolUse`/`Write|Edit|MultiEdit` gate that resolves the post-write
  content of the target file (handling `Write`, `Edit`, and `MultiEdit`
  tool inputs, including partial `MultiEdit` application), restricts
  itself by filename regex to the role's own proposal/record write
  surfaces, checks for role-specific required elements via keyword/regex
  presence, and fails closed (`exit 2`) on any of: unparseable payload,
  unresolvable content, or a missing element — never fails open on an
  internal error (wrapped in `trap __fc EXIT` plus a Python-level
  `except Exception` fail-closed handler). It references core's
  `record-fields-gate.sh` conceptually ("on top of, never instead of")
  without copying its code. `implementation-rulebook/coding/hooks/`
  (issue-56 branch) additionally shows the gate-test harness shape this
  repo lacks: `tests/run-gate-tests.sh` spins up a throwaway git repo per
  case, pipes a synthetic tool-call JSON payload on stdin to the gate
  script as a real subprocess, and asserts the exit code (`0`=allow,
  `2`=deny) — no framework, pure bash + python3 available everywhere.

## Gap, stated plainly

Doctrine (issue-1) fully describes what a valid deliverable must contain.
Nothing mechanically checks it. Concretely, none of the following exist:

- A gate that inspects a `docs/issue-<n>/reports/refactoring-legacy.md`
  write and denies it if `characterization_tests_path`,
  `refactoring_steps`, or `behavior_equivalence_note` (or equivalent
  named content) is absent.
- A gate that inspects a `docs/issue-<n>/proposals/*.md` write under this
  role and denies it if the six-point proposal norm (survey ref,
  scout-brief ref + Sources, named methodology + citation, options-vs-
  decision, out-of-scope, phase-2 verification criteria) is not visibly
  present.
- Any state-tracking mechanism enforcing the one methodology-internal
  ordering constraint this role's own doctrine already asserts:
  characterization tests must exist **before** the structural change,
  not merely be present at delivery time. Issue-1 phase 2 flagged this as
  possibly infeasible and fell back to a presence-only design without
  building even that.
- Any test file exercising a gate as a subprocess.
- Any agent/checklist for the repeated procedural sequence this role's
  methodology implies (write characterization test → make each named
  refactoring step → re-run tests after each step → write the
  equivalence note).

## What's thin / unknown / contested (steers the scout sweep)

- **Thin**: no local precedent in *this* repo for a working gate script —
  everything gate-shaped here is either core-referenced (generic) or
  dangling (never written).
- **Known-hard, not yet attempted**: whether "characterization test
  predates the first structural edit" can be checked mechanically at
  PreToolUse time (a single point-in-time hook invocation) versus only at
  commit time via git history — issue-1 named this open and never
  resolved it; issue #10 explicitly asks for state tracking "if there is
  an ordering constraint," which there is.
- **To confirm via scouting**: what shape do sibling rulebooks that
  already built this (pricing, implementation) use for (a) the gate
  script itself, (b) the test harness, (c) any ordering/state-tracking
  mechanism for a similar before/after or sequence constraint, so this
  proposal adopts a proven pattern rather than inventing one from
  scratch.

## Sources

- `refactoring-legacy/hooks/directive.sh`, `hooks.json`,
  `.claude-plugin/plugin.json`, `README.md` (read directly, this repo).
- `docs/issue-1/proposals/proposal.md`,
  `docs/issue-1/reports/refactoring-legacy.md` (read directly, this repo).
- `pricing-rulebook/pricing/hooks/methodology-gate.sh`,
  `pricing-rulebook/pricing/hooks/hooks.json` (local sibling checkout,
  read directly).
- `implementation-rulebook/coding/hooks/` test harness listing and
  `tests/run-gate-tests.sh` (local sibling checkout, read directly).
