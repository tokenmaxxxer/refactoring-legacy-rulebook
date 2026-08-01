# Proposal: gate A+ final closure — re-audit residual defects (issue-16)

Basis: `docs/issue-16/reports/refactoring-legacy/survey.md` (current-state
defect map) and `docs/issue-16/reports/refactoring-legacy/scout-brief.md`
(core issue #75's landed source-guard/compliance-check/missing-core/
gate_bash_write_targets shape, on-the-record issue #182's landed
`CLAUDE_PLUGIN_ROOT_CORE` injection shape, `Sources:` listed there).
Adopted methodology citations: this proposal is itself governed by the
`refactoring-legacy` role's own doctrine (`README.md`'s `## Doctrine`) —
characterization-tests-first, small named steps, no bundled behavior
change; core's `docs/handbooks/gate-house-standard.md` (issue-72/issue-75,
landed) for the shared gate-implementation shape this issue's precondition
mandates reference-adopting rather than re-deriving.

## Context

A 2026-08-01 re-audit of this rulebook's gate A+ closure (issue-13's
delivered state) found four residual defects, gated on two preconditions
this proposal confirms landed (scout-brief, "Precondition check"):
`tokenmaxxxer-core` issue #75 (gate-lib source guard, mandatory;
compliance-check detection; missing-core mandatory test;
`gate_bash_write_targets` ported to `gate-lib.py`) merged to `main` at
commit `52bdc15` (PR #77); `on-the-record` issue #182 (inject
`CLAUDE_PLUGIN_ROOT_CORE` in `spawn.py`) merged to `main` via PR #185.
Both preconditions are satisfied — no blocker on that axis.

The four defects, per the issue text and located in `survey.md`:

1. **Source guard + PASS self-attestation limitation.** All three
   methodology-enforcement gates (`proposal-norm`, `characterization-tests`,
   `refactoring-steps`) source `gate-lib.sh` with no `||` guard (survey
   §1) — the exact shape core issue-75's `compliance-check.sh` now flags.
   This repo's only recorded compliance-check-clean claim
   (`docs/issue-13/reports/refactoring-legacy.md`) predates that check and
   is now stale, an instance of the same "self-reported PASS the gate
   cannot execute-verify" limitation the doctrine already names for
   `test_run:` fields — now also true of this repo's claim about itself.
2. **`hooks.json` matcher vs. code tool-coverage.** The three
   methodology-enforcement plugins are fully aligned (survey §2, no
   action needed). `refactoring-legacy/hooks/hooks.json`'s `Bash` matcher
   points at `refactoring-legacy-progress-gate.sh`, which has zero
   backing implementation (does not exist) — a ghost-file mismatch, not a
   code-coverage gap.
3. **Missing-core test case + full suite green + compliance-check pass
   recorded.** None of the four `run-gate-tests.sh` suites has a
   missing-core case (survey §5); no current-dated compliance-check run
   is recorded anywhere in this repo.
4. **README/manifest ghost-file and old-role-name cleanup.** The
   dangling `refactoring-legacy-progress-gate.sh` reference (survey §3)
   is documented but not enforced against. No old-role-name strings exist
   in this repo (survey §4, confirmed via full git history) — this half
   of the requirement is a documented finding of absence, not a
   remediation target.

## Options considered

**Option A — patch each gate's source line in place, ad hoc, with a
locally-invented guard idiom.** Rejected: this is exactly the
"re-derive a local version of a shape core already owns" anti-pattern
this repo's own issue-13 proposal already rejected as its Option A, and
issue #16's Common preconditions section is explicit that the fix should
"reference-apply core #75's finalized guard/rule" — not a new local
invention.

