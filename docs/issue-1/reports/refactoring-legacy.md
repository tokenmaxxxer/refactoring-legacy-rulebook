# Phase-2 record — issue #1 (refactoring-legacy)

loop_state: landed

## What was done

Reflected the Approved proposal (`docs/issue-1/proposals/proposal.md`) into
the plugin:

1. `refactoring-legacy/hooks/directive.sh` — `PRODUCES` rewritten to name
   the three required deliverable components by name (characterization
   tests written first, refactoring plan as small named steps,
   evidence-citing before/after equivalence note), replacing the prior
   unstructured three-noun list.
2. `README.md` — added a `## Doctrine` section documenting the proposal
   norm (a) and deliverable norm (b) adopted in the proposal, updated the
   `produces` line to match the directive, and replaced the "scaffolding,
   doctrine not filled in" caveat with an accurate statement of what is now
   filled in vs. still open.
3. `README.md` — added an explicit "Enforcement gap" note (see Why, below)
   in place of implementing the record-fields.json / gate design from the
   proposal's plan (d).

## Why

The proposal's plan (d) proposed a `record-fields.json`-equivalent listing
three role-specific required record fields
(`characterization_tests_path`/`refactoring_steps`/
`behavior_equivalence_note`) enforced by a phase-2 gate, contingent on
checking `core/hooks/lib/role-directive.sh` and `core`'s record-fields gate
first (the proposal flagged this as unresolved). That check was done this
phase: cloned `tokenmaxxxer/tokenmaxxxer-core` read-only and read
`core/hooks/record-fields-gate.sh` and
`core/contract/role-handoff-contract.md` section 2 directly. Finding: core's
gate enforces only the generic contract §20 fields (what-was-done/why/
upstream-basis/loop_state/open-findings) plus a configurable
`RECORD_FIELDS_TERMINAL_STATES` list; role-specific required fields are
hardcoded in the contract's own section-2 table for its nine canonical
roles only (`product`, `coding`, `qa`, `feasibility`, `ux-design`, `review`,
`verify`, `ops`, `reflect`) — `refactoring-legacy` is not one of them, and
there is no mechanism for a rulebook outside that table to register custom
required fields into core's gate.

Given that, two options were considered:
- **Vendor a new bespoke `record-fields-gate.sh`/`record-fields.json` pair
  local to this rulebook**, checking the three fields directly. Rejected:
  this reintroduces exactly the local-gate-vendoring pattern issue #2/#5
  spent two PRs removing in favor of core-canon reference, for a check
  narrower than what core's canon gate already gives every role for free
  (the generic §20 fields, which do cover "what was done"/upstream basis
  and already force some evidence trail). Building bespoke enforcement
  infra beyond what was asked, for a role this rulebook doesn't own
  (core's contract table), is scope beyond this issue.
- **Document the three-field requirement as doctrine, state the
  enforcement gap plainly, leave the mechanical check to review and to the
  existing (dangling, pre-existing) `refactoring-legacy-progress-gate.sh`
  hook slot as a named future home.** Chosen: this is exactly the
  proposal's own stated fallback — "if not mechanically feasible, phase 2
  should fall back to a presence-only check and note the gap explicitly
  rather than silently skip it" — applied one level up, since even a
  presence-only *gate* isn't supported by core's per-role mechanism as it
  exists today, only doctrine + review is.

## Upstream basis

- `docs/issue-1/proposals/proposal.md` (Approved via issue comment
  `APPROVE issue-1/refactoring-legacy`, single-account mode, per contract
  v3 s19).
- `docs/issue-1/reports/refactoring-legacy/survey.md`,
  `docs/issue-1/reports/refactoring-legacy/scout-brief.md` (phase-1 basis
  for the proposal).
- `tokenmaxxxer/tokenmaxxxer-core` (read-only clone, this phase):
  `core/hooks/record-fields-gate.sh`, `core/hooks/lib/role-directive.sh`,
  `core/contract/role-handoff-contract.md` (sections 2 and 20).

## Open findings

None raised against another role this phase.

- Pre-existing, still open (not created or worsened by this PR): the
  `refactoring-legacy-progress-gate.sh` entry registered in `hooks.json`'s
  `PreToolUse`/`Bash` hook has never had a corresponding file in this repo
  (flagged independently in issue-2's and issue-5's surveys). This phase
  names it as the natural future home for a mechanical presence-check on
  the three deliverable-norm fields, per the "Enforcement gap" note in
  `README.md`, but does not implement it — no proposal in this issue's PR
  scoped writing a new gate script, and doing so unprompted would be scope
  creep beyond what issue #1 and its Approved proposal asked for.

loop_state is `landed`; no next-steps backlog required.
