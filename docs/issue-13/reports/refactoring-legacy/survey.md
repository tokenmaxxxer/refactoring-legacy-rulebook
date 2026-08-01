# Current-state survey (issue-13)

Scope: the three `hooks/methodology-gate.sh` scripts issue #10 built
(`proposal-norm`, `characterization-tests`, `refactoring-steps`), audited
2026-08-01 at grade B-. This survey maps each named defect to its exact
location before the proposal designs a fix.

## 1. Reconstruction: existing+new concatenation, no real Edit/MultiEdit/replace_all semantics

All three gates approximate the post-write file as
`existing_on_disk + new_text`, where `new_text` is just every
`new_string`/`content` concatenated — not an actual string replacement:

- `characterization-tests/hooks/methodology-gate.sh:47-58` — `Write`
  reads `content`; `Edit` reads `new_string`; `MultiEdit` joins every
  edit's `new_string` with `"".join(...)`. `old_string` and `replace_all`
  are never read at all.
- `refactoring-steps/hooks/methodology-gate.sh:28-42` (Python) — same
  shape: `Write`→content, `Edit`→new_string, `MultiEdit`→ join of
  new_strings. No `old_string`/`replace_all` read.
- `proposal-norm/hooks/methodology-gate.sh:48-56` — same shape again.

Consequence: a `Write` that *replaces* an approved-looking existing file
with new content missing the required elements still passes, because the
old content's keywords survive in the `existing + new` concatenation (the
issue's "재구성이 existing+new 연결... 삭제 미모델" finding — deletion is
never modeled, and a genuine same-file rewrite is scored against content
that is no longer actually on disk after the write). This is not a
`replace_all` bug narrowly — it is that no gate performs a replacement at
all, ever; `old_string`/`new_string`/`replace_all` are read from a
different code path than the one that already exists in
`core/hooks/lib/gate-lib.py`'s `gate_reconstruct_write` (see scout-brief).

## 2. Bash sed bypass

None of the three `hooks.json` (`proposal-norm/hooks/hooks.json`,
`characterization-tests/hooks/hooks.json`, `refactoring-steps/hooks/hooks.json`)
registers a `PreToolUse`/`Bash` matcher — all three match only
`Write|Edit|MultiEdit`. A write to any gated path via `Bash` (`sed -i`,
`cat >`, `python3 -c "open(...).write(...)"`, `echo >>`) reaches disk with
no gate evaluation at all. `refactoring-legacy/hooks/hooks.json` *does*
register a `Bash` matcher, but for a dangling target
(`refactoring-legacy-progress-gate.sh`, which does not exist in the repo —
confirmed absent; every `Bash` call currently free-passes through that
entry too, since a missing hook script is a no-op, not a deny). This is a
pre-existing gap the issue-10 report already flagged as open and out of
that PR's scope; issue #13 is where it gets closed, since the audit calls
it out directly ("Bash sed 우회").

## 3. `'catalog'` word-match passes

`refactoring-steps/hooks/methodology-gate.sh:97-99` (embedded Python):

```python
catalog_terms = ["extract method", "extract function", "rename", "inline",
                 "move method", "move function", "refactoring.com/catalog", "catalog"]
has_catalog = any(t in low for t in catalog_terms)
```

The bare word `"catalog"` is itself a member of the term list, so any
record text containing the literal word "catalog" — in any sentence, any
context, unrelated to naming an actual Fowler-catalog step against a real
piece of code — satisfies the check. Same substring-membership shape (not
the same specific bug) applies to the other two gates' checks: `"seam"`
anywhere in the effective text (`characterization-tests`, `refactoring-steps`),
`"equivalence"`/`"동등성"` anywhere (`refactoring-steps`), `"context"` /
`"option"` / `"decision"` / `"consequence"` anywhere, 2-of-4
(`proposal-norm`) — none of these require the matched term to sit in a
section boundary, near a concrete referent (a file path, a test name, a
named step), or in any structural relationship to the rest of the
document.

## 4. Characterization-test existence/pass unverified

`characterization-tests/hooks/methodology-gate.sh:63-74` only checks that
the phrase `"characterization test"` (or Korean `"특성화 테스트"`) and a
non-empty `characterization_tests_path:` field appear as text in the
record. Nothing reads the path the field names, confirms a file exists
there, or runs/parses any test result. `refactoring-steps/hooks/methodology-gate.sh:160`
(BRANCH 2, the "characterize before refactor" ordering gate) only checks
the *field is present and non-empty* via
`grep -Eq 'characterization_tests_path:[[:space:]]*[^[:space:]]+'` against
the on-disk record — again presence of a line, not existence of the file
it names, let alone that the tests at that path pass.