**Option B — reference-adopt core #75's exact guard shape verbatim into
the three existing source lines; convert the dangling `hooks.json` entry
into an enforced hard-error instead of a silent no-op; add a missing-core
case to each suite; record a fresh, current-dated compliance-check run;
state explicitly that no old-role-name remediation is needed (with
evidence).** Chosen. Mirrors the precedent this repo's own issue-13
already set (reference-adopt core's shape, do not re-derive) and stays
inside the doctrine's characterization-tests-first, small-named-steps,
no-bundled-behavior-change constraint: each defect gets its own
characterization-test-first sequence below.

**Option C — replace the dangling `Bash`-matcher entry by deleting it
from `hooks.json` instead of building the gate it was always meant to
back.** Rejected for this proposal's scope: issue #16 requirement 4 asks
for ghost files to "become hard errors," which reads as making the gap
detectable/failing rather than silently removing the aspiration it
represents; issue-13's own Out-of-scope section explicitly deferred
*creating* the progress gate as separate, future work — this proposal
does not reopen that scope decision, it only makes the existing gap
loud instead of silent. (If phase-2 execution finds the "make it a hard
error" framing infeasible without also building the gate, that tradeoff
is phase-2's to surface — this proposal names the intended shape, not a
guaranteed final form; see Verification criteria.)

## Decision

Adopt Option B. Concretely, per defect — each written as a
characterization-test-first refactoring sequence per the role's own
doctrine (seam first, then small named steps, then equivalence check):

### 1. Source guard + PASS self-attestation limitation (reference-adopt core #75)

**Seam/test that captures current behavior.** A new "missing-core" case
in each of the three `hooks/tests/run-gate-tests.sh` suites: run the gate
as a subprocess with `CLAUDE_PLUGIN_ROOT_CORE` pointed at a nonexistent
path (and no sibling `../../core` fallback present in the fixture tmpdir,
so the fallback also fails to resolve) — this seam captures the *current*
behavior first (today: an unguarded source fails silently, the script
continues, and downstream `gate_kill_switch_active` calls read as
"undefined command" — expected current-state exit code is whatever bash's
own "command not found" propagates to, almost certainly not a clean `2`).
Recording this actual current exit code, before any code change, is the
characterization test's job.

**Small named steps** (Fowler's catalog — each independently completable,
system left working after each):

- Step 1 — **Extract guard clause**: add core #75's exact `||` guard to
  each of the three source lines
  (`proposal-norm/hooks/methodology-gate.sh:11`,
  `characterization-tests/hooks/methodology-gate.sh:9`,
  `refactoring-steps/hooks/methodology-gate.sh:11`), reusing core's own
  deny-message shape (`"<gate-name>.sh: cannot source gate-lib.sh"`,
  substituting each gate's own name), matching the guarded exemplar at
  `core/hooks/approval-gate.sh:38` verbatim in structure. No other line
  in any of the three files changes.
- Step 2 — **Re-run the missing-core characterization test** from the
  seam above against the now-guarded gate: expected new exit code is `2`
  (fail-closed), with the deny message on stderr naming the gate that
  could not source `gate-lib.sh`.
- Step 3 — **Record a fresh compliance-check run**: invoke
  `core/hooks/tests/compliance-check.sh` (current, post-#75, `main`)
  against each of the three plugins' `hooks/` directories; record the
  actual `ok`/`FAIL` lines and the invoked commit SHA of core's `main` at
  run time, superseding (not silently overwriting — cite it explicitly as
  superseding) the stale record in
  `docs/issue-13/reports/refactoring-legacy.md`.
- Step 4 — **Name the residual limitation explicitly, not silently**:
  the phase-2 report must state that a compliance-check-clean record is a
  point-in-time claim against a specific core commit, not a
  standing guarantee — recommend (as a phase-2 report item, not new gate
  logic) that future re-audits re-run compliance-check against current
  core `main` rather than trusting an old record, closing the exact gap
  this issue's defect 1 named. (Whether that recommendation becomes a CI
  step, a doctrine sentence, or stays a report note is phase-2's call —
  this proposal does not design new gate-runtime logic for it, matching
  the doctrine's characterization-tests-first, no-bundled-feature-work
  constraint.)

**Equivalence verification.** Before: three gates fail-open on missing
core (undefined exit code, effectively allows). After: three gates
fail-closed (`exit 2`) on missing core, and every currently-passing case
in each of the three `run-gate-tests.sh` suites (proposal-norm 19/19,
characterization-tests 18/18, refactoring-steps 22/22 per issue-13's
record) must still pass unchanged, since the guard only adds a fallback
path for the *already-broken* case — it does not touch the
already-succeeding source path. Phase 2 re-runs all three suites and
confirms the same or greater pass counts, listing any fixture that had to
be reshaped (expected: none, since no existing fixture exercises a
missing-core condition).

`refactoring-legacy/hooks/directive.sh:4`'s unguarded source of
`role-directive.sh` is a related but distinct file (not `gate-lib.sh`,
outside `compliance-check.sh`'s specific pattern match) — out of scope
for *this* defect's compliance-check-clean claim, but sharing the
identical fail-open risk class; see Out of scope below for the explicit
scope call on whether to fix it in the same pass.

### 2. `hooks.json` matcher vs. code tool-coverage alignment

**Seam/test.** The three methodology-enforcement plugins already have no
gap (survey §2) — nothing to characterize or change there; re-confirming
this after defect 1's guard fix (a `run-gate-tests.sh` re-run, not new
test code) is the only step needed for that half.

For `refactoring-legacy/hooks/hooks.json`'s `Bash`-matcher-to-ghost-file
mismatch: the characterization seam is a new test asserting *today's*
actual behavior first — a `Bash` tool call in a fixture repo currently
proceeds unobstructed (no deny), because Claude Code treats a missing
hook-command file as a no-op. This is the "before" state to capture
before any fix step runs.

**Small named steps**, sequenced but each independently completable:

- Step 1 — decide (phase-2, per the Out-of-scope tradeoff named in Option
  C above) whether "hard error" means (a) building a minimal
  `refactoring-legacy-progress-gate.sh` that itself fails closed on
  invocation (satisfies "matcher has real backing code"), or (b) a
  repo-level check (e.g. extending `compliance-check.sh`-adjacent
  tooling, or a new manifest-integrity test) that fails the test suite
  loudly if any `hooks.json` `command` entry names a file absent from
  disk (satisfies "the gap itself becomes a hard error" without building
  the aspirational gate). This proposal names both candidate shapes and
  defers the choice to phase-2 design, since committing to one now would
  be designing the fix rather than proposing it.
- Step 2 — whichever shape is chosen, add the missing/ghost-command
  detection as its own small step, independently testable, before
  touching anything else in `hooks.json`.
- Step 3 — re-run the characterization seam from above; expected new
  behavior: a `Bash` call fails loudly (chosen shape (a)) or the test
  suite itself fails loudly on the ghost reference (chosen shape (b)) —
  either way, "silently passes forever" is closed.

**Equivalence verification.** No previously-passing case in any of the
four plugins' test suites should newly fail; the only new behavior is
that the ghost-file gap stops being silent. Phase 2 records which shape
((a) or (b)) was chosen and why, plus a before/after transcript of the
characterization seam's exit behavior.

### 3. Missing-core test case + full suite green + compliance-check pass recorded (execution plan only)

This is the same missing-core case designed in defect 1's Step 1/2 above,
generalized: each of the three `hooks/tests/run-gate-tests.sh` gains one
new case (not a rewrite of existing cases), following the exact
`run_case`/`run_raw` harness shape already in use (see e.g.
`characterization-tests/hooks/tests/run-gate-tests.sh` cases 12-14 for the
existing malformed-JSON-fixture pattern this new case should match in
style). Phase-2 plan, not implementation:

1. Add the missing-core case to all three suites (mirrors core's own
   `run-gate-lib-tests.sh` addition per scout-brief).
2. Run all three suites; require 0 failures, and report the new totals
   (baseline: 19/19, 18/18, 22/22 plus one new case each = 20, 19, 23).
3. Run `compliance-check.sh` against all three `hooks/` dirs against
   current core `main`; record the commit SHA and the `ok`/`FAIL` line
   per plugin.
4. Write the phase-2 record
   (`docs/issue-16/reports/refactoring-legacy.md`, gated on human Approve
   per contract v3 s19 — not created by this proposal) citing the actual
   suite totals and the actual compliance-check output, not a paraphrase.

### 4. README/manifest ghost-file and old-role-name cleanup

**Seam/test.** A new check (shape (a) or (b) from defect 2 Step 1) is the
same mechanism that turns the ghost file into a hard error; README's own
prose is the second surface. Characterize first: `README.md:92-94` and
`:127-129` already *state* the gap exists (this is accurate prose, not
drift) — the seam here is confirming, before any edit, that no other
sentence in README or any of the four `plugin.json` manifests references
a file/path/plugin absent from the delivered tree, the same spot-check
issue-13's survey §7 already performed and issue-13's phase-2 record
confirmed clean.

**Small named steps:**

- Step 1 — re-run the same spot-check issue-13's survey §7 performed
  (README + `docs/handbooks/gate-hooks.md` against the current delivered
  tree) to confirm no *new* drift was introduced since issue-13 landed.
  Expected result per this proposal's own survey §7 equivalent (survey.md
  §3-§4): no new drift found; the one known gap
  (`refactoring-legacy-progress-gate.sh`) is the same one already named.
- Step 2 — once defect 2's hard-error mechanism lands, update README's
  prose (the "dangling ... remains" sentences at `README.md:92-94,127-129,144-145`)
  to describe the new enforced-not-just-documented state, rather than
  leaving accurate-but-now-outdated "remains dangling, unenforced" prose
  standing next to a mechanism that now enforces it.
- Step 3 — explicitly record, in the phase-2 report, that no old-role-name
  string was found anywhere in this repo (survey §4) — stating the
  absence rather than silently doing nothing, so a future audit does not
  re-ask the same question without an answer on record.

**Equivalence verification.** Before/after: README's factual claims about
what exists on disk stay 100% accurate at both points (the spot-check
step gates this); the *enforcement* state of the one known gap changes
(documented-only → hard-error), which is the intended, named change for
this defect — not an unintended side effect.

## Consequences

- Positive: closes the compliance-check-clean claim's staleness gap by
  reference-adopting core #75's exact guard shape (no local re-derivation
  risk); converts a silently-passing ghost-file matcher into a loud
  failure; adds the one test-coverage class (missing-core) this repo's
  suites lacked relative to core's own; keeps every existing passing test
  case in all four suites unchanged in intent.
