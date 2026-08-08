# refactoring-legacy-rulebook

Rulebook for the `refactoring-legacy` role (contract v3 role-handoff protocol), split off
per `docs/issue-160/proposals/role-taxonomy.md`'s round-4 promotion and
generated as skeleton scaffolding by issue-167.

- **decides**: 기존 코드의 관찰 가능한 동작을 바꾸지 않고 안전하게 재구조화할 수 있는가
- **use_when**: 레거시/기존 코드에 손을 대야 할 때
- **produces**: characterization tests (written before any structural change),
  refactoring plan (small named steps), before/after behavior-equivalence note
  (evidence-citing) — see `## Doctrine` below for the full norm (issue #1)
- **write_scope**: ['src/**', 'test/**']
- **hand-off**: 신규 기능 구현이 섞이면 그 부분은 → implementation

## Doctrine (issue #1)

Adopted per `docs/issue-1/proposals/proposal.md` (Approved; see
`docs/issue-1/reports/refactoring-legacy.md` for the phase-2 record).

**Phase-1 proposal norm** — every proposal under this role must: reference a
current-state survey and a scout-brief (with a `Sources:` list); name its
adopted methodology and cite its origin rather than paraphrase it; show
options-considered vs. option-chosen in an ADR/RFC-shaped
context→options→decision→consequences form; state an explicit out-of-scope
section; and state phase-2 verification criteria.

**Phase-2 deliverable norm** — every deliverable this role produces must
contain: (1) a characterization test capturing the code's actual observed
behavior, written *before* any structural change (Feathers,
*Working Effectively with Legacy Code*); (2) a refactoring plan as a
sequence of small, independently-completable named refactorings, not one
monolithic rewrite step (Fowler, *Refactoring*); (3) a before/after
behavior-equivalence note that names which characterization tests were run
and confirms they pass identically before and after; (4) an explicit scope
boundary stating no behavior/feature change is bundled in — anything that
would change observable behavior is handed off to `implementation` instead.

**Mechanical enforcement (issue #10, gate-house A+ remediation issue #13)**:
the norms above are no longer review-only. Three independent plugins, one
per adopted methodology (cut by methodology, not by phase, per
`docs/issue-10/proposals/methodology-enforcement.md`), each self-contained
(own `plugin.json`, `hooks/methodology-gate.sh`, `hooks/hooks.json`,
`hooks/tests/run-gate-tests.sh`, own kill switch), registered in
`.claude-plugin/marketplace.json`. Each gate now sources core's shared
`gate-lib.sh`/`gate-lib.py` (core issue #72, reference-adopted per
`docs/issue-13/proposals/proposal.md` — never vendored) for trap-at-top
fail-closed, the fixed kill-switch convention (an unrecognized value stays
ACTIVE, not disabled), JSON-parse-or-deny, absolute/`./`-prefixed path
normalization, and full `Write`/`Edit`/`MultiEdit` reconstruction honoring
per-edit `replace_all`; the semantic content each gate checks (which
elements, which catalog terms) stays this rulebook's own logic:

- **`proposal-norm`** — gates every `docs/issue-<n>/proposals/*.md` write
  (`PreToolUse`/`Write|Edit|MultiEdit|Bash`, fail-closed) for the six
  required phase-1 elements listed above, checked structurally: each
  element must appear under a markdown heading matching a small alias set
  (or the top-level title's own front matter for survey/scout-brief/
  citation), not as a bare substring anywhere in the document; the ADR
  shape requires >=2 of Context/Options/Decision/Consequences as heading
  *titles*, not body mentions. Kill switch: `PROPOSAL_NORM_GATE_OFF=1`.
- **`characterization-tests`** — gates the phase-2 record
  (`docs/issue-<n>/reports/refactoring-legacy.md`, `Write|Edit|MultiEdit|Bash`)
  for characterization-test evidence and a heading naming the seam
  (Feathers) — not a bare "seam" mention — plus an adjacent (within 3
  lines) `characterization_tests_path:`/`test_run: PASS (<command>)` pair;
  the path must resolve (via `gate_normalize_path`) to a file that exists
  on disk and is non-empty. `test_run: PASS` is a self-reported assertion
  the gate cannot execute-verify at write time — see Verification criteria
  in `docs/issue-13/proposals/proposal.md` for the phase-2 check that
  re-runs it. Kill switch: `CHARACTERIZATION_TESTS_GATE_OFF=1`.
- **`refactoring-steps`** — gates the same record (`Write|Edit|MultiEdit|Bash`)
  for a named Fowler-catalog step as a list item under a "refactoring
  steps" heading (the bare word "catalog" alone no longer satisfies this —
  every other term names a specific, identifiable step) and a before/after
  equivalence note under an "equivalence" heading naming a concrete
  test-shaped identifier (plus a stable-seam requirement when a
  strangler-fig migration is named), and separately denies any `src/**`
  structural write (`Write|Edit|MultiEdit|Bash`) unless
  `characterization_tests_path` is already set in the record — the
  mechanism enforcing "characterize before refactor". Kill switch:
  `REFACTORING_STEPS_GATE_OFF=1`.

Each plugin is independently loadable/disable-able and owns exactly one
methodology; `refactoring-steps` reading `characterization-tests`'s record
field is a data dependency only, not shared code. A `Bash`-tool write
reaching an in-scope path (e.g. `sed -i`, `cat >`) is denied outright by
all three gates — such a write is opaque to reconstruction, so the gate
refuses rather than approximating its resulting content. Residual
limitation (unchanged from the original proposal): this is a
presence/structure check against durable on-disk state and a self-reported
`test_run:` claim, not a cryptographically or git-history-verified
test-first guarantee, and a `compliance-check.sh`-clean record is itself a
point-in-time claim against a specific core commit, not a standing
guarantee (issue #16); re-audits should re-run it against current core
`main` rather than trust an old record. The role-specific
`refactoring-legacy-progress-gate.sh` entry in `hooks.json` (previously
dangling — see Open findings in `docs/issue-10/reports/refactoring-legacy.md`)
now has real backing code (issue #16): it fails closed on missing core and
otherwise allows, since no per-step methodology check is designed for it
yet; `refactoring-legacy/hooks/tests/manifest-integrity-check.sh` is a
permanent regression guard that hard-fails if any plugin's `hooks.json`
ever again references a command file absent from disk.
Each plugin's `hooks/` directory passes
`core/hooks/tests/compliance-check.sh` clean.

**Spec field mapping (issue #20)** — the realized marketplace spec
`roles/specs/refactoring-legacy.spec.json` names four required deliverable
fields and a five-value `loop_state` vocabulary; both are layered onto the
methodology above under their literal spec names, never as a parallel
system:

- `refactoring_name` — the named Fowler-catalog step already required by
  `refactoring-steps` as a list item under a "refactoring steps" heading;
  the gate now also requires a `refactoring_name:` field in the same
  section naming that step.
- `motivation` — the *why* half of the record, grounded in Fowler's own
  catalog-entry shape (motivation precedes mechanics in every catalog
  entry this rulebook cites); required by `characterization-tests` as a
  `motivation:` field adjacent to the `characterization_tests_path:`/
  `test_run:` pair.
- `mechanics` — the applied step sequence, mapped onto the existing
  before/after equivalence note; required by `refactoring-steps` as a
  `mechanics:` field under the "equivalence" heading.
- `verdict` — the closed-enum (`pass`/`fail`) companion to the existing
  free-text `test_run: PASS (<command>)` line; required by
  `characterization-tests` alongside it. `test_run:` keeps the
  human-readable command evidence; `verdict:` supplies the spec's
  checkable enum.

`loop_state` (spec: `identifying`, `applying`, `landed`,
`motivation-undeclared`, `tests-unreachable`):

- `identifying` — characterizing the seam and capturing behavior, before
  any refactoring step is applied (progress state; no per-step gate check
  yet, unchanged from issue-13's Out-of-scope call).
- `applying` — a named catalog step is in progress, tests already
  captured (progress state; same open status as `identifying`).
- `landed` — the phase-2 record is complete: characterization evidence,
  `motivation:`, the applied step(s) with `refactoring_name:`,
  `mechanics:`, and `verdict:` all present and gate-passing.
- `motivation-undeclared` — refusal state: `characterization-tests` denies
  a write whose record has no `motivation:` field.
- `tests-unreachable` — error state: `characterization-tests` denies a
  write whose `characterization_tests_path` cannot be resolved to an
  existing, non-empty file — distinct from `verdict: fail`, which means
  the tests ran and failed.

## Install

This rulebook now references core canon (issue #2) instead of vendoring its
own copies of the warrant-hunt agent and the three role-agnostic gates.
Install `core` and `warrant` (plus `terse`, `freelunch`, `scout`) from the
`tokenmaxxxer-core` marketplace alongside this rulebook's own plugin:

```
claude plugin marketplace add tokenmaxxxer/refactoring-legacy-rulebook
claude plugin install refactoring-legacy
claude plugin install proposal-norm
claude plugin install characterization-tests
claude plugin install refactoring-steps

claude plugin marketplace add tokenmaxxxer/core
claude plugin install core
claude plugin install terse
claude plugin install freelunch
claude plugin install scout
claude plugin install warrant
```

## Layout

- `proposal-norm/`, `characterization-tests/`, `refactoring-steps/` — the
  three methodology-enforcement plugins (issue #10); see `## Doctrine`
  above for what each gates and their kill switches
- `refactoring-legacy/.claude-plugin/plugin.json` — plugin manifest
- `refactoring-legacy/hooks/hooks.json` — SessionStart + PreToolUse wiring;
  the `Bash`-matcher `refactoring-legacy-progress-gate.sh` entry now has
  real backing code (issue #16, see `## Doctrine` above); the three
  role-agnostic gates fire from core's own `core/hooks/hooks.json` for
  every plugin install
- `refactoring-legacy/hooks/tests/run-gate-tests.sh`,
  `refactoring-legacy/hooks/tests/manifest-integrity-check.sh` — tests for
  the progress gate plus the repo-wide ghost-command regression guard
  (issue #16)
- `refactoring-legacy/hooks/directive.sh` — SessionStart role directive, now a
  stub that sources core's `hooks/lib/role-directive.sh` and supplies only
  this role's four unique values
- `stub-check.sh` — no longer vendored here (issue #5, core canon #69). Run
  by reference against the core-installed copy instead:
  `"${CORE_PLUGIN_ROOT:-$CLAUDE_PLUGIN_ROOT/../core}"/hooks/tests/stub-check.sh refactoring-legacy`
- `docs/specs/approvers.md` — Approve-authority allowlist (see below)

The warrant-hunt agent (`agents/warrant-hunter.md`) and the three gates
(`trailer-gate.sh`, `record-fields-gate.sh`, `handbook-trigger-gate.sh`) are
no longer vendored here — see core canon (`core/agents` via the `warrant`
plugin, `core/hooks/*-gate.sh`) instead.

Doctrine detail is now filled in (`## Doctrine` above, issue #1); the
role-specific progress gate now has real (minimal) backing code (issue
#16) — full per-step progress-tracking methodology enforcement for it
remains open, unchanged from issue-13's Out-of-scope call.
