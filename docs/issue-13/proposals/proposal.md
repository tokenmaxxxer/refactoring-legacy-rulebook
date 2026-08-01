# Proposal: gate A+ remediation (issue-13)

Basis: `docs/issue-13/reports/refactoring-legacy/survey.md` (current-state
defect map) and `docs/issue-13/reports/refactoring-legacy/scout-brief.md`
(core's landed gate-house standard, Sources: listed there). Adopted
methodology citations: Feathers, *Working Effectively with Legacy Code*
(characterization testing / seams); Fowler, *Refactoring: Improving the
Design of Existing Code* (catalog-driven steps); core's
`docs/handbooks/gate-house-standard.md` (issue-72, landed) for the shared
gate-implementation shape this issue's precondition mandates
reference-adopting rather than re-deriving.

## Context

The 2026-08-01 audit graded this rulebook's three methodology gates
(`proposal-norm`, `characterization-tests`, `refactoring-steps`, all built
under issue #10) B-, naming four defect classes: (1) reconstruction that
concatenates existing-on-disk content with new text instead of modeling a
real `Write`/`Edit`/`MultiEdit`/`replace_all` replacement — deletions
never modeled, a same-file rewrite scored against content no longer on
disk; (2) a `Bash`-tool bypass (`sed`, `cat >`, etc. reach disk with zero
gate evaluation — none of the three `hooks.json` registers a `Bash`
matcher); (3) semantic checks that pass on a bare substring match anywhere
in the effective text (the word `"catalog"` alone satisfies
`refactoring-steps`'s catalog-step check; `"seam"`, `"equivalence"`,
`"context"`/`"option"`/`"decision"`/`"consequence"` all match the same
way); (4) a `characterization_tests_path` field whose value is never
checked to name a file that exists, let alone one whose tests actually
pass. The survey (§1-§6) locates each defect by file and line; this
proposal's job is to design the fix, not re-audit.

Issue #13 sets a precondition: core issue #72 ("게이트 하우스 표준")
landed a shared `gate-lib.sh`/`gate-lib.py` codifying fixes for
structurally the same defect classes found across core's own seven gates
and 43 downstream rulebooks — trap-at-top fail-closed, a fixed
kill-switch convention, JSON-parse-or-deny, path normalization, and full
`Write`/`Edit`/`MultiEdit`/`NotebookEdit` reconstruction honoring
per-edit `replace_all`. The precondition text is explicit: reference-adopt
this library, do not re-derive a local version of the same shapes.

## Options considered

**Option A — patch each gate's embedded Python in place, ad hoc.** Add a
real replace-based reconstruction, a `Bash` matcher, tighter regexes, and
a file-existence check, independently in each of the three
`methodology-gate.sh` scripts, without touching the shared library.
Rejected: this is exactly the "each repo re-derives its own version of
the same shape" pattern issue-72's own audit named as the root cause of
core's original bugs, and it violates issue #13's explicit precondition
("자체 재구현 금지"). It would also leave `compliance-check.sh` flagging
this repo's gates as non-compliant even after the fix landed.

**Option B — migrate all three gates onto `gate-lib.sh`/`gate-lib.py`,
building the section/adjacency/structure semantic layer as this repo's own
addition on top.** Source `gate-lib.sh` for trap/kill-switch/deny/Bash-scan;
load `gate-lib.py` for JSON-parse-or-deny, path-normalize, and full
reconstruction; keep the *content* of what each gate checks for
(catalog-step names, seam, equivalence note, ADR shape, etc.) as this
rulebook's own logic, since that content is role-specific and has no
counterpart in the role-agnostic core library. **Chosen.**

**Option C — replace the three custom gates with a single generic
role-agnostic gate configured by a rules file.** Rejected as out of scope
for an A+ remediation issue: it would re-architect the plugin-per-
methodology cut issue-10 deliberately chose (one plugin, one methodology,
independently loadable/disable-able — see `README.md`'s Doctrine
section), which issue #13's audit does not ask to revisit. A generic
rules-file gate is also a heavier surface to build and test inside a
budget the audit scoped to remediation, not redesign.

## Decision

Adopt Option B. Concretely, per gate:

### 1. Reference-adopt `gate-lib.sh` / `gate-lib.py` (fixes defect 1, part of 5)

Each `hooks/methodology-gate.sh` sources `gate-lib.sh` at
`${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh`
(mirroring the existing pattern in
`refactoring-legacy/hooks/directive.sh:4` for `role-directive.sh`), calls
`gate_trap_fail_closed` as the first statement before `set -uo pipefail`,
and calls `gate_kill_switch_active "$THE_VAR"` in place of the current
`[ "${...}" = "1" ]` check. Each gate's embedded Python payload loads
`gate-lib.py` via `importlib.util.spec_from_file_location(..., os.environ["GATE_LIB_PY"])`
and calls `gate_lib.gate_parse_json_or_deny(raw, deny)` for JSON parsing,
`gate_lib.gate_normalize_path(repo_root, file_path)` for scope matching
(replacing the raw `re.search` against the unnormalized `file_path`
string — fixes the absolute/`./`-prefixed gap in survey §5), and
`gate_lib.gate_reconstruct_write(tool_name, tool_input, current_content)`
for the actual post-write text — replacing every
`existing + "".join(new_strings)` concatenation. `gate_reconstruct_write`
returns `(None, False)` when an `Edit`'s `old_string` is not present in
`current_content`; on `ok is False` the gate treats reconstruction as
undeterminable and denies (fail-closed, matching the posture
`gate-lib.py`'s own docstring specifies for its callers), rather than
falling back to the old concatenation.

### 2. `Bash`-tool coverage (fixes defect 2)

Each plugin's `hooks/hooks.json` adds a `PreToolUse`/`Bash` matcher
entry pointing at the same `methodology-gate.sh`. Inside the gate, a
`Bash` `tool_name` branches to: run `gate_bash_write_targets
"$tool_input.command"` (bash-side, before the JSON payload is even
handed to the Python parser — the same token-scan `approval-gate.sh`/
`board-gate.sh` already use per the scout brief) to extract path-shaped
tokens from the command string, then apply the same
`gate_normalize_path`-based scope check to each candidate token; if any
candidate falls in scope, deny with a message naming the gate cannot
verify a `Bash`-executed write's resulting content and refuses rather
than guessing (`Bash` writes are opaque to reconstruction — the gate
denies the *write attempt*, it does not attempt to reconstruct
`sed`/`cat` output). This closes the `refactoring-legacy-progress-gate.sh`-adjacent
gap the README already flagged as dangling; that file itself remains a
separate, still-not-created hook (out of scope, see below) — this
proposal only ensures the three methodology gates themselves can no
longer be routed around via `Bash`.

### 3. Section/adjacency/structure semantic checks (fixes defect 3)

Replace every bare-substring check with a check anchored to markdown
structure, evaluated against the reconstructed full text (not
existing+new concatenation) from step 1:

- **`proposal-norm`**: each of the six required elements must appear
  under (i.e. as text following, before the next `^#{1,3}\s` line) a
  markdown heading whose title matches a small alias set per element —
  e.g. survey reference under a heading containing "survey" or
  "basis"/"근거"; ADR shape requires the *heading titles themselves*
  (not body text anywhere) to cover at least 2 of
  Context/Options/Decision/Consequences (case-insensitive, singular or
  plural); out-of-scope requires a heading matching
  `out[\s-]?of[\s-]?scope`/`범위 밖`; verification criteria requires a
  heading matching `verification`/`검증`. `survey.md`/`scout-brief.md`
  references and the methodology citation stay substring checks (they
  name a specific file/author, already unambiguous — heading-anchoring a
  citation would just move the loophole to "put the citation under any
  heading").
- **`characterization-tests`**: require a heading matching
  `seam` (not the bare word anywhere) naming the seam; require the
  `characterization_tests_path:` field line and a `test_run:`
  result line (new field, see below) to be **adjacent** — within 3 lines
  of each other — so a path and a claimed run-result cannot be stated in
  unrelated parts of the record; require the path, once normalized via
  `gate_normalize_path` against repo root, to resolve to a file that
  **exists on disk** (fixes defect 4's existence half) and is non-empty.
- **`refactoring-steps`**: require each named catalog step to appear as a
  markdown list item (`^\s*[-*]\s`) under a heading matching
  `refactoring steps`/`리팩터링 단계`, and require the item's text to
  contain one of the specific catalog-term phrases *excluding* the bare
  word `"catalog"` on its own (drop `"catalog"` from the term list
  entirely — every other term in the list is already a specific,
  identifiable step name; a bare mention of the word "catalog" names
  nothing) — this directly closes the audit's named "'catalog' 단어 통과"
  finding. Require the equivalence note under a heading matching
  `equivalence`/`동등성`, adjacent (within the same section) to at least
  one concrete test-name-shaped token (a path-like or
  `test_`/`Test`-prefixed identifier) so the note cannot be a bare "tests
  pass" sentence with no named referent.

### 4. Characterization-test pass verification (fixes defect 4's second half)

`characterization-tests` requires a new adjacent field,
`test_run: <PASS|FAIL> (<command>)`, within 3 lines of
`characterization_tests_path:`. The gate denies unless the value starts
with `PASS` — this does not execute the test command itself (a
`PreToolUse` gate is not the right place to shell out to an arbitrary,
potentially-slow or side-effecting test runner on every record write);
it requires the author to assert a specific run result in a
structurally-checkable, adjacent field rather than the free-floating
"characterization test" substring today. **Verification criteria** below
adds an independent phase-2 check (a human/CI step, not the gate) that
re-runs the named command and confirms the record's `PASS` claim is
truthful — this is the honest boundary of what a text-presence gate can
enforce versus what requires actually executing code, and this proposal
states it rather than silently under-delivering "verified" in the gate's
own deny message.

### 5. Compliance and test-suite obligations

- Each of the three plugins gets a `run-gate-lib-tests.sh`-shaped suite
  (adapted per gate) covering, at minimum, the six mandatory cases from
  `gate-house-standard.md`: `Edit`+`replace_all:true` against a
  multiply-occurring `old_string`; `MultiEdit` with mixed
  `replace_all` true/false edits; malformed JSON (truncated, non-object,
  empty); kill-switch set to an unrecognized value (must stay active);
  absolute `file_path` matching the same scope a relative fixture
  matches, plus a `./`-prefixed variant; a `Bash`-tool write reaching the
  same target a `Write`-tool call would hit. Existing suites' passing
  cases (malformed-JSON-denies, deny-on-stderr, the `refactoring-steps`
  ordering cases 5-7) are kept, not rewritten from scratch.
- `core/hooks/tests/compliance-check.sh "$(pwd)"` run against each
  plugin's `hooks/` directory must report clean (no hand-rolled
  kill-switch, no `.replace(old, new[, 1])`-shaped reconstruction) before
  phase 2 is considered complete.
- Full three-suite run green is a phase-2 delivery gate (verification
  criteria below), not merely "should pass."

### 6. README/handbook realignment (fixes defect/finding 7)

`README.md`'s Doctrine section and `docs/handbooks/gate-hooks.md` are
updated to: name `gate-lib.sh`/`gate-lib.py` as the now-mandatory shared
implementation each gate sources/loads; document the `Bash`-matcher
coverage added in step 2; document the new `test_run:` field
requirement; and correct/remove any sentence that becomes stale once the
gates no longer do raw-string concatenation (the "effective-text
approximation" paragraph in `docs/issue-10/reports/refactoring-legacy.md`
is historical record and stays as-is — README and gate-hooks.md are the
living docs that get edited). The dangling
`refactoring-legacy-progress-gate.sh` entry stays documented as a known,
separate open gap (unchanged from today) — see Out of scope.

## Consequences

- Positive: eliminates the four named audit defects; brings this
  rulebook's gates into `compliance-check.sh`-clean status; removes the
  `Bash`-tool blind spot entirely for these three gates; makes the
  semantic checks resistant to a single stray keyword satisfying a
  methodology requirement with no structural relationship to real content.
- Negative/residual: `test_run: PASS` is still a self-reported assertion
  the gate cannot independently execute-verify at write time — closed
  only at phase-2 verification (below), not by the gate itself. This is
  the same class of residual limitation `README.md`'s Doctrine section
  already states plainly for the issue-10 gates ("presence/ordering
  check against durable on-disk state, not a cryptographically or
  git-history-verified test-first guarantee") and this proposal keeps
  that framing rather than overclaiming.
- `Bash`-tool coverage denies rather than reconstructs — a legitimate
  `Bash`-based write to a gated path (there should be none under normal
  role usage, since the role's own tooling uses `Write`/`Edit`) is
  blocked outright with a clear reason, not silently passed or
  best-effort-approximated.
- Migrating onto `gate-lib.sh`/`gate-lib.py` creates a runtime dependency
  on `core` being installed at a resolvable path — already true today for
  `role-directive.sh` via the identical `CLAUDE_PLUGIN_ROOT_CORE`
  fallback pattern, so this is not a new class of dependency, only a
  second consumer of it.

## Out of scope

- Creating `refactoring-legacy-progress-gate.sh` (the dangling
  `hooks.json` `Bash` entry in the top-level `refactoring-legacy` plugin,
  separate from the three methodology-gate plugins this issue targets) —
  pre-existing, tracked in `docs/issue-10/reports/refactoring-legacy.md`'s
  Open findings; not named in the 2026-08-01 audit and not touched here.
- Re-architecting the plugin-per-methodology cut (Option C, rejected
  above).
- Actually executing the named `test_run:` command inside the
  `PreToolUse` gate itself (see Decision §4) — the gate checks the
  claim's presence/adjacency/shape; truthfully executing and confirming
  it is phase-2/CI verification work, not gate logic.
- Any change to `proposal-norm`/`characterization-tests`/`refactoring-steps`
  plugins' own methodology content (which elements are required at all) —
  this issue changes *how* those elements are checked (structurally, via
  the shared library), not *what* is required.
- Approving this proposal — phase 1 of this issue ends at PR submission;
  phase 2 (the actual gate migration, test suites, and README edits)
  opens only on an approvers.md Approve per contract v3 s19.

## Verification criteria (phase 2)

1. `bash core/hooks/tests/compliance-check.sh <plugin-dir>` reports zero
   violations for all three plugins.
2. Each plugin's own `run-gate-tests.sh` (extended with the six
   gate-house-standard mandatory cases) exits 0.
3. A manual/CI re-run of the `test_run:` command named in a sample
   `docs/issue-<n>/reports/refactoring-legacy.md` record produces an
   actual `PASS`, confirmed to match the record's claim, at least once
   during phase-2 delivery — demonstrating the field is not merely
   present but truthful in the delivered example.
4. A `Bash`-tool write attempt (e.g. `sed -i` against a gated path) in a
   fixture repo is denied (exit 2) by all three gates post-migration.
5. `README.md` and `docs/handbooks/gate-hooks.md` contain no reference to
   a file, path, or plugin that does not exist in the delivered tree
   (spot-checked the same way this proposal's survey §7 spot-checked the
   current README).