- Negative/residual: a compliance-check-clean record remains a
  point-in-time claim against a specific core commit — defect 1's Step 4
  names this honestly rather than overclaiming a standing guarantee; this
  mirrors the same residual limitation issue-13 already accepted for
  `test_run: PASS` records and does not attempt to close it further here
  (closing it would require executing arbitrary code inside a
  `PreToolUse` gate, which issue-13's own Decision §4 already rejected as
  out of scope for a gate).
- `refactoring-legacy/hooks/directive.sh:4`'s unguarded `role-directive.sh`
  source shares the fail-open risk class but is a different file outside
  this issue's named defect 1 scope (compliance-check.sh's `gate-lib\.sh"$`
  pattern does not match it) — see Out of scope.

## Out of scope

- Deciding, inside this document, which of defect 2's two candidate
  hard-error shapes ((a) build the gate, (b) a manifest-integrity check)
  is final — phase-2 design work, per the doctrine's
  characterization-tests-first, propose-then-execute split; this proposal
  names both candidates and the decision criterion, not the answer.
- Guarding `refactoring-legacy/hooks/directive.sh:4`'s
  `role-directive.sh` source line with the same `||` shape — shares the
  risk class with defect 1 but is not itself named by
  `compliance-check.sh`'s specific rule or by the issue text's four
  defects; flagging it here as a related finding for a future issue, not
  silently bundling a fifth fix into this one's four.
