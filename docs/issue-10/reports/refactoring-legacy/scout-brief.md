# Scout brief — issue-10 (refactoring-legacy)

Mode: batched-sequential (not parallel fan-out). Reason: the sweep's real
angles — "which sibling rulebook already built a working local methodology
gate" and "which sibling already built a gate-test harness" — could only be
identified after locating which local sibling checkouts exist on disk
(`find` over `~/.tokenmaxxxer/work`), making genuine concurrent dispatch
unavailable for the first round; each subsequent read targeted a specific
already-identified file, so no further parallelism was lost. 3 stages used
of the 5-stage budget; wall-clock well under the 3-minute cap.

## Must-bes (what a working local methodology gate machine assumes)

1. **Fail-closed on every uncertain path** — unparseable JSON payload,
   unresolvable file content (an `Edit`/`MultiEdit` whose `old_string`
   doesn't match), or an internal script exception must all `exit 2`
   (deny), never `exit 0`. Both `pricing/hooks/methodology-gate.sh` and
   core's `record-fields-gate.sh` share this as a hard invariant, wrapped
   in a `trap ... EXIT` plus an inner `except Exception` handler.
2. **Narrow write-surface targeting by path regex** — the gate must
   restrict itself, by filename pattern, to exactly this role's own
   proposal/record write surfaces and exit 0 immediately (no-op) for any
   other write. A gate that fires on unrelated files is a correctness bug,
   not caution.
3. **Resolve the *resulting* content, not just the tool name** — the gate
   must reconstruct what the file will contain after `Write`, `Edit` (via
   `old_string`/`new_string` substitution against current content), or
   `MultiEdit` (sequential substitution, bailing if any edit's
   `old_string` doesn't match), then run the content check against that
   resulting text — never against the pre-write file or the diff alone.
4. **Layer on top of core's generic gate, never replace it** — the local
   gate's docstring explicitly frames itself as role-specific enforcement
   *in addition to* core's generic §20-field check, not a substitute.
5. **Kill switch env var** — an explicit `${ROLE}_METHODOLOGY_GATE_OFF`
   escape hatch, documented in the script header, for local debugging
   without deleting the hook wiring.
6. **A real-subprocess test harness, no framework** — `run-gate-tests.sh`
   spins up a throwaway `git init` repo per case, pipes a synthetic
   tool-call JSON payload on stdin to the actual gate script via `bash
   .../gate.sh`, and asserts the exit code against `0`(allow)/`2`(deny).
   Every test is a real process invocation of the real script, not a unit
   test against an extracted function.

## Chosen performance axes

- **Precision of required-element detection**: pricing's gate checks six
  named elements via `has_any(...)` keyword/phrase matching, with an
  explicit "structurally exited early" escape clause per element so a
  proposal that legitimately never reaches a stage isn't penalized for
  omitting it. This role's three deliverable-norm components (issue-1 (b))
  map cleanly onto the same shape.
- **Ordering enforcement, not just presence**: neither reference gate
  actually solves a *before/after* ordering constraint at Write-time (a
  single PreToolUse invocation has no memory of prior invocations). The
  closest working precedent found is `coding-progress-gate.sh`'s pattern
  (implementation-rulebook, exercised in its `tests/run-gate-tests.sh`
  `progress()` cases): it reads a *different* role's record file
  (`verify.md`) at commit time and denies the commit if that file's
  `loop_state`/`finding` fields show an unresolved blocking condition —
  i.e., ordering is enforced by inspecting durable on-disk state (a
  file's content) at the point of the gated action, not by the hook
  remembering anything across invocations itself.

## Adopt / skip

- **Adopt**: the six-element structural shape (per-element `has_any` +
  explicit-exit escape), path-regex scoping, fail-closed-everywhere, the
  Write/Edit/MultiEdit content-resolution logic, and the kill-switch
  convention — directly, adapted to this role's own three deliverable
  fields plus its six proposal-norm points.
- **Adopt**: the durable-on-disk-state pattern for the one real ordering
  constraint this role has (characterization test before structural
  change) — recorded as a small JSON/text state marker file this role's
  own gate writes/reads (e.g. a `.refactoring-legacy-state/<issue>.json`
  under the write scope, or a required field inside the record itself)
  rather than inventing hook-to-hook memory that doesn't exist in this
  hook model.
- **Skip**: copying `record-fields-gate.sh` or `methodology-gate.sh`
  verbatim — canon-reference constraint (core canon-scripts.md) forbids
  vendoring copies; only the *shape* is adopted, re-derived for this
  role's own required elements.
- **Skip**: attempting true git-history-timestamp verification that a
  characterization test file's first commit predates the first edit to
  the refactored source path — issue-1 already flagged this as possibly
  infeasible, and the scouted precedent solves ordering via durable state
  inspection, not git-log archaeology; re-deriving a more powerful
  mechanism than any sibling has built is over-scoping phase 1.

## Gap line

Doctrine (issue-1) already states the must-bes conceptually (test-first,
small named steps, evidence-citing note, scope boundary). What is missing,
matching the field's must-bes above: (1) fail-closed automated enforcement
of presence — absent entirely; (2) durable-state-backed ordering
enforcement for test-first — absent entirely, previously deemed possibly
infeasible without ever trying the durable-state-marker approach that
sibling precedent actually uses for its own ordering constraint; (3) a
real-subprocess gate-test harness — absent entirely, no `tests/` directory
exists in this repo at all.

## Sources

- `pricing-rulebook/pricing/hooks/methodology-gate.sh` (local checkout,
  read in full).
- `pricing-rulebook/pricing/hooks/hooks.json` (local checkout).
- `implementation-rulebook/coding/hooks/` — `tests/run-gate-tests.sh`
  (local checkout, read in full; references `record-fields-gate.sh`,
  `trailer-gate.sh`, `coding-progress-gate.sh` by the calls it makes to
  them).
- This repo's own `docs/issue-1/proposals/proposal.md` and
  `docs/issue-1/reports/refactoring-legacy.md` (prior finding that core's
  per-role field table has no registration mechanism for this role —
  re-verified as still the working assumption, not re-fetched from core
  this pass since issue-1 already did that read and nothing in this
  repo's history since suggests core changed).
