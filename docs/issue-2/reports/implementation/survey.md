# Current-state survey — issue-2

## This repo's write surfaces (the five items in the issue)

- `refactoring-legacy/agents/warrant-hunter.md` — full copy of the hunt-agent
  prompt (adapted text, not byte-identical), 23 lines. Item 1 target.
- `refactoring-legacy/hooks/trailer-gate.sh` — commit-trailer gate, role-agnostic
  logic, only the deny-message prefix (`refactoring-legacy:`) is role-specific. Item 2.
- `refactoring-legacy/hooks/record-fields-gate.sh` — record required-field gate.
  Pre-issue-66 shape: no `loop_state`/terminal-state concept at all, just a flat
  `REQUIRED_FIELDS` list (`refactoring-plan`, `characterization-tests`,
  `behavior-equivalence-note`) checked against file content. Item 2.
- `refactoring-legacy/hooks/handbook-trigger-gate.sh` — placeholder verdict
  (`exit 0 # placeholder verdict — TODO`), never implemented past skeleton. Item 2.
- `refactoring-legacy/hooks/directive.sh` — SessionStart directive, currently a
  standalone script carrying the full boilerplate (trap, kill-switch case,
  `CLAUDE_ROLE` guard) plus this role's four unique values inline. Item 3.
- `refactoring-legacy/hooks/hooks.json` — registers all four hooks above plus a
  `refactoring-legacy-progress-gate.sh` referenced but never present in the repo
  (dangling entry, pre-existing before this issue, out of the issue's 5 items).

## Core canon (tokenmaxxxer-core, cloned read-only for this survey)

- `core/hooks/{trailer-gate.sh,record-fields-gate.sh,handbook-trigger-gate.sh}`
  — CLAUDE_ROLE-parameterized, registered globally in `core/hooks/hooks.json`'s
  `PreToolUse` block. Fire for every plugin install; a rulebook needs no
  `hooks.json` entry for these three at all once its copy is deleted.
- `core/hooks/lib/role-directive.sh` — sourceable library exposing
  `core_role_directive(you_decide, use_when, produces, hand_off)`, rendering the
  fixed preamble (trap/kill-switch/guard/open-close) around four role-supplied
  strings.
- `core/hooks/tests/stub-check.sh` — drift-recurrence detector: fails if any of
  the three gate filenames (or `parse-check.sh`) still exist under a rulebook's
  `hooks/` tree, and structurally validates that `directive.sh` is *only* the
  source line + var assignments + one `core_role_directive` call (item 5 target).
- `warrant/` plugin (`.claude-plugin/marketplace.json` entry `warrant`) — canon
  home of `agents/warrant-hunter.md` + `hooks/{directive.sh,hunt-guard.sh,
  hunt-state.sh,scope-gate.sh,state.sh,hooks.json}`. A rulebook installs this
  plugin instead of vendoring the agent file (item 1 target).
- `record-fields-gate.sh`'s terminal-state set is configurable via
  `RECORD_FIELDS_TERMINAL_STATES` (space-separated, default `landed`) — added
  because two of the 43 vendored copies disagreed on terminal `loop_state`
  values (core issue-66 finding). Item 4 in this issue's task list.

## Precedent: implementation-rulebook (already migrated)

`implementation-rulebook`'s `coding/` plugin already completed this exact
conversion (its own issue-provenance not in this repo's reach, but the shipped
state is directly readable):

- `coding/hooks/directive.sh`: still a standalone file — NOT a
  `role-directive.sh`-sourcing stub. It keeps its own trap/kill-switch/guard
  and a long, role-specific directive body (research/survey/proposal fields,
  execution judgment, hunt cadence, record requirement — far more than the
  four-value core stub shape covers). It does **not** call
  `core_role_directive`.
- `coding/hooks/{trailer-gate.sh,record-fields-gate.sh,handbook-trigger-gate.sh}`
  are **still present** as full vendored copies in this rulebook, still
  registered in its own `hooks.json`, still role-specific in content (e.g.
  `record-fields-gate.sh` checks a different field set and default terminal
  state than core's).
- `coding/agents/warrant-hunter.md` is **still a full vendored copy** (not a
  stub referencing the `warrant` plugin), still paired with its own
  `hunt-guard.sh`/`hunt-state.sh`.
- `README.md` states core's `core`/`terse`/`freelunch`/`scout` plugins are
  installed *alongside* this rulebook's own plugin, but does not list `warrant`
  as an installed dependency.

**This means implementation-rulebook is not yet the finished exemplar for
items 1–3 of this issue** — it predates (or has not yet absorbed) the
core-63/66 canon promotion its own gate files' comments describe as forthcoming.
The only concretely finished, load-bearing artifacts to build against are
core's own canon files and `stub-check.sh`'s structural rule, not a sibling
rulebook's already-converted `directive.sh`.

## Gaps this proposal must close

- No installed-plugin dependency on `core`'s marketplace exists yet in this
  repo (`.claude-plugin/marketplace.json` only registers `refactoring-legacy`
  itself) — items 1–3 assume the session also has `core` and `warrant`
  installed alongside this rulebook, the same way implementation-rulebook's
  README documents for `core`/`terse`/`freelunch`/`scout` (but per above, not
  yet for `warrant`). This repo's README needs the equivalent install
  instruction added, or the stub silently references a path that is never
  populated at runtime.
- `refactoring-legacy-progress-gate.sh` is referenced in `hooks.json` but the
  file has never existed in this repo — a pre-existing gap, not in the issue's
  5 items; flagged here, left untouched (out of this issue's scope) per the
  hand-off rule (신규 기능 구현이 섞이면 → implementation — this repo IS being
  worked by the implementation role here, but fixing an unrelated dangling
  reference is scope creep beyond the issue's stated 5 items).