- Actually executing/re-verifying a `test_run:` command's truthfulness at
  gate-runtime (unchanged from issue-13's Decision §4 — still a
  `PreToolUse`-inappropriate operation).
- Re-architecting the plugin-per-methodology cut, or any change to what
  each of the three methodology gates' semantic checks require (unchanged
  from issue-13's Option C rejection and Out-of-scope section — this
  issue is a closure/remediation issue, not a redesign).
- Approving this proposal — phase 1 of this issue ends at PR submission;
  phase 2 (the actual guard edits, hard-error mechanism, test-suite
  additions, compliance-check run, and README edits) opens only on an
  `docs/specs/approvers.md`-listed account's Approve per contract v3 s19.

## Verification criteria (phase 2)

1. `core/hooks/tests/compliance-check.sh <plugin-dir>` (current, post-#75,
   core `main`) reports zero violations for all three
   methodology-enforcement plugins, with the run's core commit SHA
   recorded in the phase-2 report.
2. Each of the three methodology-enforcement plugins' own
   `run-gate-tests.sh` (extended with the new missing-core case) exits 0,
   with the new totals reported.
3. The missing-core characterization test (defect 1's seam) demonstrably
   flips from an unguarded, non-`2` exit code before the fix to a
   guarded, `exit 2` deny after — the before/after transcript is part of
   the phase-2 record, not just a claim.
4. Whichever hard-error shape defect 2/4 chooses, a fixture exercising
   the ghost-file/matcher-mismatch condition demonstrably fails loudly
   (not silently passes) post-fix.
5. `README.md` and the four `plugin.json` manifests contain no reference
   to a file, path, or plugin absent from the delivered tree — spot-check
   repeated the same way issue-13's survey §7 / phase-2 record §5 did —
   and no old-role-name string is introduced or left present (this
   proposal's survey §4 already confirms none exists today; phase-2 only
   needs to confirm none was introduced by its own edits).
