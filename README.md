# refactoring-legacy-rulebook

Rulebook for the `refactoring-legacy` role (contract v3 role-handoff protocol), split off
per `docs/issue-160/proposals/role-taxonomy.md`'s round-4 promotion and
generated as skeleton scaffolding by issue-167.

- **decides**: 기존 코드의 관찰 가능한 동작을 바꾸지 않고 안전하게 재구조화할 수 있는가
- **use_when**: 레거시/기존 코드에 손을 대야 할 때
- **produces**: characterization tests (written before any structural change),
  refactoring plan (small named steps), before/after behavior-equivalence note
  (evidence-citing) — see `## Doctrine` below for the full norm (issue #1)
- **write_scope**: ['src/**', 'test/**']
- **hand-off**: 신규 기능 구현이 섞이면 그 부분은 → implementation

## Doctrine (issue #1)

Adopted per `docs/issue-1/proposals/proposal.md` (Approved; see
`docs/issue-1/reports/refactoring-legacy.md` for the phase-2 record).

**Phase-1 proposal norm** — every proposal under this role must: reference a
current-state survey and a scout-brief (with a `Sources:` list); name its
adopted methodology and cite its origin rather than paraphrase it; show
options-considered vs. option-chosen in an ADR/RFC-shaped
context→options→decision→consequences form; state an explicit out-of-scope
section; and state phase-2 verification criteria.

**Phase-2 deliverable norm** — every deliverable this role produces must
contain: (1) a characterization test capturing the code's actual observed
behavior, written *before* any structural change (Feathers,
*Working Effectively with Legacy Code*); (2) a refactoring plan as a
sequence of small, independently-completable named refactorings, not one
monolithic rewrite step (Fowler, *Refactoring*); (3) a before/after
behavior-equivalence note that names which characterization tests were run
and confirms they pass identically before and after; (4) an explicit scope
boundary stating no behavior/feature change is bundled in — anything that
would change observable behavior is handed off to `implementation` instead.

**Mechanical enforcement (issue #10)**: the norms above are no longer
review-only. Three independent plugins, one per adopted methodology (cut by
methodology, not by phase, per `docs/issue-10/proposals/methodology-enforcement.md`),
each self-contained (own `plugin.json`, `hooks/methodology-gate.sh`,
`hooks/hooks.json`, `hooks/tests/run-gate-tests.sh`, own kill switch),
registered in `.claude-plugin/marketplace.json`:

- **`proposal-norm`** — gates every `docs/issue-<n>/proposals/*.md` write
  (`PreToolUse`/`Write|Edit|MultiEdit`, fail-closed) for the six required
  phase-1 elements listed above. Kill switch: `PROPOSAL_NORM_GATE_OFF=1`.
- **`characterization-tests`** — gates the phase-2 record
  (`docs/issue-<n>/reports/refactoring-legacy.md`) for characterization-test
  evidence and a named seam (Feathers), and requires a non-empty
  `characterization_tests_path` field — the record itself is the durable
  state marker `refactoring-steps` reads. Kill switch:
  `CHARACTERIZATION_TESTS_GATE_OFF=1`.
- **`refactoring-steps`** — gates the same record for named Fowler-catalog
  steps and a before/after equivalence note (plus a stable-seam requirement
  when a strangler-fig migration is named), and separately denies any
  `src/**` structural write unless `characterization_tests_path` is already
  set — the mechanism enforcing "characterize before refactor". Kill
  switch: `REFACTORING_STEPS_GATE_OFF=1`.

Each plugin is independently loadable/disable-able and owns exactly one
methodology; `refactoring-steps` reading `characterization-tests`'s record
field is a data dependency only, not shared code. Residual limitation
(unchanged from the proposal): this is a presence/ordering check against
durable on-disk state, not a cryptographically or git-history-verified
test-first guarantee. A role-specific `refactoring-legacy-progress-gate.sh`
entry in `hooks.json` remains dangling (pre-existing gap, unrelated to this
enforcement — see Open findings in `docs/issue-10/reports/refactoring-legacy.md`).

## Install

This rulebook now references core canon (issue #2) instead of vendoring its
own copies of the warrant-hunt agent and the three role-agnostic gates.
Install `core` and `warrant` (plus `terse`, `freelunch`, `scout`) from the
`tokenmaxxxer-core` marketplace alongside this rulebook's own plugin:

```
claude plugin marketplace add tokenmaxxxer/refactoring-legacy-rulebook
claude plugin install refactoring-legacy
claude plugin install proposal-norm
claude plugin install characterization-tests
claude plugin install refactoring-steps

claude plugin marketplace add tokenmaxxxer/core
claude plugin install core
claude plugin install terse
claude plugin install freelunch
claude plugin install scout
claude plugin install warrant
```

## Layout

- `proposal-norm/`, `characterization-tests/`, `refactoring-steps/` — the
  three methodology-enforcement plugins (issue #10); see `## Doctrine`
  above for what each gates and their kill switches
- `refactoring-legacy/.claude-plugin/plugin.json` — plugin manifest
- `refactoring-legacy/hooks/hooks.json` — SessionStart + PreToolUse wiring
  (only this role's own dangling `refactoring-legacy-progress-gate.sh` entry
  remains; the three role-agnostic gates now fire from core's own
  `core/hooks/hooks.json` for every plugin install)
- `refactoring-legacy/hooks/directive.sh` — SessionStart role directive, now a
  stub that sources core's `hooks/lib/role-directive.sh` and supplies only
  this role's four unique values
- `stub-check.sh` — no longer vendored here (issue #5, core canon #69). Run
  by reference against the core-installed copy instead:
  `"${CORE_PLUGIN_ROOT:-$CLAUDE_PLUGIN_ROOT/../core}"/hooks/tests/stub-check.sh refactoring-legacy`
- `docs/specs/approvers.md` — Approve-authority allowlist (see below)

The warrant-hunt agent (`agents/warrant-hunter.md`) and the three gates
(`trailer-gate.sh`, `record-fields-gate.sh`, `handbook-trigger-gate.sh`) are
no longer vendored here — see core canon (`core/agents` via the `warrant`
plugin, `core/hooks/*-gate.sh`) instead.

Doctrine detail is now filled in (`## Doctrine` above, issue #1); handoff
enforcement and a role-specific progress gate remain open — see the
enforcement gap noted above before treating those as load-bearing.
