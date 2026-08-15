---
axis: characterization-test-scope
rule_count_floor: 5
---

# Characterization test scope

Research trail: Michael Feathers' characterization-test definition (Wikipedia's summary of *Working Effectively with Legacy Code*), golden-master testing write-ups (Chris Melinn; Fabrizio Duroni/chicio; Blexin) that operationalize "how much to capture," and understandlegacycode.com's comparison of characterization vs. approval vs. regression tests. Academic layer: none independently found for this axis beyond the practitioner canon above — flagged as an open gap below, same pattern the observability/technical-writing exemplars already recorded for their own thin-academic axes.

## Rules

1. When writing a characterization test, assert on the actual observed output of a run, not on what the output "should" be — the test documents current behavior, bugs included, so a passing characterization test proves nothing about correctness, only that behavior has not changed since the test was written. source: https://en.wikipedia.org/wiki/Characterization_test

2. When the code under test produces a complex structured result (PDF, XML, image, large object graph) where field-by-field assertions would be unreadable or incomplete, use golden-master testing (snapshot the whole output, diff future runs against the saved snapshot) rather than writing many individual assertions — this captures the full behavior instead of only the fields the author remembered to check. source: https://chicio.medium.com/golden-master-testing-aka-characterization-test-a-powerful-tool-to-win-your-fight-against-legacy-1ca590f219a1

3. When selecting inputs for a characterization test, generate a large, diverse input set (edge cases, boundary values, and realistic production-like samples) rather than one or two happy-path examples — the safety net's coverage is only as wide as the input set, so a narrow set leaves the exact regressions a refactor is likely to introduce unguarded. source: https://en.wikipedia.org/wiki/Characterization_test

4. When deciding whether characterization tests are "done" for a unit before starting structural change, stop adding tests once new inputs stop producing new observed behaviors (coverage has plateaued) rather than at a fixed test count — an arbitrary count target either under-covers a wide-behavior function or wastes effort re-confirming behavior already pinned down. source: https://cloudamite.com/characterization-testing/

5. When legacy code has an obvious defect visible during characterization, record the defect as a known, cited discrepancy (e.g., a comment or a separately tracked issue) instead of silently "fixing" it inside the characterization test — changing the assertion to the "correct" value turns the safety net into a feature change with no independent verification, which characterization testing exists specifically to avoid. source: https://understandlegacycode.com/blog/characterization-tests-or-approval-tests/

6. **REMOVAL**: When the unit under test has dead branches that a diverse input sweep never reaches, do not write characterization tests to force coverage of unreachable code — pin down only the behavior the sweep actually observes, and let unreached branches surface for later dead-code removal instead of being certified as "intended behavior" by an artificial test. source: https://hackernoon.com/refactoring-021-remove-dead-code

7. After capturing a characterization test, deliberately mutate the code under test to produce a different observed output, then confirm the test fails against that mutation before trusting it as a safety net — a captured test that merely runs without ever being observed to fail proves only that it executes, not that it actually pins the behavior it claims to guard.

## Open findings

- No distinct academic/theory-layer source was located for characterization-test scope specifically (as opposed to testing methodology generally); the searches run this session surfaced only practitioner blogs and the Feathers/Fowler canon. A later pass should search software-testing-effectiveness literature (e.g. mutation-testing coverage studies) for an independent academic anchor.
