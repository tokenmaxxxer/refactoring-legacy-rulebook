# Current-state survey (issue-16)

Scope: the four residual defects named in the 2026-08-01 re-audit against
this rulebook's gate A+ closure (issue-13's delivered state, commit
`d091602`). This survey locates each defect by file/line in this repo
before the proposal designs a fix; it does not re-derive core issue #75's
or on-the-record issue #182's own fixes (see `scout-brief.md`).

## 1. Source guard — unguarded `gate-lib.sh` source, PASS self-attestation gap

All three methodology-enforcement gates source `gate-lib.sh` with **no**
`||` guard on the source statement:

- `proposal-norm/hooks/methodology-gate.sh:11`
- `characterization-tests/hooks/methodology-gate.sh:9`
- `refactoring-steps/hooks/methodology-gate.sh:11`

All three read, verbatim:

```
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
```

Per core's own `gate-lib.sh` usage-contract comment (`core/hooks/lib/gate-lib.sh:11-18`
in `tokenmaxxxer-core`, issue-75-confirmed), an unguarded source that fails
when core is unreachable runs no code at all — including no `gate_*`
function definitions — after which every
`gate_kill_switch_active ... || { exit 0; }` call site reads the resulting
"command not found" (exit 127) as the kill switch being *off*, silently
allowing everything. This is the exact shape core's new
`compliance-check.sh` (post-#75) flags:

```
if grep -q 'gate-lib\.sh"$' "$f" && ! grep -qE 'gate-lib\.sh"[[:space:]]*\|\|' "$f"; then
  reasons+=("sources gate-lib.sh with no || guard on the same line — fail-open when core is unreachable (missing CLAUDE_PLUGIN_ROOT_CORE)")
fi
```
(`core/hooks/tests/compliance-check.sh:51-59`)

All three of this repo's gate scripts would **fail** this check today.

**PASS self-attestation gap.** `docs/issue-13/reports/refactoring-legacy.md`
("Verification criteria" item 1) records `compliance-check.sh` as clean —
truthfully, at the time, against `tokenmaxxxer-core` PR #74 (issue-72's
landed `compliance-check.sh`, which did not yet contain the source-guard
check above). That record is a self-reported `PASS` claim written into a
phase-2 report; nothing in this repo re-runs `compliance-check.sh` against
the *current* core `main` on any cadence, so the record's "clean" claim
silently went stale the moment core issue-75 landed a stricter check. This
is the same class of residual limitation the README's Doctrine section
already names for `test_run: PASS` in characterization-test records
("a self-reported assertion the gate cannot independently execute-verify
at write time") — it now also applies to this repo's own
compliance-check-clean claim about itself.

`refactoring-legacy/hooks/directive.sh:4` sources `role-directive.sh`
(a different file, not `gate-lib.sh`) with the same unguarded shape; it is
outside `compliance-check.sh`'s `gate-lib\.sh"$` pattern (which only
matches gate-lib.sh sources) so it does not fail that specific check, but
it shares the identical fail-open-on-missing-core risk class.

## 2. `hooks.json` matcher vs. code tool-coverage

| Plugin | `hooks.json` matcher | Code's actual tool_name handling |
|---|---|---|
| `proposal-norm` | `Write\|Edit\|MultiEdit\|Bash` | Handles `Bash` (denies via `gate_bash_write_targets` token scan) + `Write`/`Edit`/`MultiEdit` (reconstructs). **Aligned.** |
| `characterization-tests` | `Write\|Edit\|MultiEdit\|Bash` | Same shape (`methodology-gate.sh:27-49` Bash branch, `:51-157` reconstruct branch). **Aligned.** |
| `refactoring-steps` | `Write\|Edit\|MultiEdit\|Bash` | Same shape. **Aligned.** |
| `refactoring-legacy` (top-level role plugin) | `Bash` only (`refactoring-legacy/hooks/hooks.json:10-17`) | **No code at all** — the matcher points at `${CLAUDE_PLUGIN_ROOT}/hooks/refactoring-legacy-progress-gate.sh`, a file that does not exist anywhere in this repo (confirmed absent by `find`). Every `Bash` tool call currently free-passes through this entry: a missing hook script is a Claude Code no-op, not a deny. |

