---
axis: refactoring-step-decomposition
rule_count_floor: 5
---

# Refactoring step decomposition

Research trail: Martin Fowler, Kent Beck et al., *Refactoring: Improving the Design of Existing Code* (the catalog and its test-small-change-test rhythm), understandlegacycode.com's summary of the catalog's key points, and freeCodeCamp/Sourcegraph practitioner guides that restate the small-step discipline for legacy codebases specifically.

## Rules

1. When a structural improvement can be reached by more than one catalog refactoring, pick the smallest individually-named one that makes progress (e.g. Extract Function before Extract Class) rather than a larger compound change — each catalog entry is deliberately sized to be "too small to be worth doing" on its own, and the safety of the technique comes from that granularity, not from the destination design. source: https://understandlegacycode.com/blog/key-points-of-refactoring/

2. When applying any catalog step, run the full test suite immediately after that one step, before starting the next step — the test-small-change-test rhythm is the mechanism that makes refactoring fast and safe; skipping a test cycle to batch several steps removes the ability to localize a regression to the step that caused it. source: https://www.mybookadvisor.com/books/refactoring-martin-fowler

3. When a single catalog step (e.g. Extract Function) would still require touching more than one clearly separable concern to compile, split it further along those concerns rather than accepting a larger diff — the catalog's guidance is that each transformation should leave the system compiling and passing tests, which is only guaranteed when the step is minimal enough to be mechanically checkable. source: https://silab.fon.bg.ac.rs/wp-content/uploads/2016/10/Refactoring-Improving-the-Design-of-Existing-Code-Addison-Wesley-Professional-1999.pdf

4. When deciding what to refactor first in a legacy area with many candidate improvements, prioritize the code path with the highest change frequency or highest defect risk over the path that looks structurally worst — the catalog's guidance is to refactor where you are about to work anyway ("opportunistic refactoring"), not to schedule a general cleanup pass. source: https://www.freecodecamp.org/news/how-to-refactor-complex-codebases

5. When a planned refactoring step would also change what the code does (not just its structure), stop and treat it as a feature change, not a refactoring step — the catalog's definition of refactoring is explicitly behavior-preserving; a step that a reviewer could not describe without the word "still" (i.e., the observable output changes) is out of the catalog's scope and needs its own motivation and its own tests. source: https://www.mybookadvisor.com/books/refactoring-martin-fowler

6. **REMOVAL**: When a legacy method contains duplicated logic that a catalog step (e.g. Extract Function, then Inline Function on the duplicate) can collapse into one call site, prefer removing the duplicate over parameterizing it in place — the catalog frames duplication removal as one of the primary refactoring motivations, and collapsing to one implementation reduces the surface later characterization/refactoring work has to cover, rather than adding conditional parameters that grow it. source: https://sourcegraph.com/blog/code-refactoring-techniques

7. When several legacy components are candidates to refactor or migrate first, score each on business criticality, existing test coverage, coupling to other components, and team familiarity, and let that combined score — not change frequency alone — set the order; a component touched often but already well-tested and loosely coupled is a lower real risk than a rarely-touched component with thin coverage and dense coupling, which change-frequency-only prioritization would miss.
