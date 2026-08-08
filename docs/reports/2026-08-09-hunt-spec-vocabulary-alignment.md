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
