# Issue #10 — Phase 1 proposal (revised per approver feedback): a plugin set enforcing the issue-1 methodology norms

Status: proposal only — not executed, not approved. **Phase 1 ONLY per the
invoking prompt: this PR stops at the proposal; no `Approve` is solicited
or assumed, and no code below is implemented in this PR.**

**Revision note (round 2)**: this supersedes the round-1 plugin-set design
after a second approver `FEEDBACK` comment on PR #11 (domain review,
WEAK verdict) required two further corrections:

1. The plugin cut was still phase-shaped (`proposal-norm` /
   `deliverable-norm` mirror phase 1 / phase 2), not methodology-shaped.
   The feedback names the fix explicitly: split the phase-2 plugin into
   **`characterization-tests`** and **`refactoring-steps`** as two
   independent plugins, one per adopted methodology, matching one plugin
   = one methodology, not one plugin = one phase.
2. The design lacked refactoring-legacy-specific canon and did not name
   its source catalog. This revision adds a **strangler fig** / **seam**
   canon section and cites Fowler's refactoring catalog by name
   throughout, rather than gesturing at "Fowler" generically.

Round 1's underlying premise — one independent plugin per adopted
methodology (mirroring core's `freelunch`/`scout` split), phase norms
expressed as *combinations* of those plugins, plugin list as the
proposal's required core (name, owning methodology, components,
combination relationship) — stands and is unchanged by this round; only
the cut of the phase-2 plugin and the canon content change.

## Context

Issue-1 (Approved, `docs/issue-1/proposals/proposal.md`) established this
role's methodology doctrine — a phase-1 proposal norm (six required
elements) and a phase-2 deliverable norm (four required components) — and
reflected it into `directive.sh`'s `PRODUCES` string and `README.md`'s
`## Doctrine` section. It named an "Enforcement gap": nothing mechanically
checks that a proposal or record actually contains the required elements.
Issue #10 asks this repo to close that gap. The current-state survey is at
`docs/issue-10/reports/refactoring-legacy/survey.md`; the scout sweep is at
`docs/issue-10/reports/refactoring-legacy/scout-brief.md` (both unchanged
by this revision — the gap and the scouted `pricing-rulebook/pricing/
hooks/methodology-gate.sh` structural reference still apply; only the
shape of the design built on top of them changes).

Reference architecture for "plugin", taken from
`tokenmaxxxer-core/.claude-plugin/marketplace.json` and
`tokenmaxxxer-core/freelunch/`: a plugin is a self-contained directory
(`<plugin>/.claude-plugin/plugin.json` naming it, plus any of `hooks/`,
`agents/`, `workflows/`, `README.md` it needs), registered as one entry in
this repo's own `.claude-plugin/marketplace.json` alongside the existing
`refactoring-legacy` entry.

## Plugin list (the design's core)

Three adopted methodologies map to three independent plugins — cut by
**methodology**, not by phase. Issue-1's phase-2 deliverable norm bundled
two distinct methodologies (Feathers' characterization testing, Fowler's
catalog-driven refactoring); this revision un-bundles them into their own
plugins per the approver's explicit instruction.

