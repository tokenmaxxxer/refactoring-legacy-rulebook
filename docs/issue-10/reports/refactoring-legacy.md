# Phase-2 record — issue #10 (refactoring-legacy)

loop_state: landed

## What was done

Implemented the Approved proposal
(`docs/issue-10/proposals/methodology-enforcement.md`, `APPROVE
issue-10/refactoring-legacy`, single-account mode) as three independent,
self-contained plugins, cut by methodology per the approver's two rounds of
`FEEDBACK`:

1. **`proposal-norm/`** — `.claude-plugin/plugin.json`,
   `hooks/methodology-gate.sh`, `hooks/hooks.json`
   (`PreToolUse`/`Write|Edit|MultiEdit`), `hooks/tests/run-gate-tests.sh`
   (9 cases). Fail-closed gate on `docs/issue-<n>/proposals/*.md` writes:
   denies unless all six phase-1 proposal-norm elements (survey ref,
   scout-brief ref w/ `Sources:`, named methodology citation, ADR-shaped
   considered-vs-chosen structure, out-of-scope, phase-2 verification
   criteria) are present in the effective (on-disk + new) text. Kill
   switch `PROPOSAL_NORM_GATE_OFF=1`.
2. **`characterization-tests/`** — same file set plus `CANON.md` (seam
   catalog: preprocessing/link/object seams, cited to Feathers).
   `hooks/tests/run-gate-tests.sh` (6 cases). Fail-closed gate on the
   phase-2 record (`docs/issue-<n>/reports/refactoring-legacy.md`): denies
   unless characterization-test evidence, a named seam, and a non-empty
   `characterization_tests_path:` field are present. The record itself is
   the durable state marker (no separate state file). Kill switch
   `CHARACTERIZATION_TESTS_GATE_OFF=1`.
3. **`refactoring-steps/`** — same file set plus `CANON.md` (Fowler catalog
   name index, strangler fig cited to `refactoring.com/catalog` and
   Fowler's writeup). `hooks/tests/run-gate-tests.sh` (9 cases). Fail-closed
   gate with two branches: (a) the phase-2 record — denies unless named
   catalog steps and a before/after equivalence note are present, plus (if
   `strangler` is named) a stable-seam description; (b) any `src/**`
   structural write — denies unless the record already carries a non-empty
   `characterization_tests_path` field, reading the issue number off the
   current git branch name (`issue-<n>/...`). This is the mechanism
   enforcing "characterize before refactor" across the two plugins via a
   data dependency on `characterization-tests`'s record field only (no
   shared code/mutable state). Kill switch `REFACTORING_STEPS_GATE_OFF=1`.

All three registered as entries in `.claude-plugin/marketplace.json`
alongside the existing `refactoring-legacy` entry. `refactoring-legacy/hooks/directive.sh`'s
`PRODUCES`/`HAND-OFF` facets deepened per the proposal's Appendix (ordered
four-step procedure, explicit hand-off trigger), now stating they are
mechanically enforced by the two record-scoped plugins. `README.md`'s
`## Doctrine` section rewritten: the prior "Enforcement gap" paragraph is
replaced by a "Mechanical enforcement (issue #10)" paragraph naming all
three plugins, their scopes, and kill switches, with the residual
test-first-ordering limitation (presence/ordering check against durable
on-disk state, not cryptographic/git-history-verified) stated plainly, per
the proposal's own stated limit. `## Install` and `## Layout` updated to
list the three new plugins.

No canon script was copied into this repo — the three gate scripts are
original, referencing the scouted `pricing-rulebook/pricing/hooks/
methodology-gate.sh` structural pattern (PreToolUse JSON on stdin, fail-closed,
kill switch, scope check) by name/behavior only, per `core/canon-scripts.md`'s
reference-only constraint.

## Why

The proposal specified exact per-plugin element lists and gate-test case
sets; those were implemented literally rather than reinterpreted. Two
implementation choices not fully pinned by the proposal, made during this
phase:

- **JSON parsing**: each `methodology-gate.sh` uses `python3` (assumed
  available, no `jq` dependency) rather than shell regex on raw JSON, since
  hook payloads can contain multi-line/escaped content that regex handles
  unreliably. Two build-time bugs surfaced and were fixed: piping JSON via
  stdin conflicted with a `python3 - <<EOF` heredoc claiming stdin for the
  script body itself (fixed by passing JSON through an env var or argv
  string instead, per plugin); and `git rev-parse --abbrev-ref HEAD` fails
  on an unborn HEAD in a fresh repo (fixed by trying `git symbolic-ref
  --short HEAD` first in `refactoring-steps`, matching how its own test
  harness exercises a fresh throwaway repo).
- **Effective-text approximation**: since `Edit`/`MultiEdit` tool inputs
  carry only the changed `new_string`(s), not the resulting whole file, each
  gate approximates the post-write state as (existing on-disk content, if
  any) concatenated with the new text, rather than simulating the exact
  string replacement. Stated as an approximation, not a guaranteed
  end-state read — sufficient for a presence/keyword check, the same class
  of simplification the proposal already accepted for scope checks.

This issue's own deliverable is enforcement tooling for the role, not a
`src/**` behavior-preserving code refactor — like issue #1's phase-2 record,
this record therefore does not itself carry a `characterization_tests_path`
field or cite characterization tests; the four-component deliverable norm
governs future `src/**` refactoring work done under this role, and would
now be mechanically checked by `characterization-tests`/`refactoring-steps`
the next time such work lands.

## Upstream basis

- `docs/issue-10/proposals/methodology-enforcement.md` (Approved via issue
  comment `APPROVE issue-10/refactoring-legacy`, single-account mode, per
  contract v3 s19; two prior `FEEDBACK` rounds on PR #11 drove the
  methodology-cut and canon-citation revisions this proposal reflects).
- `docs/issue-10/reports/refactoring-legacy/survey.md`,
  `docs/issue-10/reports/refactoring-legacy/scout-brief.md` (phase-1
  basis).
- `docs/issue-1/proposals/proposal.md`,
  `docs/issue-1/reports/refactoring-legacy.md` (adopted doctrine this
  phase mechanically enforces; the phase-2 record naming the enforcement
  gap this issue closes).

## Open findings

None raised against another role this phase.

- Pre-existing, still open (not created or worsened by this PR): the
  `refactoring-legacy-progress-gate.sh` entry in
  `refactoring-legacy/hooks/hooks.json`'s `PreToolUse`/`Bash` hook remains
  dangling — unrelated to the three new record/proposal-write gates added
  this phase, which are wired into their own plugins' `hooks.json` instead.

loop_state is `landed`; no next-steps backlog required.
