# Scout brief (issue-13)

Angle count: 1 (single mandated reference target, not an open field —
see below), run inline in this session (no background fan-out available
in this headless single-turn run; stated per scout-directive fallback
rule). Stages used: 1 sweep, 1 deepening read of the linked files
(gate-lib.sh, gate-lib.py) — 2 stages total, well under budget.

## Why one angle, not a multi-angle sweep

Issue #13's precondition line names the exact exemplar to adopt: "core
issue #72(게이트 하우스 표준)가 랜딩된 뒤 그 공유 라이브러리를 참조해
구현(자체 재구현 금지)." This is not an open competitive-landscape
question (no "best gate design in the industry" search) — it is a
single fixed upstream artifact whose landed state must be read before
any design decision. The scout pass here is: confirm issue-72 landed to
`tokenmaxxxer/tokenmaxxxer-core`'s `main`, then read what it actually
shipped.

## What was checked

- `gh api repos/tokenmaxxxer/tokenmaxxxer-core/commits/main` — HEAD is
  `22a7cad`, `deliver(implementation): gate-house standard canonization
  (issue-72) (#74)` — landed, not just proposed.
- `docs/handbooks/gate-house-standard.md` (on `main`) — the handbook
  itself.
- `core/hooks/lib/gate-lib.sh`, `core/hooks/lib/gate-lib.py` (on `main`)
  — the actual functions.

## Must-bes (what a compliant gate must now do, per the landed standard)

1. Source `gate-lib.sh` and call `gate_trap_fail_closed` as the very
   first statement, before `set -uo pipefail`.
2. Call `gate_kill_switch_active "$THE_VAR"` instead of a hand-rolled
   `case`/`[ = "1" ]` check.
3. Load `gate-lib.py` via `importlib.util.spec_from_file_location` (env
   var `GATE_LIB_PY`, already exported by `gate-lib.sh`) inside each
   gate's own Python payload, rather than re-deriving JSON-parse,
   path-normalize, or reconstruct logic locally.
4. Call `gate_lib.gate_parse_json_or_deny(raw, deny)` for the
   malformed-JSON path.
5. Call `gate_lib.gate_normalize_path(root, path)` for scope matching
   instead of a raw regex `.search` on `tool_input.file_path`.
6. Call `gate_lib.gate_reconstruct_write(tool, tool_input,
   current_content)` for the actual post-write text — the fix for
   defect class 1 (existing+new concatenation) in the survey.
7. Use `gate_bash_write_targets` (bash-side) to extend `Bash`-tool
   coverage — the fix for defect class 2 (sed bypass) in the survey.
8. Ship a `run-gate-lib-tests.sh`-equivalent six-case suite per gate
   (Edit+replace_all-multi-occurrence, MultiEdit mixed replace_all,
   malformed JSON, kill-switch-unrecognized-value-stays-active,
   absolute-path parity, Bash-tool write reaching the same target).
9. Pass `compliance-check.sh` (invoked the same way `stub-check.sh` is)
   clean, with zero flagged hand-rolled kill-switch or
   `.replace(old, new[, 1])` reconstruction.

## Gap line — what this repo's gates already meet vs. still miss

Already meets (do not touch, do not re-derive): malformed-JSON
fail-closed deny (all three gates already deny on parse failure); deny
reason on stderr (all three already write to `&2`); kill-switch
correctness on the recognized-on-spelling axis (all three already treat
only `"1"` as disabling, none has core's pre-issue-72
default-off-on-unrecognized-value bug — narrower spelling set than
`gate_kill_switch_active`'s, but not backwards).

Missing (the actual remediation surface): no EXIT trap at all (must-be
1); hand-rolled kill-switch instead of the shared function (must-be 2,
low-severity but flagged by `compliance-check.sh` regardless); no
`gate-lib.py` load anywhere (must-bes 3-6); raw-regex path scope instead
of `gate_normalize_path` (must-be 5); zero `Bash`-tool coverage on any
of the three gates (must-be 7); no six-case suite, no
`compliance-check.sh` run (must-bes 8-9).

## Pattern to adopt

Reference-not-copy: source `gate-lib.sh`/load `gate-lib.py` at the
resolved `CLAUDE_PLUGIN_ROOT_CORE`-relative path (mirroring
`refactoring-legacy/hooks/directive.sh`'s existing
`CLAUDE_PLUGIN_ROOT_CORE`/fallback-to-sibling-`core`-dir pattern for
`role-directive.sh`), never vendor a copy — `stub-check.sh` /
`compliance-check.sh` both exist specifically to catch a vendored copy
via `canon-manifest.txt`.

## Pattern to skip

Do not invent a fourth, rulebook-local reconstruction/kill-switch/path
helper "just for this repo's shape" — the standard's whole point (per
its own opening line: "six repo-wide structural defect classes, not
isolated per-repo bugs") is that per-repo re-derivation is the disease,
not a legitimate local variation.

## Segment fit

This rulebook is exactly the "downstream rulebook repo" the standard's
migration checklist targets (`docs/handbooks/gate-house-standard.md`'s
"Per-repo migration checklist" section, steps 1-5) — no adaptation of
the checklist itself is needed; the proposal below follows it directly.

Sources:
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/commit/22a7cadef5c1389433d130bb4c9742863fbe47c0
- https://raw.githubusercontent.com/tokenmaxxxer/tokenmaxxxer-core/main/docs/handbooks/gate-house-standard.md
- https://raw.githubusercontent.com/tokenmaxxxer/tokenmaxxxer-core/main/core/hooks/lib/gate-lib.sh
- https://raw.githubusercontent.com/tokenmaxxxer/tokenmaxxxer-core/main/core/hooks/lib/gate-lib.py
