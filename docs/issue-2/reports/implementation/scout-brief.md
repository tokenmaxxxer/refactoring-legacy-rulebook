# Scout brief — issue-2

Category: internal engineering conformance (rulebook-to-canon reference
conversion), not a product-facing surface — no external market/competitor
angle applies. Best-in-class comparable here is the org's own canon rollout
(core issue-63/66) and its one existing per-rulebook attempt
(implementation-rulebook), read directly rather than web-searched (private
GitHub org, not indexable). Mode: batched-sequential (single coherent
internal target — `gh repo clone` core + implementation-rulebook, then read),
not parallel fan-out; stated per the fallback-disclosure rule. 1 stage used
(saturated after reading core canon + the one sibling attempt — a second
sibling rulebook would not change the target shape, since core's own files
are the authoritative spec regardless of how many siblings converted).

## Must-bes (from core's canon + stub-check.sh, load-bearing not optional)

- Vendored copies of `trailer-gate.sh`, `record-fields-gate.sh`,
  `handbook-trigger-gate.sh` must be deleted, not edited-down — their mere
  presence under `hooks/` at depth ≤3 is what `stub-check.sh` fails on.
- `directive.sh` must reduce to exactly: shebang, one source line resolving
  core's `hooks/lib/role-directive.sh`, plain var assignments, one
  `core_role_directive` call — `stub-check.sh` fails any other line shape
  (case statements, raw `cat`, guards regrown locally).
- `agents/warrant-hunter.md` and its `hunt-guard.sh`/`hunt-state.sh` pairing
  are superseded by installing the `warrant` core plugin — not converted to a
  stub file (core's `warrant/` plugin ships the agent + guards as a unit;
  there is no "warrant-hunter stub" shape in core's own tree).
- A role whose terminal `loop_state` set differs from the `landed` default
  sets `RECORD_FIELDS_TERMINAL_STATES` explicitly, in its own `hooks.json`
  `env` — silence here is a silent regression to `landed`-only per core's own
  issue-66 finding.
- `stub-check.sh` itself is a per-rulebook artifact core expects copied in
  (same distribution model as `parse-check.sh`), run from the rulebook's own
  test harness — passing it is a gate, not a suggestion (issue task 5).

## Gap line (what this rulebook already meets vs. misses)

Meets: nothing — all four gate/agent copies are still vendored in full, and
`directive.sh` is still the pre-stub standalone shape. Misses: all five of
the must-bes above. This repo is exactly the "43x mechanical edit" core's
issue-66 record describes as tracked-but-not-yet-executed per-rulebook
follow-up; issue-2 is that follow-up for this one rulebook.

## Adopt / skip

- Adopt: core's exact stub shape for `directive.sh` (source `role-directive.sh`
  + four values), since `stub-check.sh` enforces it structurally and a
  hand-rolled variant fails CI.
- Adopt: `RECORD_FIELDS_TERMINAL_STATES` override only if evidence of a real
  role-specific terminal state exists — none found for `refactoring-legacy`
  (its record has no documented non-`landed` terminal point; see proposal's
  open question).
- Skip: implementation-rulebook's `directive.sh`/gate shape as a model to
  copy — per the survey, it has not itself absorbed the canon promotion, so
  copying it would reproduce the exact drift core's issue-66 already found
  and fixed once.

## Segment fit

One-role, low-traffic internal plugin repo — the full core canon machinery
(proportional hunt tiers, miss-streak adaptation, configurable terminal
states) transfers as-is; nothing here calls for a role-specific variant
beyond the four `core_role_directive` values and, if warranted,
`RECORD_FIELDS_TERMINAL_STATES`.

Sources:
- https://github.com/tokenmaxxxer/tokenmaxxxer-core (core/hooks/*, warrant/*,
  docs/issue-63/reports/implementation.md, docs/issue-66/reports/implementation.md)
- https://github.com/tokenmaxxxer/implementation-rulebook (coding/hooks/*,
  coding/agents/warrant-hunter.md, README.md)