Concrete mismatch: `refactoring-legacy/hooks/hooks.json`'s `Bash` matcher
has zero backing implementation — this is not a coverage-gap-in-the-code
case (like the pre-issue-13 `sed` bypass), it is a hooks.json entry
pointing at a ghost file. The three methodology-enforcement plugins'
`Write|Edit|MultiEdit|Bash` matchers are each fully aligned with their own
gate's `tool_name` branches (issue-13 already closed the coverage gap on
those three) — no work needed there beyond re-confirming after the
source-guard fix.

## 3. Ghost files / dangling references

- `refactoring-legacy/hooks/hooks.json:14` references
  `${CLAUDE_PLUGIN_ROOT}/hooks/refactoring-legacy-progress-gate.sh` —
  confirmed absent from `refactoring-legacy/hooks/` (only `directive.sh`
  and `hooks.json` exist there). This gap is not new: it was flagged
  "dangling" in `docs/issue-10/reports/refactoring-legacy.md`'s Open
  findings, reiterated as an explicit issue-13 Out-of-scope item, and is
  currently documented (not hidden) in `README.md:92-94,127-129,144-145`.
  Issue #16 requirement 4 ("old role names / ghost files ... become hard
  errors") makes this the concrete target: today the gap is *documented*
  but not *enforced against* — nothing fails if the file stays absent
  forever, or if a differently-named ghost file is introduced later.

## 4. Old role names

No old-role-name string was found anywhere in this repo's current tree.
`git log --oneline --reverse` shows the role was named `refactoring-legacy`
from the repo's first commit (`3f15c0c`, "Seed rulebook skeleton for role
refactoring-legacy (on-the-record issue-167)") onward — there was no prior
name to leave stale references to. `README.md`, `.claude-plugin/marketplace.json`,
and all four `*/.claude-plugin/plugin.json` manifests consistently use
`refactoring-legacy`, `proposal-norm`, `characterization-tests`,
`refactoring-steps`. Issue #16's requirement 4 ("old names become hard
errors") is therefore, for this repo, entirely about the ghost-file half
(item 3 above) — there is no old-role-name half to remediate here. The
proposal states this explicitly rather than inventing a check for a
condition that does not exist in this repo.

## 5. Missing-core test case / compliance-check pass record

Confirmed absent: none of the four `hooks/tests/run-gate-tests.sh` (or any
other test file in this repo) exercises a "core missing/unresolvable"
scenario (e.g. `CLAUDE_PLUGIN_ROOT_CORE` pointing at a nonexistent path, or
no `core/` sibling present) against any gate. Core's own
`run-gate-lib-tests.sh` gained a missing-core mandatory case as part of
issue-75 (`tokenmaxxxer-core` commit `52bdc15`, `run-gate-lib-tests.sh`
diff `+43` lines); this repo's suites have no equivalent. There is also no
recorded, dated re-run of `compliance-check.sh` against the *current*
(post-#75) core `main` anywhere in this repo — the only recorded run is
the stale one from issue-13 (item 1 above).

## Write-surface map (for the proposal's per-defect sequencing)

| Surface | File(s) | Defect(s) present |
|---|---|---|
| `proposal-norm` | `proposal-norm/hooks/methodology-gate.sh:11` | 1 |
| `characterization-tests` | `characterization-tests/hooks/methodology-gate.sh:9` | 1 |
| `refactoring-steps` | `refactoring-steps/hooks/methodology-gate.sh:11` | 1 |
| `refactoring-legacy` role plugin | `refactoring-legacy/hooks/hooks.json:10-17`, `refactoring-legacy/hooks/directive.sh:4` | 1 (directive.sh source shape), 2, 3 |
| test harnesses | `*/hooks/tests/run-gate-tests.sh` | 5 |
| docs | `README.md`, `docs/issue-13/reports/refactoring-legacy.md` (stale PASS claim, historical — not edited by this issue) | 1 (attestation gap) |