| Plugin | Owning methodology | Components | Registered as |
|---|---|---|---|
| `proposal-norm` | Issue-1's phase-1 proposal norm (six required elements: survey ref, scout-brief ref w/ Sources, named methodology citation, considered-vs-chosen structure, Out-of-scope, phase-2 verification criteria) | `hooks/methodology-gate.sh` (scope: `docs/issue-<n>/proposals/**`, fail-closed, kill switch `PROPOSAL_NORM_GATE_OFF=1`); `hooks/hooks.json` (`PreToolUse`/`Write\|Edit\|MultiEdit`); `hooks/tests/run-gate-tests.sh` | new marketplace.json entry `proposal-norm`, `source: ./proposal-norm` |
| `characterization-tests` | Feathers' characterization testing (*Working Effectively with Legacy Code*): pin current behavior with tests, opened via a **seam**, before any structural edit | `hooks/methodology-gate.sh` (scope: `docs/issue-<n>/reports/refactoring-legacy.md`, fail-closed, kill switch `CHARACTERIZATION_TESTS_GATE_OFF=1`) denying the record write unless it names (a) the characterization-test evidence and (b) the seam used to introduce it; the accepted write sets a durable `characterization_tests_path` field on the record — the record itself is the state marker, no separate state file, per the scouted `coding-progress-gate.sh` durable-state precedent; `hooks/hooks.json`; `hooks/tests/run-gate-tests.sh`; `CANON.md` (seam catalog: preprocessing/link/object seams, when each applies to this repo's languages) | new marketplace.json entry `characterization-tests`, `source: ./characterization-tests` |
| `refactoring-steps` | Fowler's refactoring catalog (*Refactoring: Improving the Design of Existing Code*, catalog at refactoring.com/catalog): decompose into small, named, independently-safe steps; for structural migrations too large for one catalog refactoring, the **strangler fig** pattern (incrementally route behavior to a new structure behind a stable seam, retiring the old path last) | `hooks/methodology-gate.sh` (scope: same record file, fail-closed, kill switch `REFACTORING_STEPS_GATE_OFF=1`) denying (a) the record write unless it names the refactoring steps by their catalog name and a before/after equivalence note, and (b) any `src/**` structural `Write\|Edit\|MultiEdit` unless the record already carries a non-empty `characterization_tests_path` field (the ordering dependency on `characterization-tests`'s state marker — this is the mechanism enforcing "characterize before refactor"); `hooks/hooks.json`; `hooks/tests/run-gate-tests.sh`; `CANON.md` (Fowler catalog name index used in this repo, plus strangler fig as the named large-scope escape hatch, cited to `refactoring.com/catalog` and Fowler's strangler-fig writeup) | new marketplace.json entry `refactoring-steps`, `source: ./refactoring-steps` |

Each plugin is independently loadable/disable-able (its own kill switch,
its own `hooks.json`, its own test suite) and owns exactly one
methodology — no plugin checks more than one methodology's shape. This
mirrors `freelunch` and `scout` being separate plugins in core even though
both fire in the same session lifecycle. `refactoring-steps` reading
`characterization-tests`'s durable record field is a data dependency, not
shared code or shared mutable state — the two remain independently
loadable (disabling `refactoring-steps` alone still leaves
`characterization-tests` enforcing its own methodology).

### Combination relationship

The phase-1/phase-2 norms are not new artifacts to design — they **are**
the plugin combinations already implied by contract v3 plus issue-1:

- **Phase-1 proposal norm** = `proposal-norm` plugin alone, composed with
  the already-existing core `scout` plugin (whose brief the gate checks
  for) — the gate is downstream verification of what `scout` and the
  session's own survey step produce; `proposal-norm` does not duplicate
  scout's logic, it checks scout's *output artifact* is referenced.
- **Phase-2 deliverable norm** = `characterization-tests` **and**
  `refactoring-steps` composed together, in that order — the ordering
  constraint issue-1 names ("조사→근거→채택", here: characterize before
  refactor) is enforced across the two plugins by the durable
  `characterization_tests_path` record field, not by a single combined
  gate. Composed with core's existing `warrant` plugin's landing-time
  hunt (out of scope to change) — the rest of phase-2's shape (branch,
  PR, Approve gating) stays owned by core's `core` plugin, untouched.
