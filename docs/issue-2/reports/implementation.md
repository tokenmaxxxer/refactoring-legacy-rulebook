# Phase 2 record — core canon reference conversion (issue #2)

loop_state: landed

## Summary of work (what was done, why)

This record documents phase 2 execution of GitHub issue #2, approved by
a human reviewer per contract v3 s19 on top of the phase-1 proposal at
`docs/issue-2/proposals/2026-07-31-core-canon-reference-conversion.md`
(upstream basis: commit 21086aa, "Phase 1: propose core canon reference
conversion (issue #2)", and the survey at
`docs/issue-2/reports/implementation/survey.md`). Why: core landed a
single canon for the warrant-hunt agent and the three role-agnostic gates
(core issues #63/#66); this rulebook still vendored its own pre-canon
copies of all four plus a full standalone `directive.sh`, which issue #2
requires converted to reference core canon instead of forking it. No
redesign was performed here — the phase-1 proposal's frozen contract was
executed exactly as approved; the file shapes below are copied/authored
verbatim from `tokenmaxxxer-core`'s canon per that contract.

## What was removed

- `refactoring-legacy/agents/warrant-hunter.md` — deleted. The `warrant` core
  plugin (`tokenmaxxxer-core/warrant`) is the canon home of this agent going
  forward; this rulebook no longer vendors a copy. The now-empty
  `refactoring-legacy/agents/` directory was removed with it.
- `refactoring-legacy/hooks/trailer-gate.sh` — deleted. Fired globally by
  `core/hooks/hooks.json` once `core` is installed.
- `refactoring-legacy/hooks/record-fields-gate.sh` — deleted, same reason.
- `refactoring-legacy/hooks/handbook-trigger-gate.sh` — deleted, same reason
  (this file was only ever a placeholder verdict per the phase-1 survey, so
  no logic is lost).
- The three corresponding entries in `refactoring-legacy/hooks/hooks.json`'s
  `PreToolUse` block. The pre-existing, out-of-scope dangling entry for
  `refactoring-legacy-progress-gate.sh` (a file that has never existed in
  this repo) was left untouched, per the proposal's explicit "out of scope"
  call — it is not one of this issue's 5 items.

## What was stubbed

- `refactoring-legacy/hooks/directive.sh` replaced with the exact stub text
  frozen in the phase-1 proposal: it sources
  `core/hooks/lib/role-directive.sh` and calls `core_role_directive` with
  this role's four values (`YOU DECIDE`, `USE_WHEN`, `PRODUCES`, `HAND-OFF`),
  keeping only the `trap`/`set -uo pipefail` pair locally (per the proposal's
  stated rationale: a trap inside the sourced function does not catch the
  sourcing script's own exit).

## Role-specific content preserved

- The four directive values above (this role's actual decision criterion,
  use-when trigger, produces list, and hand-off target) are preserved
  verbatim inside the new stub's `core_role_directive` call — they are not
  core canon, they are this role's own doctrine, and `core_role_directive`
  takes them as parameters specifically so each role keeps them.
- `WRITE_SCOPE: ['src/**', 'test/**']`, previously printed inline by the old
  standalone `directive.sh`, is not part of `core_role_directive`'s four-value
  shape (core's own directive.sh does not print a write scope either — write
  scope is enforced by `board-gate.sh`, not printed by the role directive).
  It remains documented in this repo's `README.md`, which already lists it
  under the role summary; no information was dropped, only its emission
  point moved from a runtime hook echo to the static doc that already
  carried it.
- `RECORD_FIELDS_TERMINAL_STATES` override: **not set**, per the proposal's
  own resolution (item 6) — this role's record shape names no non-`landed`
  terminal `loop_state`, so there is no divergence to preserve and the
  default in core's `record-fields-gate.sh` applies unmodified.
- `refactoring-legacy-progress-gate.sh`'s dangling `hooks.json` reference —
  preserved as-is (pre-existing gap, explicitly out of scope for this issue).

## README / install surface

Added an install-alongside section for `core`, `terse`, `freelunch`, `scout`,
and `warrant` from the `tokenmaxxxer/core` marketplace, and updated the
"Layout" section to describe the post-conversion file set (closes the gap
the phase-1 survey flagged: the stub referencing `core/hooks/lib/...` needs
an install instruction or it points at a path nothing populates).

## Verification: `stub-check.sh`

Copied verbatim (upstream basis: `tokenmaxxxer-core`, commit
2fd1fcbe364ed59be7969a81177c8a080608de57) from
`core/hooks/tests/stub-check.sh` into
`refactoring-legacy/hooks/tests/stub-check.sh`, then run against
`refactoring-legacy/`:

```
$ bash refactoring-legacy/hooks/tests/stub-check.sh refactoring-legacy
stub-check: ok — no vendored 'trailer-gate.sh' under refactoring-legacy
stub-check: ok — no vendored 'record-fields-gate.sh' under refactoring-legacy
stub-check: ok — no vendored 'handbook-trigger-gate.sh' under refactoring-legacy
stub-check: ok — no vendored 'parse-check.sh' under refactoring-legacy
stub-check: FAIL — refactoring-legacy/hooks/directive.sh: has non-stub line(s),
  looks like regrown boilerplate: trap 'rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then exit 2; fi' EXIT
stub-check exit: 1
```

**Result: 4 of 5 checks pass; the `directive.sh` structural check FAILS.**

This is a genuine discrepancy between the phase-1 proposal's frozen contract
and the actual, verbatim-copied `stub-check.sh` from core canon — not a
mistake introduced during this execution. The proposal's frozen contract
requires the `trap`/`set -uo pipefail` pair to stay in the rulebook's own
`directive.sh` (citing "core's own issue-66 record" as the reason a trap
inside the sourced `core_role_directive` function cannot catch the sourcing
script's own exit). But `stub-check.sh`'s actual structural regex only
allow-lists blank/comment lines, the shebang, the `role-directive.sh` source
line, the `core_role_directive` call, and plain variable assignments — a
bare `trap ...` or `set -uo pipefail` line does not match any of those and
is flagged as "regrown boilerplate," regardless of its rationale.

Per this issue's mandate ("execute exactly what the phase-1 proposal
specifies — do not redesign it"), the `directive.sh` content was kept
verbatim as frozen rather than unilaterally dropping the `trap`/`set` lines
to force a pass (which would also diverge from the shape the proposal
states core's own canon expects every rulebook to keep). The other four
structural/absence checks in `stub-check.sh` — the actual "no local fork"
items 1-2 of the issue's task list — all pass cleanly. The `directive.sh`
mismatch is a stub-check.sh-vs-proposal-text conflict, flagged here for the
approver/core maintainers rather than silently resolved by this execution
pass, since resolving it either way (drop the trap lines, or loosen
`stub-check.sh`'s regex) is a design call outside the scope of "execute the
frozen contract."

## Open findings

- `stub-check.sh`'s structural check on `directive.sh` FAILS against the
  frozen-contract stub because the check's allow-list has no exception for
  the `trap`/`set -uo pipefail` pair the contract text requires kept. This
  needs a decision from the approver or core maintainers: either amend the
  frozen contract to drop those two lines (accepting the trap-does-not-
  propagate risk the contract's own comment warns about), or amend core's
  `stub-check.sh` regex to allow-list them. Not resolved unilaterally here.
- No other open findings; all other proposal items (agent/gate deletion,
  hooks.json cleanup, README install instructions,
  `RECORD_FIELDS_TERMINAL_STATES` non-override) are complete and verified
  by direct `find`/read against the frozen contract's stated checks.

## Files touched

Removed:
- `refactoring-legacy/agents/warrant-hunter.md` (and the now-empty `agents/` dir)
- `refactoring-legacy/hooks/trailer-gate.sh`
- `refactoring-legacy/hooks/record-fields-gate.sh`
- `refactoring-legacy/hooks/handbook-trigger-gate.sh`

Modified:
- `refactoring-legacy/hooks/hooks.json`
- `refactoring-legacy/hooks/directive.sh`
- `README.md`

Added:
- `refactoring-legacy/hooks/tests/stub-check.sh`
- `docs/issue-2/reports/implementation.md` (this file)
