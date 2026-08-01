# Phase-2 record — issue #13 (refactoring-legacy)

loop_state: landed

## What was done

Implemented the Approved proposal (`docs/issue-13/proposals/proposal.md`,
`APPROVE issue-13/refactoring-legacy`, single-account mode): migrated all
three methodology-enforcement plugins (`proposal-norm`,
`characterization-tests`, `refactoring-steps`) onto core's gate-house
standard library and closed every defect the 2026-08-01 audit named.

1. **Reference-adopted `gate-lib.sh`/`gate-lib.py`** (core issue #72,
   landed at `tokenmaxxxer-core` PR #74) in all three
   `hooks/methodology-gate.sh` — never vendored. Each gate now calls
   `gate_trap_fail_closed` first, `gate_kill_switch_active` for its kill
   switch (unrecognized value stays ACTIVE — closes the fail-open bug),
   `gate_parse_json_or_deny` for malformed/empty/non-object payloads,
   `gate_normalize_path` for absolute/`./`-prefixed scope matching, and
   `gate_reconstruct_write` for real `Write`/`Edit`/`MultiEdit`
   reconstruction (honoring per-edit `replace_all`; deletions and
   multiply-occurring `old_string`s are now modeled instead of the old
   `existing + new_strings` concatenation).
2. **`Bash`-tool coverage** — each `hooks/hooks.json` matcher widened to
   `Write|Edit|MultiEdit|Bash`; each gate branches a `Bash` `tool_name` to
   `gate_bash_write_targets` token-scanning before the JSON payload is
   parsed, and denies outright (not reconstructed) if any candidate token
   falls in the gate's own scope. Closes the `sed`/`cat >` bypass the audit
   named.
3. **Section/adjacency/structure semantic checks**, replacing every bare
   substring-anywhere match:
   - `proposal-norm`: each of the six required elements must appear under a
     heading matching a small alias set (survey/basis/근거, scout,
     methodology/citation) or in the document's top-level title body
     (where a proposal's opening Basis line conventionally lives); the ADR
     shape now requires >=2 of Context/Options/Decision/Consequences as
     heading *titles*, not body mentions anywhere; out-of-scope and
     verification-criteria each require their own heading.
   - `characterization-tests`: requires a heading naming the seam (not a
     bare "seam" mention); requires `characterization_tests_path:` and a
     new `test_run: <PASS|FAIL> (<command>)` field to sit within 3 lines of
     each other; requires the path to resolve to a file that exists on
     disk and is non-empty (closes defect 4's existence half); denies
     unless `test_run` asserts `PASS`.
   - `refactoring-steps`: requires a catalog step as a markdown list item
     under a "refactoring steps" heading, with the bare word "catalog"
     dropped from the accepted term list (closes the audit's named
     "'catalog' word passes" finding — every remaining term already names
     a specific, identifiable step); requires the equivalence note under
     an "equivalence"/동등성 heading naming a concrete test-shaped
     identifier; keeps the existing strangler-without-seam sub-check.
4. **Characterization-test pass verification** — the new adjacent
   `test_run:` field requires the author to assert a specific run result
   rather than a free-floating "characterization test" substring; a
   phase-2 human/CI re-run confirms the claim (see Verification criteria
   below), which the gate itself cannot execute-verify at write time.
5. **Test suites extended** to the six gate-house-standard mandatory cases
   (`Edit`+`replace_all:true` on a multiply-occurring `old_string`,
   `MultiEdit` mixed `replace_all`, malformed JSON [truncated/non-object/
   empty], kill-switch-set-to-unrecognized-value-stays-active, absolute +
   `./`-prefixed `file_path`, a `Bash`-tool write reaching the same
   target), plus cases proving each closed loophole (bare "catalog"/"seam"
   word no longer passes, non-adjacent path/test_run fields deny, a
   nonexistent characterization-tests path denies). All existing passing
   cases were kept (rewritten only where the new structural requirement
   changed the fixture shape — e.g. plain sentences became headinged
   records). Full suite green:
   - `proposal-norm/hooks/tests/run-gate-tests.sh`: 19/19 passed
   - `characterization-tests/hooks/tests/run-gate-tests.sh`: 18/18 passed
   - `refactoring-steps/hooks/tests/run-gate-tests.sh`: 22/22 passed
6. **README.md and `docs/handbooks/gate-hooks.md` realigned** with the
   `gate-lib` migration, the widened `Write|Edit|MultiEdit|Bash` matcher,
   the new `test_run:` field, and the structural (not substring) semantic
   checks; no reference to a nonexistent file/path/plugin remains (spot
   -checked the same files the proposal's survey §7 spot-checked).

## Why

The 2026-08-01 audit graded this rulebook's three methodology gates B-,
naming four defect classes (unreal reconstruction, a `Bash` bypass, bare
substring semantic checks, an unverified `characterization_tests_path`)
that let a proposal or record satisfy a methodology requirement with no
real structural or behavioral relationship to the content the gate exists
to check. Issue #13 asked for A+ across every axis and set a precondition:
core issue #72 landed a shared gate-house library codifying fixes for
structurally the same defect classes across core's own seven gates and 43
downstream rulebooks — reference-adopt it rather than re-deriving a local
version of the same shapes.

## Upstream basis

- `docs/issue-13/proposals/proposal.md` (this role's own Approved
  proposal), citing `docs/issue-13/reports/refactoring-legacy/survey.md`
  (defect map) and `docs/issue-13/reports/refactoring-legacy/scout-brief.md`
  (core's landed gate-house standard).
- `tokenmaxxxer-core` issue #72 / PR #74 (`hooks/lib/gate-lib.sh`,
  `hooks/lib/gate-lib.py`, `hooks/tests/compliance-check.sh`), merged to
  `main` 2026-08-01.
- `docs/issue-10/reports/refactoring-legacy.md` (the original three-plugin
  build this issue remediates).

## Characterization

characterization_tests_path: characterization-tests/hooks/tests/run-gate-tests.sh
test_run: PASS (bash characterization-tests/hooks/tests/run-gate-tests.sh)

## Refactoring steps

- Extract Method: split each `methodology-gate.sh`'s inline substring
  checks into heading/section-anchored structural checks (`under_alias`,
  `section_text` helpers) while keeping the gate's fail-closed shell
  wrapper unchanged in shape.
- Rename/Inline: replaced each gate's own ad hoc kill-switch
  `case`/JSON-`try`/`existing + new_text` blocks with direct
  `gate_lib.gate_kill_switch_active` / `gate_parse_json_or_deny` /
  `gate_reconstruct_write` calls (Fowler's catalog, applied against the
  already-landed `gate-lib.py` rather than re-derived).

## Equivalence

Before (issue-10 build) vs. after (this migration): every case that passed
under the old substring/regex checks in `proposal-norm`, `characterization
-tests`, and `refactoring-steps`'s original `run-gate-tests.sh` suites
still passes under the rewritten fixtures verifying the same intent
(structurally reshaped where the new heading/adjacency requirement changed
what "present" means — e.g. `docs/issue-42/reports/refactoring-legacy.md`
in `refactoring-steps`'s suite). No previously-denied case now allows; the
three additive loophole-closure cases (bare "catalog"/"seam" word, non-
adjacent fields, nonexistent test path) prove the new structural checks
reject inputs the old substring checks would have passed. Full run:
`proposal-norm` 19/19, `characterization-tests` 18/18, `refactoring-steps`
22/22 — see `## What was done` item 5.

## Verification criteria (phase-2, per the proposal)

1. `bash core/hooks/tests/compliance-check.sh <plugin-dir>` reports zero
   violations for all three plugins — confirmed clean against a local
   checkout of `tokenmaxxxer-core` `main` (PR #74, merged 2026-08-01):
   `compliance-check: ok — proposal-norm/hooks/methodology-gate.sh`,
   `compliance-check: ok — characterization-tests/hooks/methodology-gate.sh`,
   `compliance-check: ok — refactoring-steps/hooks/methodology-gate.sh`.
2. Each plugin's own `run-gate-tests.sh` exits 0 — confirmed (19/19,
   18/18, 22/22 above).
3. A re-run of the `test_run:` command named above
   (`bash characterization-tests/hooks/tests/run-gate-tests.sh`) produced
   an actual `Total: 18, Failed: 0` (all `PASS`), confirmed to match this
   record's `test_run: PASS` claim.
4. A `Bash`-tool write attempt (`sed -i`/`cat >` shaped) in a fixture repo
   is denied (exit 2) by all three gates post-migration — covered by each
   suite's "Bash-tool write ... is denied" case (see item 5 above).
5. `README.md` and `docs/handbooks/gate-hooks.md` were re-read after
   editing; both name only files/paths/plugins that exist in the delivered
   tree (the pre-existing, still-open `refactoring-legacy-progress-gate.sh`
   gap stays documented as a known gap, unchanged, per the proposal's Out
   of scope).

## Open findings

None new. The pre-existing, out-of-scope gap
(`refactoring-legacy-progress-gate.sh` dangling in
`refactoring-legacy/hooks/hooks.json`) remains open, tracked in
`docs/issue-10/reports/refactoring-legacy.md`'s Open findings — not named
in the 2026-08-01 audit and not touched by this issue, per the proposal's
Out of scope section.
