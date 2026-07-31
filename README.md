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

**Enforcement gap, stated plainly**: `core`'s `record-fields-gate.sh` checks
only the generic contract §20 fields (what-was-done / why / upstream-basis /
loop_state / open-findings) plus a configurable terminal-states list — core's
contract table (section 2) hardcodes required fields per role for its own
nine canonical roles only, with no mechanism for a rulebook outside that
table (this one included) to register custom required fields. The four
deliverable components above are therefore enforced by this doctrine
document and by review, not by an automated gate; a role-specific progress
gate remains the dangling `refactoring-legacy-progress-gate.sh` entry in
`hooks.json` (pre-existing gap, unimplemented) and would be the natural home
for a future mechanical presence check if one is built.

## Install

This rulebook now references core canon (issue #2) instead of vendoring its
own copies of the warrant-hunt agent and the three role-agnostic gates.
Install `core` and `warrant` (plus `terse`, `freelunch`, `scout`) from the
`tokenmaxxxer-core` marketplace alongside this rulebook's own plugin:

```
claude plugin marketplace add tokenmaxxxer/refactoring-legacy-rulebook
claude plugin install refactoring-legacy

claude plugin marketplace add tokenmaxxxer/core
claude plugin install core
claude plugin install terse
claude plugin install freelunch
claude plugin install scout
claude plugin install warrant
```

## Layout

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