## 5. Fail-closed / kill-switch / path-normalization posture (not named in the audit one-liner, but load-bearing for "전 축 A+")

- **Trap-at-top**: none of the three gates installs an EXIT trap at all.
  `set -uo pipefail` runs first; if the embedded `python3` heredoc/argv
  call itself dies from something the script's own `case`/`if` logic does
  not anticipate (before the script reaches its own exit-code check), the
  script's own exit code — not necessarily 2 — becomes the hook's exit
  code, and Claude Code treats any non-0/2 exit as **non-blocking**
  (fail-open per `gate-lib.sh`'s own doc comment). `refactoring-steps`
  comes closest by checking `$PY_STATUS`/`$PY2_STATUS` explicitly and
  exiting 2 on non-zero, but only for the two `python3` calls it makes —
  any other unexpected abort (e.g. `git` invoked wrong, an `set -u`
  unbound-variable abort before those checks) still exits with bash's own
  code.
- **Kill switches**: all three use the narrow correct form already
  (`= "1"` only disables; everything else — including an unrecognized
  typo — stays active), so they do NOT have core's pre-issue-72
  default-off-on-unrecognized-value bug. They do differ from the
  now-canon `gate_kill_switch_active` convention (`1`/`true`/`yes`/`on`,
  case-insensitive) in only recognizing the bare `"1"`.
- **Malformed JSON**: all three fail closed already (`characterization-tests`
  and `proposal-norm` via explicit `except`/`fail()`; `refactoring-steps`
  via `PY_STATUS`/first-line-not-`OK` check) — this axis is already sound
  and should be preserved, not rebuilt, by the migration.
- **Path normalization**: none of the three normalizes `file_path` against
  repo root before scope-matching; all three regex-search the raw
  `tool_input.file_path` string for a `docs/issue-<n>/...` suffix. A
  regex `.search` (not `.match`/anchor-at-start) against the raw string
  does incidentally match both `docs/issue-13/...` (relative) and
  `/home/u/repo/docs/issue-13/...` (absolute) today, but does not reject
  a path that resolves *outside* repo root while still containing that
  substring elsewhere in a longer absolute path, and does not collapse a
  `./`-prefixed or `../`-containing input the way
  `gate_normalize_path` does.
- **Deny reason on stderr**: already uniform and correct across all three
  (every deny path writes to `>&2`) — preserve as-is.

## 6. Test coverage gaps

- `characterization-tests/hooks/tests/run-gate-tests.sh` and
  `proposal-norm/hooks/tests/run-gate-tests.sh`: no `Bash`-tool case, no
  malformed-JSON case beyond what the harness happens to hit, no
  kill-switch-unrecognized-value case, no absolute-path case, no
  `MultiEdit`/`replace_all` case exercising an actual multi-occurrence
  replace.
- `refactoring-steps/hooks/tests/run-gate-tests.sh`: has the ordering
  cases (5-7) but the same gaps otherwise.
- None of the three suites is wired into a single "run all three" or
  CI-equivalent entrypoint at repo root; `docs/handbooks/gate-hooks.md`
  documents running each individually.

## 7. README drift

`README.md`'s `## Doctrine (issue #10)` section already accurately
describes the three plugins' current file layout and kill switches (spot
checked against `.claude-plugin/plugin.json`, `hooks/hooks.json` for all
three — matches). It explicitly names the dangling
`refactoring-legacy-progress-gate.sh` entry as a known, still-open gap.
The one drift found: README does not yet mention `core`'s gate-house
standard (issue-72, landed after README was last edited) as the
now-mandatory reference target for these three gates — this is what the
phase-2 README update under this issue needs to add, alongside removing
any language that would newly become stale once the gates migrate to
`gate-lib.sh`/`gate-lib.py`.

## Write-surface map (for the proposal's options section)

| Surface | File | Current defect classes present |
|---|---|---|
| `proposal-norm` | `proposal-norm/hooks/methodology-gate.sh` | 1, 2, 3(shape), 5(fail-closed trap, path-normalize) |
| `characterization-tests` | `characterization-tests/hooks/methodology-gate.sh` | 1, 2, 3(shape), 4, 5 |
| `refactoring-steps` | `refactoring-steps/hooks/methodology-gate.sh` | 1, 2, 3, 4, 5 |
| test harnesses | `*/hooks/tests/run-gate-tests.sh` | 6 |
| docs | `README.md`, `docs/handbooks/gate-hooks.md` | 7 |
