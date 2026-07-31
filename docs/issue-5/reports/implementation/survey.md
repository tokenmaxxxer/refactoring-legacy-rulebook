# Issue #5 — Phase 1 survey: stub-check.sh vendoring

## Scope

Core canon #69 (`docs/handbooks/canon-scripts.md`, lives in the `core`
rulebook, not in this repo) states: `stub-check.sh` must be run by
*reference* against the core-installed copy; rulebooks must not vendor
(copy) their own version of it.

## Where stub-check.sh exists in this repo

- `refactoring-legacy/hooks/tests/stub-check.sh` — the only copy found.
  Verified verbatim copy of core's drift-recurrence check (per its own
  header comment: "Distributed to every rulebook ... Every rulebook copies
  this file verbatim and runs it over its own hooks/ tree.").
  - `find . -name 'stub-check.sh' -not -path '*/.git/*'` returns exactly
    this one path.
  - No inlined/embedded copies of its logic were found elsewhere (grep for
    `CANON_GATES`, `core_role_directive` structural-check logic, etc.
    outside this file returned nothing).

No canonical `core/hooks/tests/stub-check.sh` file exists inside *this*
repo's working tree — `core` is a separate plugin (see README's Install
section: `claude plugin install core` from the `tokenmaxxxer-core`
marketplace). This repo has no git submodule for it (`.gitmodules` does not
exist) and no local `core/` directory. The canonical source is therefore an
externally-installed plugin path, not a path checked into this repository.

## hooks.json registration

- `refactoring-legacy/hooks/hooks.json` is the only `hooks.json` in the
  repo (`find . -iname 'hooks.json'`).
- Its contents register exactly two hooks:
  - `SessionStart` → `${CLAUDE_PLUGIN_ROOT}/hooks/directive.sh`
  - `PreToolUse` (matcher `Bash`) → `${CLAUDE_PLUGIN_ROOT}/hooks/refactoring-legacy-progress-gate.sh`
- `stub-check.sh` has **no entry** in `hooks.json` — it is not wired up as
  an automatically-firing hook at all. It appears to be intended as a
  manually-run / CI-run check (per its own header: "run against
  `refactoring-legacy/` to confirm no core canon file has been
  re-vendored locally"), not a session hook.
- README.md (`## Layout` section) documents the file as: "verbatim copy of
  core's drift-recurrence check; run against `refactoring-legacy/` to
  confirm no core canon file has been re-vendored locally."

## Cross-references in issue-2 docs

`docs/issue-2/reports/implementation/survey.md` and
`docs/issue-2/proposals/2026-07-31-core-canon-reference-conversion.md`
(phase-1/phase-2 record of the prior issue #2 work) describe
`refactoring-legacy/hooks/tests/stub-check.sh` as having been added as a
**verbatim copy from core**, specifically because at the time core's own
canon promotion (issue-66) had not yet been rolled out to make it
reference-only. That is exactly the vendoring core canon #69 (issue #5)
now retires.

## Canonical source per core canon #69

The canonical, single source of truth for `stub-check.sh` is the copy
shipped inside the `core` plugin (installed via `claude plugin install
core` from the `tokenmaxxxer-core` marketplace), conventionally at
`core/hooks/tests/stub-check.sh` inside that plugin's own repo/install
tree. This repo's `refactoring-legacy/hooks/tests/stub-check.sh` is a
disallowed vendored duplicate under core canon #69 and is the deletion
candidate.
