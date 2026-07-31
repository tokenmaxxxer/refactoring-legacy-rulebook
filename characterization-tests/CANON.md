# Canon: Seams and Characterization Tests

## Seam

A seam is a place in the code where you can alter behavior without editing
the code in that place. Seams are the entry points legacy code offers (or can
be given) for inserting tests around behavior that has no tests, without
first doing a large, risky rewrite. Every seam has an "enabling point" — the
place where you choose which behavior runs (e.g. a call site, a link
configuration, a build flag).

## Seam catalog (relevant to this repo)

**Object seam.** In object-oriented languages, the object seam is a
substitution point created by polymorphism: a method call goes through an
interface, base class, or injected dependency, so a test can supply a
different implementation (a fake, stub, or subclass) at the enabling point.
This applies whenever the language has interfaces/abstract classes and the
production code depends on an abstraction rather than a concrete type —
typically via constructor or setter dependency injection.

**Link seam.** In statically linked or compiled languages, the link seam
lets you substitute an entire compiled unit (a library, object file, or
module) at build or link time, without touching the calling code's source.
This applies when a language/toolchain resolves symbols at compile or link
time and test builds can be configured to link against a different
implementation of a dependency than production builds do.

**Preprocessing seam.** In languages with a preprocessor or another
build-time text-substitution mechanism, the preprocessing seam lets you swap
code before compilation — for example via macros or conditional compilation
directives. This applies when the enabling point is a preprocessor directive
that selects between two bodies of code depending on a build-time flag.

## Characterization tests

A characterization test documents the actual current behavior of a piece of
legacy code, rather than the intended behavior. It is written by exercising
the code, observing what it does, and asserting that behavior — used to
detect any behavior change during refactoring, not to validate correctness.
Introducing a characterization test around code that has no seam usually
requires finding or creating one first.

## Citation

Michael Feathers, "Working Effectively with Legacy Code" (2004), chapter on
seams.
