# Issue #5 — Phase 1 proposal: retire vendored stub-check.sh

Status: **proposal only — not executed, not approved.**

## Delete

- `refactoring-legacy/hooks/tests/stub-check.sh` — the sole vendored copy
  (see survey.md). No other copies or inlined-logic duplicates exist.

## Reference mechanism to use instead

Per core canon #69, `stub-check.sh` is run *by reference* against the
core-installed plugin copy rather than a local copy. Since `core` is
installed as a separate plugin (not vendored into this repo, no
submodule), the reference is an invocation path, not a repo file:

- Document (README.md `## Layout`, replacing the current bullet) that
  `stub-check.sh` is run via the core plugin's installed path, e.g.
  `"$CLAUDE_PLUGIN_ROOT"/../core/hooks/tests/stub-check.sh
  refactoring-legacy/` (exact `${CLAUDE_PLUGIN_ROOT}`-relative form to be
  confirmed against how `core` actually resolves sibling-plugin paths at
  runtime — needs a phase-2 check, not a guess).
- Record the pass/fail of that reference-run in
  `docs/issue-5/reports/implementation.md` (phase-2 record), matching how
  `docs/issue-2` recorded the same check's copy-based run.

## hooks.json changes needed

None required beyond documentation: `refactoring-legacy/hooks/hooks.json`
never registered `stub-check.sh` as a hook entry (confirmed in survey.md —
it only has `SessionStart` → `directive.sh` and `PreToolUse` →
`refactoring-legacy-progress-gate.sh`). No hooks.json edit is needed for
the deletion itself.

## README.md update needed

Update the `## Layout` bullet currently describing
`refactoring-legacy/hooks/tests/stub-check.sh` as a "verbatim copy of
core's drift-recurrence check" to instead point at the core-plugin
reference-run mechanism above, once phase 2 confirms the exact invocation
form.

## Out of scope for this proposal

- Any change to `core`'s own plugin (its `stub-check.sh` remains
  canonical there).
- Any change to `docs/issue-2` records (historical; left as-is).
