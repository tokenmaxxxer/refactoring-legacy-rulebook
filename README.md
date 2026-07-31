# refactoring-legacy-rulebook

Rulebook for the `refactoring-legacy` role (contract v3 role-handoff protocol), split off
per `docs/issue-160/proposals/role-taxonomy.md`'s round-4 promotion and
generated as skeleton scaffolding by issue-167.

- **decides**: 기존 코드의 관찰 가능한 동작을 바꾸지 않고 안전하게 재구조화할 수 있는가
- **use_when**: 레거시/기존 코드에 손을 대야 할 때
- **produces**: refactoring plan, characterization tests, before/after behavior-equivalence note
- **write_scope**: ['src/**', 'test/**']
- **hand-off**: 신규 기능 구현이 섞이면 그 부분은 → implementation

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

This is scaffolding, not a finished rulebook: fill in doctrine detail,
handoff enforcement, and any role-specific progress gate before treating
it as load-bearing.
