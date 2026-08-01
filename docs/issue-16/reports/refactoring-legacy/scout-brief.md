# Scout brief (issue-16)

No external web search performed — this is an internal-conventions task;
the reference exemplars (core issue #75, on-the-record issue #182) are the
primary and sufficient source, per issue #16's own "Common preconditions"
section naming them as the exact upstream artifacts to reference-adopt.

## Precondition check: are #75 and #182 actually landed?

Both confirmed landed to their respective `main` branches, ahead of this
issue's residual-defect date (2026-08-01):

- **core issue #75** — `gh issue view 75 -R tokenmaxxxer/tokenmaxxxer-core`
  reports `state: CLOSED`, closed by PR #76 (propose) / **PR #77
  (deliver)**. `git -C tokenmaxxxer-core log main --oneline` shows
  `52bdc15 deliver(implementation): gate-lib source guard +
  gate_bash_write_targets py parity (issue-75) (#77)` on `main`.
- **on-the-record issue #182** — `gh issue view 182 -R
  tokenmaxxxer/on-the-record` reports `state: CLOSED`, closed by PR #185.
  `gh pr view 185 -R tokenmaxxxer/on-the-record` reports `state: MERGED`,
  `baseRefName: main`, `mergedAt: 2026-08-01T09:34:15Z`. (Note: the local
  on-disk clone of `on-the-record` predates this merge and could not be
  re-fetched in this sandbox — read-only filesystem — so the code below
  was read via `gh pr diff 185` against the actual merged PR content, not
  a local checkout of `main`.)

## What core #75 established (source guard + gate_bash_write_targets.py)

Landed at `tokenmaxxxer-core` commit `52bdc15` (PR #77, merged 2026-08-01),
on top of `main`. Changed files (from `git show --stat 52bdc15`):
`core/hooks/approval-gate.sh`, `board-gate.sh`, `directive.sh`,
`gh-guard.sh`, `handbook-trigger-gate.sh`, `record-fields-gate.sh`,
`trailer-gate.sh` (each `+1/-1`: added the `||` guard), plus
`core/hooks/lib/gate-lib.py` (+19), `core/hooks/lib/gate-lib.sh` (+9),
`core/hooks/tests/compliance-check.sh` (+10), `core/hooks/tests/run-gate-lib-tests.sh`
(+43), and `docs/handbooks/gate-house-standard.md` (+70/-... transition
note).

1. **Mandatory `||`-guarded source.** Every core gate's source line for
   `gate-lib.sh` now reads (verified in
   `core/hooks/approval-gate.sh:38`, identical shape repeated across all
   seven core gates):

   ```
   . "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "<gate-name>.sh: cannot source gate-lib.sh" >&2; exit 2; }
   ```

   `gate-lib.sh`'s own usage-contract header (`core/hooks/lib/gate-lib.sh:11-24`)
   documents *why*: an unguarded source that fails when core is
   unreachable runs no code at all — including no `gate_*` function
   definitions — so every subsequent
   `gate_kill_switch_active ... || { exit 0; }` call site reads the
   resulting "command not found" (127) as the kill switch being off,
   silently allowing everything. The `||` guard converts a missing/
   unreachable core into a hard `exit 2` deny instead.

2. **`compliance-check.sh` detection rule.** New rule added at
   `core/hooks/tests/compliance-check.sh:51-59`:

   ```
   if grep -q 'gate-lib\.sh"$' "$f" && ! grep -qE 'gate-lib\.sh"[[:space:]]*\|\|' "$f"; then
     reasons+=("sources gate-lib.sh with no || guard on the same line — fail-open when core is unreachable (missing CLAUDE_PLUGIN_ROOT_CORE)")
   fi
   ```

   This is a *detector* (invoked the same way `stub-check.sh` is, against
   a rulebook's own `hooks/` dir), not an enforcer at gate-runtime — it
   flags a gate script's source code shape, not a live PreToolUse event.

3. **Missing-core mandatory test case.** `core/hooks/tests/run-gate-lib-tests.sh`
   grew by 43 lines in the same commit — a case exercising the
   missing/unreachable-core path against the now-guarded source line
   (confirms the `|| exit 2` fires rather than silently continuing).

4. **`gate_bash_write_targets` ported to `gate-lib.py`.** `gate-lib.py`
   gained a 19-line addition at `core/hooks/lib/gate-lib.py:159` —
   `def gate_bash_write_targets(command):` — documented in its own
   docstring as "Python mirror of gate-lib.sh's gate_bash_write_targets
   (issue-75): same [token semantics]", sh/py parity-tested per the PR's
   commit message ("sh/py parity-tested").

## What on-the-record #182 established (CLAUDE_PLUGIN_ROOT_CORE injection)

Landed at `on-the-record` PR #185 (merged main, 2026-08-01T09:34:15Z),
commits `677aa32` (phase 1: survey+proposal) and `e50fe08` (phase 2:
implementation). Read via `gh pr diff 185 -R tokenmaxxxer/on-the-record`.

- **The gap it closed.** Before this PR, `spawn.py` never set
  `CLAUDE_PLUGIN_ROOT_CORE` in a spawned role session's environment, so a
  rulebook gate's own
  `${CLAUDE_PLUGIN_ROOT_CORE:-<relative-fallback>/core}` line fell through
  to the relative fallback, which resolves incorrectly in real deployment
  (pointing inside the rulebook's own clone, not the actual `core` plugin
  install) — combined with an unguarded source (core issue-75's defect),
  this fail-opened every rulebook gate in real deployment, not merely in
  a local dev checkout where the relative fallback happens to work.
- **The fix, in `spawn_cmd()`** (`spawn.py`, diff hunk at the function's
  existing env-setup block, immediately after the `TOKENMAXXXER_UNATTENDED`
  env line):

  ```python
  core_dir = next((p for p in (core_plugins or []) if Path(p).name == "core"), None)
  if core_dir:
      env["CLAUDE_PLUGIN_ROOT_CORE"] = str(core_dir)
  else:
      print("spawn_cmd: core_plugins 에 'core' 엔트리가 없다 — "
            "CLAUDE_PLUGIN_ROOT_CORE 미주입, 게이트가 fallback 경로로 "
            "빠질 수 있다", file=sys.stderr)
  ```

  It reuses the already-resolved `core_plugins` list (`_spawn_one()`
  builds this via `core_plugin_dirs()` and passes it into `spawn_cmd()`)
  by locating the entry whose `Path(p).name == "core"`, rather than
  calling `core_root()` a second time (which risks a redundant network
  clone) — this guarantees "injected path == the exact path passed via
  `--plugin-dir`" as a structural invariant, not a coincidence of two
  independent resolutions agreeing.
- **Tests added** (`test_spawn.py`, same diff):
  `test_claude_plugin_root_core_matches_attached_core_dir` (asserts the
  injected value string-equals the `core_plugins` entry) and
  `test_claude_plugin_root_core_unset_without_core_plugin` (asserts the
  var is *not* set, not set to a garbage value, when core is missing from
  `core_plugins` — the stderr warning path).
- **What it does NOT do.** No change to any rulebook's own gate scripts —
  this PR is entirely inside `on-the-record`'s `spawn.py`. It makes the
  *value* `${CLAUDE_PLUGIN_ROOT_CORE:-...}` resolves to correct in real
  deployment; it does not, by itself, fix an unguarded `||`-less source
  line in a downstream rulebook (that is core #75's + this issue's job).

## Gap line — what this repo already meets vs. still misses

Already meets (do not touch, do not re-derive):
`CLAUDE_PLUGIN_ROOT_CORE`-relative sourcing pattern itself (this repo
already used `${CLAUDE_PLUGIN_ROOT_CORE:-<fallback>}/hooks/lib/...` for
both `gate-lib.sh` and `role-directive.sh` before this issue — issue-13
already reference-adopted the *variable name and fallback shape*); the
three methodology gates' `Bash` matcher coverage in `hooks.json` (issue-13
already closed this per gate_bash_write_targets bash-side — see survey
§2); `gate_bash_write_targets` is already called (bash function form) at
`characterization-tests/hooks/methodology-gate.sh:46` and equivalent call
sites in the other two gates.

Missing (the actual remediation surface, per survey.md):

1. The `||` guard itself on all three `gate-lib.sh` source lines
   (survey §1) — core #75's exact fix, not yet ported here.
2. A recorded, current-dated `compliance-check.sh` run against this
   repo's three plugin `hooks/` dirs, using the post-#75
   `compliance-check.sh` (the recorded run in
   `docs/issue-13/reports/refactoring-legacy.md` predates #75's added
   check and is now stale — survey §1).
3. A missing-core test case in each of the three
   `hooks/tests/run-gate-tests.sh` suites (survey §5) — core's own
   `run-gate-lib-tests.sh` has this; this repo's three suites do not.
4. Nothing here needs `gate_bash_write_targets`'s Python-side port
   (`gate-lib.py:159`) specifically — this repo's gates already call the
   bash-side function, not a Python-side one, for the `Bash`-tool
   token-scan. The Python port is a core-internal parity fix (sh vs. py
   callers inside core itself); this repo has no `gate-lib.py`-side
   caller of `gate_bash_write_targets` to bring into parity. Recorded
   here so the proposal doesn't invent work core #75 didn't actually
   require of downstream rulebooks.
5. `CLAUDE_PLUGIN_ROOT_CORE` injection (on-the-record #182) is entirely
   upstream of this repo (lives in `spawn.py`) — nothing in this repo
   needs to change for #182 itself; it only means the fallback branch in
   this repo's `${CLAUDE_PLUGIN_ROOT_CORE:-...}` lines should now be
   correctly bypassed by injection in real deployment, making the `||`
   guard (item 1) the layer that actually matters going forward (a
   correctly-injected var mostly avoids hitting the fallback at all; the
   guard is what protects the case where injection itself fails or
   `core` truly is not installed).

## Pattern to adopt

Reference-not-copy, per this repo's own existing convention (issue-13's
scout-brief already established this and issue #16 does not change it):
add the `||` guard directly to the three existing source lines in place,
matching core's exact guard shape and deny-message convention
(`"<gate-name>.sh: cannot source gate-lib.sh"`-style, adapted per gate
name), rather than inventing a different guard idiom.

## Pattern to skip

Do not port `gate_bash_write_targets` into any local `gate-lib.py`-style
Python module in this repo — this repo has no such module and no
Python-side caller of that function (see "Missing" item 4 above); doing
so would be exactly the "re-derive a local version of a shape core
already owns" anti-pattern this repo's own issue-13 proposal already
rejected as Option A.

## Sources

This repo (`refactoring-legacy-rulebook`):
- `refactoring-legacy-rulebook/proposal-norm/hooks/methodology-gate.sh:11`
- `refactoring-legacy-rulebook/characterization-tests/hooks/methodology-gate.sh:9`
- `refactoring-legacy-rulebook/refactoring-steps/hooks/methodology-gate.sh:11`
- `refactoring-legacy-rulebook/refactoring-legacy/hooks/directive.sh:4`
- `refactoring-legacy-rulebook/refactoring-legacy/hooks/hooks.json`
- `refactoring-legacy-rulebook/docs/issue-13/reports/refactoring-legacy.md`
  (stale compliance-check PASS record)
- `refactoring-legacy-rulebook/docs/issue-13/proposals/proposal.md`,
  `refactoring-legacy-rulebook/docs/issue-13/reports/refactoring-legacy/survey.md`,
  `.../scout-brief.md` (prior template/precedent)

`tokenmaxxxer-core` (sibling checkout at
`/home/jwjung/tokenmaxxxer/tokenmaxxxer-core`, `main` branch):
- commit `52bdc15` — `deliver(implementation): gate-lib source guard +
  gate_bash_write_targets py parity (issue-75) (#77)`
- `core/hooks/lib/gate-lib.sh:11-24` (usage-contract header, guard
  rationale), `:86-99` (`gate_bash_write_targets` bash def)
- `core/hooks/lib/gate-lib.py:159` (`gate_bash_write_targets` python
  mirror)
- `core/hooks/tests/compliance-check.sh:51-59` (guard-detection rule),
  full file read
- `core/hooks/approval-gate.sh:38` (guarded source line, exemplar)
- `gh issue view 75 -R tokenmaxxxer/tokenmaxxxer-core` (state: CLOSED,
  closed by PR #77)

`on-the-record` (sibling checkout at
`/home/jwjung/tokenmaxxxer/on-the-record`; local clone predates the merge,
read via `gh` instead of a local `main` checkout):
- `gh issue view 182 -R tokenmaxxxer/on-the-record` (state: CLOSED, closed
  by PR #185)
- `gh pr view 185 -R tokenmaxxxer/on-the-record --json state,baseRefName,mergedAt,title`
  (MERGED, base `main`, merged 2026-08-01T09:34:15Z)
- `gh pr diff 185 -R tokenmaxxxer/on-the-record` — `spawn.py`'s
  `spawn_cmd()` diff hunk (`CLAUDE_PLUGIN_ROOT_CORE` injection),
  `test_spawn.py` diff hunk (the two new tests), commit messages
  `677aa32` / `e50fe08`
