# Issue #10 — Phase 1 proposal: mechanically enforcing the issue-1 methodology norms

Status: proposal only — not executed, not approved. **Phase 1 ONLY per the
invoking prompt: this PR stops at the proposal; no `Approve` is solicited
or assumed, and no code below is implemented in this PR.**

## Context

Issue-1 (Approved, `docs/issue-1/proposals/proposal.md`) established this
role's methodology doctrine — a phase-1 proposal norm (six required
elements) and a phase-2 deliverable norm (four required components) — and
reflected it into `directive.sh`'s `PRODUCES` string and `README.md`'s
`## Doctrine` section. Issue-1 phase 2 explicitly stopped there, naming an
"Enforcement gap": nothing mechanically checks that a proposal or record
actually contains the required elements, and the `refactoring-legacy-
progress-gate.sh` slot wired in `hooks.json` has never had a file behind
it. Issue #10 asks this repo to close that gap to the standard
`implementation-rulebook` already demonstrates: directive depth, a
methodology gate that machine-verifies required `produces` elements
(state-tracked where the methodology has an ordering constraint), gate
tests, and agents/checklists if the methodology implies a repeated
procedure. The current-state survey is at
`docs/issue-10/reports/refactoring-legacy/survey.md`; the scout sweep
grounding the design below is at
`docs/issue-10/reports/refactoring-legacy/scout-brief.md`.

## (a) Directive deepening

`directive.sh` currently supplies four unstructured strings via
`core_role_directive`. This proposal adopts extending each facet to name
concrete steps, judgment criteria, and prohibitions, per issue #10's ask
that a one-line summary is insufficient:

