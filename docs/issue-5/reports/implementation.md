# Phase 2 record — retire vendored stub-check.sh (issue #5)

loop_state: landed

## Summary of work (what was done, why)

Phase 2 execution of issue #5, approved via the single-account
`APPROVE issue-5/implementation` issue comment, on top of the phase-1
proposal at `docs/issue-5/proposals/` (commit 6693518). Core canon #69
retires the copy-based `stub-check.sh` model: the script must be run by
reference against the core plugin's installed copy, and a rulebook must
never vendor its own copy of it (the copy was itself the exact drift shape
`stub-check.sh` exists to catch — issue-69 item 2).

## What was removed

- `refactoring-legacy/hooks/tests/stub-check.sh` — the sole vendored copy,
  deleted. The now-empty `refactoring-legacy/hooks/tests/` directory was
  removed with it.

## hooks.json

No change: `refactoring-legacy/hooks/hooks.json` never registered
`stub-check.sh` as a hook entry (confirmed in the phase-1 survey — it only
wires `SessionStart` → `directive.sh` and `PreToolUse` →
`refactoring-legacy-progress-gate.sh`).

## README.md update

Replaced the `## Layout` bullet describing the vendored copy with the
reference-invocation form, confirmed against how core's own
`stub-check.sh` resolves itself at runtime (`${CLAUDE_PLUGIN_ROOT}/../core`
sibling-plugin shape, matching the comment header in core's script):

```
"${CORE_PLUGIN_ROOT:-$CLAUDE_PLUGIN_ROOT/../core}"/hooks/tests/stub-check.sh refactoring-legacy
```

## Verification: reference-run of core's stub-check.sh

Run against the core-installed copy
(`tokenmaxxxer-core/core/hooks/tests/stub-check.sh`), targeting this
role's directory, with no local copy present:

```
$ bash <core-plugin-root>/hooks/tests/stub-check.sh refactoring-legacy
stub-check: ok — no vendored 'trailer-gate.sh' under refactoring-legacy
stub-check: ok — no vendored 'record-fields-gate.sh' under refactoring-legacy
stub-check: ok — no vendored 'handbook-trigger-gate.sh' under refactoring-legacy
stub-check: ok — no vendored 'parse-check.sh' under refactoring-legacy
stub-check: ok — no vendored 'stub-check.sh' under refactoring-legacy
stub-check: FAIL — refactoring-legacy/hooks/directive.sh: has non-stub line(s),
  looks like regrown boilerplate: trap 'rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then exit 2; fi' EXIT
stub-check exit: 1
```

**Result: the 5 absence checks (including the new self-referential
`stub-check.sh` check) all pass; the pre-existing `directive.sh`
structural-check failure carries over unchanged.** That failure is the
same open discrepancy already recorded in
`docs/issue-2/reports/implementation.md` (the frozen `directive.sh`
contract keeps a `trap`/`set -uo pipefail` pair that core's structural
regex does not allow-list) and is out of scope for issue #5, which is
scoped only to the `stub-check.sh` vendoring itself. Not re-litigated here.

## Open findings

None new. The pre-existing `directive.sh` structural-check failure noted
above under Verification is carried over from `docs/issue-2`'s open
finding and remains unresolved there; it is out of scope for this issue.

## Files touched

Removed:
- `refactoring-legacy/hooks/tests/stub-check.sh`

Modified:
- `README.md`

Added:
- `docs/issue-5/reports/implementation.md` (this file)
