---
proposal: docs/issue-20/proposals/spec-vocabulary-alignment.md
---

# Hunt record — spec-vocabulary-alignment


## after-proposal — stance 0: assume the gate just touched is bypassable — find the bypass

Verdict: FINDING — `characterization-tests/hooks/methodology-gate.sh`'s structural check is decoupled: the "characterization test" evidence text, the "seam" heading, and the `characterization_tests_path:`/`test_run: PASS` pair are checked independently with no requirement that they refer to the same content, so a record can pass with a fabricated/unrelated evidence file — and the proposal's step 3 misdescribes this check as "characterization-test heading + adjacent ... pair" (there is no such heading requirement; `has_evidence` only requires the phrase anywhere in the body, and `has_seam_heading` only requires any heading containing "seam" anywhere in the doc, unrelated to the evidence pair). Layering `motivation:`/`verdict:` fields "adjacent to that pair" per the proposal's plan does not close this: the pair itself need not correspond to anything real.
Kind: composition
Seed: docs/issue-20/proposals/spec-vocabulary-alignment.md (phase-1, all-docs); reproduction against characterization-tests/hooks/methodology-gate.sh, the gate the proposal describes and plans to extend
cap_seconds: 60
tier: default
diff_stat_lines: 3 new files under docs/issue-20/ (docs-only)
started_at: 2026-08-09T00:00:00Z
ended_at: 2026-08-09T00:15:00Z

### Reproduce
```
cat > /tmp/reprogate/docs/issue-20/reports/refactoring-legacy.md payload (via tool_input.content):
## Seam
This document mentions characterization test somewhere unrelated to real evidence.

## Unrelated
characterization_tests_path: tests/evidence.txt
test_run: PASS (echo ok)

# tests/evidence.txt contains only: "dummy evidence"
CLAUDE_PLUGIN_ROOT_CORE=/home/jwjung/tokenmaxxxer-core/core \
  bash characterization-tests/hooks/methodology-gate.sh < payload.json
echo EXIT=$?
```

### Observed
`EXIT=0` — the gate accepts the write. The "Seam" heading has no bearing on
any real seam, the "characterization test" mention is an unrelated aside, and
`characterization_tests_path` points at a placeholder file ("dummy evidence")
with `test_run: PASS (echo ok)` naming a command (`echo ok`) that never ran
any test at all.

### Expected
The gate's own doc comment says it "mechanically enforces
characterization-testing methodology"; a record whose narrative evidence,
seam heading, and PASS claim are mutually unrelated and backed by a
placeholder file should be denied, not accepted as methodologically sound.
The proposal, in describing this as "characterization-test heading +
adjacent ... pair" and planning to bolt `motivation:`/`verdict:` onto the
same disconnected pair, inherits and extends the gap rather than closing it.

## before-landing — stance 3: assume the rule as written cannot hold — find the state nothing maintains

Verdict: FINDING — the new unconditional `break` after the first "equivalence"-titled heading in refactoring-steps/hooks/methodology-gate.sh makes has_equivalence/has_mechanics evaluation stop at the first matching heading, so a record whose first Equivalence section lacks a concrete test reference is denied even when a second Equivalence section further down has both the test reference and the mechanics: field — a record the pre-change gate accepted.
Kind: design-error
Seed: git diff (working tree vs HEAD) of refactoring-steps/hooks/methodology-gate.sh — the equivalence-heading loop changed from `if equiv_heading_re.search(title): if test_ref_re.search(...): has_equivalence = True; break` (break only on success) to a version where `break` sits outside the inner `if`, so it fires on the first heading match regardless of whether that section satisfied has_equivalence/has_mechanics.
cap_seconds: 120
tier: default
diff_stat_lines: ~180 across 6 files
started_at: 2026-08-09T00:00:00Z
ended_at: 2026-08-09T00:20:00Z

### Reproduce
```
d=<scratch dir>
cat > "$d/content.md" <<'MD'
## Refactoring steps
- Applied Extract Method to the function.

refactoring_name: Extract Method

## Equivalence
Confirmed equivalence, no evidence given here.

## Equivalence (detail)
Confirmed behavioral equivalence via test/foo_test.py.

mechanics: extracted the block into a new function and replaced the call site.
MD
python3 -c "
import json
print(json.dumps({'tool_name':'Write','tool_input':{'file_path':'docs/issue-42/reports/refactoring-legacy.md','content':open('$d/content.md').read()},'cwd':'$d'}))
" > "$d/event.json"

# current (post-diff) gate:
./refactoring-steps/hooks/methodology-gate.sh < "$d/event.json"

# pre-diff gate (git show HEAD:refactoring-steps/hooks/methodology-gate.sh):
git show HEAD:refactoring-steps/hooks/methodology-gate.sh > "$d/old-gate.sh" && chmod +x "$d/old-gate.sh"
"$d/old-gate.sh" < "$d/event.json"
```

### Observed
Current working-tree gate: exit 2, `DENY — ... no before/after equivalence note found under an "equivalence"/동등성 heading naming a concrete test ...; no mechanics: field under the "equivalence" heading ...` — even though the second "## Equivalence (detail)" heading in the same document contains both a concrete test reference (test/foo_test.py) and a valid `mechanics:` field.

Pre-diff gate (HEAD, `git show HEAD:...`): exit 0, no output — the record is accepted.

### Expected
The gate's own inline comment/original logic implies it should scan headings until it finds one that satisfies the requirement (as it did before this diff — `break` was inside the success branch). A record that has repeated or two-part Equivalence sections, one of which fully satisfies the requirement, should not be denied just because an earlier section under the same heading pattern was incomplete.
