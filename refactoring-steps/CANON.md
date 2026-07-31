# Canon: Fowler's Refactoring Catalog + Strangler Fig

Reference only. Source: Martin Fowler, *Refactoring: Improving the Design of
Existing Code*; catalog at refactoring.com/catalog.

## Catalog steps this repo expects records to cite

- Extract Method / Extract Function
- Rename Variable / Rename Method
- Inline Method / Inline Function
- Move Method / Move Function
- Extract Class
- Introduce Parameter Object
- Replace Conditional with Polymorphism
- Decompose Conditional

Cite the step by name in the phase-2 record (`docs/issue-<N>/reports/refactoring-legacy.md`),
plus a before/after equivalence note (English "equivalence" or Korean "동등성")
describing how behavior was confirmed unchanged.

## Strangler Fig (escape hatch for large structural migrations)

**Definition**: incrementally route behavior to a new structure behind a
stable seam, retiring the old path last (Fowler's strangler-fig application
writeup).

**When to use**: structural migrations too large to express as a single
catalog refactoring step above.

**Requirement**: any record invoking "strangler" must also name the stable
seam used — the interception point where traffic/calls are routed between
old and new. A strangler-fig record without a described seam is incomplete
and is denied by the methodology gate.