- All three new plugins share nothing but the `write_scope` convention
  already established by `core`'s per-role contract table, plus the one
  explicit data dependency named above (`refactoring-steps` reads
  `characterization-tests`'s record field) — no shared mutable state
  beyond that single documented read, so the plugins stay independently
  loadable/testable, matching the "no shared-line coupling → separate
  units" default this session itself works under.

## Directive deepening (unchanged content, now plugin-scoped)

`directive.sh`'s four facets deepen exactly as previously designed — see
Appendix — but the deepened `PRODUCES` text is understood as documentation
of what `proposal-norm`/`deliverable-norm` *mechanically* check, not a
separate freestanding norm. Rendering mechanics (whether
`core_role_directive`'s call shape accepts a longer value) remain deferred
to phase 2 per `core/hooks/lib/role-directive.sh`'s actual signature, not
guessed here.

## Gate tests

Each plugin carries its own `hooks/tests/run-gate-tests.sh`, exercising
its own `methodology-gate.sh` as a real subprocess (throwaway `git init`
repo, synthetic `PreToolUse` JSON on stdin, assert exit 0/2), scoped only
to its own methodology:

`proposal-norm` cases: all six elements present → allow; each of the six
missing individually → deny (one case per element); write to an unrelated
path → allow (no-op scope check).

`characterization-tests` cases: characterization-test evidence + named
seam both present → allow, and sets `characterization_tests_path`; either
missing → deny; write to an unrelated path → allow.

`refactoring-steps` cases: named catalog steps + before/after equivalence
note both present → allow; either missing → deny; a `src/**` structural
edit attempted while `characterization_tests_path` is empty/missing →
deny; the same edit after that field is present → allow; a strangler-fig
migration record (large-scope escape hatch) missing the stable-seam
description → deny; write to an unrelated path → allow.

## Out of scope

- Implementing any plugin's `methodology-gate.sh`, `hooks.json`,
  `run-gate-tests.sh`, `CANON.md`, or `.claude-plugin/plugin.json`, or
  the `marketplace.json` edits registering them — all deferred to phase 2
  pending Approve.
- Resolving the long-dangling `refactoring-legacy-progress-gate.sh`
  `hooks.json` entry — a phase-2 investigation, not repeated here.
- A cryptographically/git-history-verified test-first ordering guarantee —
  explicitly not attempted; `refactoring-steps`'s ordering check against
  `characterization-tests`'s record field is a presence/ordering check
  against durable on-disk state only, stated as a residual limitation,
  matching the prior design's stated limit.
- Any change to `core`'s `record-fields-gate.sh`, `role-directive.sh`, its
  per-role contract table, `freelunch`, `scout`, or `warrant` themselves —
  this proposal adds two new *role-scoped* plugins that reference core's
  existing plugins by name/behavior, never modifying or vendoring them.
- `docs/specs/approvers.md` — untouched.
- Re-litigating issue-1's adopted doctrine content — this proposal is
  mechanical enforcement of what issue-1 already decided.

## Phase-2 verification criteria

Once Approved, phase 2 should be verifiable by: (1) all three of
`proposal-norm/.claude-plugin/plugin.json`,
`characterization-tests/.claude-plugin/plugin.json`, and
`refactoring-steps/.claude-plugin/plugin.json` exist, and all three are
registered as entries in this repo's `.claude-plugin/marketplace.json`
alongside the existing `refactoring-legacy` entry; (2) each plugin's own
`hooks/tests/run-gate-tests.sh` exits 0 (all cases pass) when run
directly; (3) a proposal or record write missing a required element,
attempted live in a session, is observably denied by the owning plugin's
gate, including the `refactoring-steps` ordering deny (structural edit
before `characterization_tests_path` is set); (4) `README.md`'s
`## Doctrine` section is updated to name all three plugins as what now
mechanically enforces the norms, replacing the "Enforcement gap"
paragraph, with the residual test-first-ordering limitation stated
plainly.

## Appendix: directive deepening detail (carried over from the prior design)

- **`YOU DECIDE`**: state the test explicitly — *if the change could be
  described without the word "still," it is not a refactor.*
- **`PRODUCES`**: an ordered procedure — (1) capture behavior first
  (characterization test, Feathers) before touching structure; (2)
  decompose into small named steps (Fowler), each independently
  completable and leaving the system working; (3) run captured tests
  after every step, not only at the end; (4) write the equivalence note
  citing which tests ran and passed identically pre/post. Prohibition: no
  step may bundle an observable-behavior change; any such change
  discovered mid-work is handed off, not folded in.
- **`HAND-OFF`**: the judgment criterion for *when* — the moment a step
  under consideration would make a previously-passing characterization
  test fail *by design* (feature change misfiled as refactoring) rather
  than *by accident* (regression to fix within the same step).
- **`USE_WHEN`**: unchanged, already sufficiently concrete.

## References

- `docs/issue-10/reports/refactoring-legacy/survey.md`
- `docs/issue-10/reports/refactoring-legacy/scout-brief.md`
- `docs/issue-1/proposals/proposal.md` (adopted doctrine this proposal
  enforces)
- `docs/issue-1/reports/refactoring-legacy.md` (phase-2 record naming the
  enforcement gap this proposal closes)
- `tokenmaxxxer-core/.claude-plugin/marketplace.json`,
  `tokenmaxxxer-core/freelunch/` (reference architecture for the
  plugin-set shape this revision adopts, per the approver's explicit
  freelunch/scout comparison — referenced for structure only, not copied)