- **`YOU DECIDE`** (unchanged in substance, sharpened in framing): the
  judgment call is factual/technical ("does this transformation preserve
  observable behavior"), not a preference — the directive should state
  the test for this explicitly: *if the change could be described without
  the word "still," it is not a refactor.*
- **`PRODUCES`** — deepen from the current three-noun-with-parenthetical
  form into an ordered procedure the directive states outright:
  (1) capture behavior first (characterization test, Feathers) — **before**
  touching structure; (2) decompose into small named steps (Fowler),
  each independently completable and independently leaving the system
  working; (3) run the captured tests after every step, not only at the
  end; (4) write the equivalence note citing which tests ran and passed
  identically pre/post. **Prohibition, stated explicitly in the
  directive**: no step may bundle an observable-behavior change; any such
  change discovered mid-work is handed off, not folded in.
- **`HAND-OFF`** — deepen from the bare "→ implementation" into the
  judgment criterion for *when* to hand off: the moment any step under
  consideration would make a previously-passing characterization test
  fail *by design* (not by bug) rather than *by accident* — the former is
  a feature change misfiled as refactoring, the latter is a regression to
  fix within the same step.
- **`USE_WHEN`** — unchanged; already sufficiently concrete for a
  four-string directive facet.

Mechanically, this proposal defers the exact rendering to phase 2, since
(mirroring issue-1's own finding) whether `core_role_directive`'s call
shape accepts a longer structured value or needs a parallel field requires
checking `core/hooks/lib/role-directive.sh` at phase-2 time — not
guessed here.

## (b) Methodology gate — machine-verifying issue-1's required elements

**Design, adapted from the scouted `pricing-rulebook/pricing/hooks/
methodology-gate.sh` shape (see scout-brief "Adopt/skip") — referenced for
its structural pattern only, not copied; the concrete regex/keyword logic
below is derived fresh for this role's own required elements, per the
canon-reference-only constraint.**

A new `refactoring-legacy/hooks/methodology-gate.sh`, wired to
`PreToolUse`/`Write|Edit|MultiEdit` in `hooks.json` (replacing the dangling
`refactoring-legacy-progress-gate.sh` entry, or added alongside it,
pending what phase 2 finds the entry was originally meant to be — see Out
of scope), would:

1. **Scope by path regex** to this role's own write surfaces only:
   `docs/issue-<n>/proposals/.*refactoring.*\.md` (phase-1 proposals) and
   `docs/issue-<n>/reports/refactoring-legacy\.md` (phase-2 record) — a
   no-op `exit 0` for every other write, per must-be 2.
2. **Resolve resulting content** for `Write`/`Edit`/`MultiEdit` exactly as
   the scouted pattern does (substitute `old_string`→`new_string` against
   current file content; deny with a clear message if the resulting
   content cannot be determined) — per must-be 3.
3. **Check required elements, fail-closed** (`exit 2` on any missing
   element, `exit 0` only when all required elements for that document
   type are present):
   - On a **proposal** write: presence of a survey reference
     (`reports/refactoring-legacy/survey.md` or equivalent path mention),
     a scout-brief reference *with* a `Sources:` list (or an explicit,
     stated skip-record per the scout-directive's own skip-condition
     rule), a named methodology + citation (author/work — e.g.
     "Fowler"/"Feathers" or another named source), an options-vs-decision
     structure (headings or prose containing both "considered" and
     "chosen"/"adopted" language), an explicit "Out of scope" section, and
     phase-2 verification criteria language.
   - On a **record** (phase-2 deliverable) write: presence of the three
     issue-1 (b) components by name/content —
     characterization-test evidence (a test file path or explicit
     "characterization test" mention), a refactoring plan expressed as an
     enumerated/named sequence (not a single paragraph — checked
     structurally, e.g. requiring at least two distinguishable named
     steps), and a before/after equivalence note that names which tests
     ran and states they passed both before and after.
4. **Fail closed on internal error** — wrap the check in a trap/exception
   handler that denies (`exit 2`) rather than allows on any unexpected
   script failure, per must-be 1.
5. **Kill switch**: `REFACTORING_LEGACY_METHODOLOGY_GATE_OFF=1`, per
   must-be 5.

### State tracking for the one real ordering constraint

Issue-1's doctrine states characterization tests must exist **before**
any structural change — an ordering constraint a single stateless
PreToolUse invocation cannot verify by itself. Per the scouted durable-
state precedent (`coding-progress-gate.sh` inspecting another role's
record file's `loop_state` at commit time, rather than the hook
remembering anything across invocations), this proposal adopts:

- A required record field, `characterization_tests_path`, written into
  the phase-2 record the first time a characterization test is captured
  — the record itself *is* the durable state marker, no separate state
  file needed.
- A **second gate** (or an added check inside the same
  `methodology-gate.sh`), scoped to `Write|Edit` under this role's
  `write_scope` (`src/**`, `test/**`), that denies a structural edit under
  `src/**` unless the current record
  (`docs/issue-<n>/reports/refactoring-legacy.md`) already contains a
  non-empty `characterization_tests_path` field. This operationalizes
  test-first as: *the record must already claim a captured test before
  the gate allows touching the source it protects* — a presence/ordering
  check against durable on-disk state, not a git-history-timestamp
  archaeology attempt (which issue-1 already flagged as likely
  infeasible, and which this proposal does not re-attempt).
- This is honestly weaker than a cryptographic guarantee that the test was
  genuinely written and run first (an author could write a hollow
  `characterization_tests_path` value before writing the actual test) —
  stated explicitly as a residual limitation, not silently glossed over.

## (c) Gate tests

Per the scouted `implementation-rulebook` pattern
(`tests/run-gate-tests.sh`, `deny-only-check.sh`, `parse-check.sh`), a new
`tests/run-gate-tests.sh` at this repo's root would exercise
`methodology-gate.sh` as a real subprocess: spin up a throwaway `git init`
repo per case, pipe a synthetic `{"tool_name":"Write","tool_input":
{"file_path":...,"content":...}}` payload on stdin, assert exit code
0 (allow) vs. 2 (deny). Planned cases:

- Proposal write with all six required elements present → allow.
- Proposal write missing the scout-brief `Sources:` list → deny.
- Proposal write missing a named methodology citation → deny.
- Record write with all three deliverable components present → allow.
- Record write with an empty/missing `characterization_tests_path` →
  deny.
- Record write whose refactoring plan is a single undifferentiated
  paragraph (no distinguishable named steps) → deny.
- A write to an unrelated path (e.g. another role's record) → allow
  (no-op scope check — must not fire outside this role's surfaces).
- A structural edit under `src/**` attempted before
  `characterization_tests_path` is recorded → deny (ordering gate).
- Same edit attempted after the field is present → allow.

## (d) Agents / checklist

Issue-1's deliverable norm implies one repeated procedure: capture →
decompose → (step, re-test)×N → equivalence note. This proposal adopts a
**checklist file** (`refactoring-legacy/CHECKLIST.md` or an equivalent
doc under this role's own tree), not a full agent definition — the
procedure is a linear sequence with no branching judgment beyond what the
directive already states, so a checklist is proportionate; introducing a
subagent for a four-step linear procedure would be scope beyond what the
methodology actually requires (per the "don't build more than the task
needs" default). The checklist would enumerate exactly the four
`PRODUCES` steps from (a) above as literal checkable items, so an
executing session (or a reviewer) can tick through them without
re-deriving the sequence from prose each time.

## Out of scope

- Implementing `methodology-gate.sh`, the second ordering gate,
  `tests/run-gate-tests.sh`, `CHECKLIST.md`, or any `hooks.json`/
  `directive.sh` edit — all deferred to phase 2 pending Approve, per the
  invoking prompt's explicit phase-1-only instruction.
- Resolving what the long-dangling `refactoring-legacy-progress-gate.sh`
  `hooks.json` entry was originally meant to contain, or whether phase 2
  should rename/replace it vs. add a second entry — a phase-2 investigation
  (git blame / issue history on that entry, not repeated here since no
  new information was found beyond issue-1/2/5's identical prior flag).
- A cryptographically or git-history-verified test-first ordering
  guarantee — explicitly not attempted, per (b)'s stated residual
  limitation and issue-1's own prior finding that this is likely
  infeasible with the tooling available.
- Any change to `core`'s `record-fields-gate.sh`, `role-directive.sh`, or
  its per-role contract table — this proposal builds a local, role-scoped
  gate entirely within this rulebook, exactly per the constraint that
  canon scripts are referenced, never copied or modified.
- `docs/specs/approvers.md` — untouched.
- Re-litigating issue-1's adopted doctrine content itself — this proposal
  is purely mechanical enforcement of what issue-1 already decided, not a
  re-derivation of the methodology.

## Phase-2 verification criteria

Once Approved, phase 2 should be verifiable by: (1) `tests/
run-gate-tests.sh` exists at repo root and exits 0 (all cases pass) when
run directly; (2) a proposal or record write missing a required element,
attempted live in a session, is observably denied (exit 2 surfaces as a
blocked tool call); (3) `directive.sh`'s rendered `SessionStart` output
visibly contains the deepened per-facet content from (a), confirmed by
reading the actual rendered directive text (not just the source
strings) if `core_role_directive`'s call shape supports it; (4)
`README.md`'s `## Doctrine` section is updated to replace the
"Enforcement gap, stated plainly" paragraph with an accurate description
of what is now mechanically enforced vs. any residual gap that remains
(per (b)'s stated limitation on ordering guarantees).

## References

- `docs/issue-10/reports/refactoring-legacy/survey.md`
- `docs/issue-10/reports/refactoring-legacy/scout-brief.md`
- `docs/issue-1/proposals/proposal.md` (adopted doctrine this proposal
  enforces)
- `docs/issue-1/reports/refactoring-legacy.md` (phase-2 record naming the
  enforcement gap this proposal closes)
