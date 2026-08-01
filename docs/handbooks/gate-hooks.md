# gate-hooks

Current state. Edited from now on to stay true.

## Methodology-enforcement gates (issue #10, gate-house A+ remediation issue #13)

Three self-contained plugins at repo root — `proposal-norm/`,
`characterization-tests/`, `refactoring-steps/` — each carry a
`hooks/methodology-gate.sh` (PreToolUse, `Write|Edit|MultiEdit|Bash`) and a
`hooks/tests/run-gate-tests.sh` operational test-runner script. Run a
plugin's own test suite directly to exercise its gate as a real subprocess:

```
bash proposal-norm/hooks/tests/run-gate-tests.sh
bash characterization-tests/hooks/tests/run-gate-tests.sh
bash refactoring-steps/hooks/tests/run-gate-tests.sh
```

Each gate sources core's shared gate-house library rather than hand-rolling
its own trap/kill-switch/parse/reconstruct machinery (core issue #72,
reference-adopted per `docs/issue-13/proposals/proposal.md` — never
vendored into this repo):

```
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
```

resolving `core/` as a sibling of this repository's own root (mirroring the
existing `refactoring-legacy/hooks/directive.sh` pattern for
`role-directive.sh`). The embedded Python payload loads the matching
`gate-lib.py` via `importlib.util.spec_from_file_location` using the
`GATE_LIB_PY` env var `gate-lib.sh` exports, and calls
`gate_parse_json_or_deny`, `gate_normalize_path`, and
`gate_reconstruct_write` instead of a hand-rolled `json.loads`/regex-scope/
`existing + new_text` concatenation. Verify a plugin's `hooks/` directory
carries no hand-rolled equivalent of these:

```
bash "${CORE_PLUGIN_ROOT:-core}"/hooks/tests/compliance-check.sh proposal-norm/hooks
bash "${CORE_PLUGIN_ROOT:-core}"/hooks/tests/compliance-check.sh characterization-tests/hooks
bash "${CORE_PLUGIN_ROOT:-core}"/hooks/tests/compliance-check.sh refactoring-steps/hooks
```

Each is fail-closed (`gate_trap_fail_closed`'s EXIT trap remaps any exit
other than 0/2 to 2; a JSON parse failure or unresolvable required state
denies) and independently disable-able via its own kill switch:
`PROPOSAL_NORM_GATE_OFF=1`, `CHARACTERIZATION_TESTS_GATE_OFF=1`,
`REFACTORING_STEPS_GATE_OFF=1`. Per `gate_kill_switch_active`, only a
recognized on-spelling (`1`/`true`/`yes`/`on`, case-insensitive) disables a
gate; an unrecognized value (a typo, e.g. `=bogus`) stays ACTIVE — the
fail-open bug issue-72's audit found and fixed at the library level.

A `Bash`-tool write toward an in-scope path (`sed -i`, `cat >`, etc.) is
denied outright by all three gates rather than reconstructed or silently
passed through: `gate_bash_write_targets` extracts path-shaped tokens from
the command string before the JSON payload is even parsed, and any
candidate matching the gate's own scope pattern refuses the write attempt.

Semantic checks are anchored to markdown structure (a required heading, a
list item under it, an adjacent field pair within 3 lines), evaluated
against the gate-lib-reconstructed full text — not a raw
`existing + new_strings` concatenation and not a bare substring match
anywhere in the document. See each plugin's `methodology-gate.sh` for the
exact heading-alias sets and adjacency rules; see
`docs/issue-13/proposals/proposal.md` §3 for the design rationale (the
"catalog" bare-word loophole, the ADR heading-title-only shape, etc).

JSON parsing uses `python3`, not `jq` — the stdin PreToolUse payload is
passed through an env var or argv string per gate script rather than via a
`python3 - <<EOF` heredoc, because a heredoc claims stdin for the script
body itself and leaves nothing for `json.load(sys.stdin)`.

`refactoring-steps/hooks/methodology-gate.sh` resolves the current issue
number from the git branch name (`issue-<n>/...`), trying `git
symbolic-ref --short HEAD` before falling back to `git rev-parse
--abbrev-ref HEAD` — the former also works on an unborn HEAD (a fresh repo
with no commits yet), which the latter does not.

See `docs/issue-10/proposals/methodology-enforcement.md` and
`docs/issue-10/reports/refactoring-legacy.md` for the original design, and
`docs/issue-13/proposals/proposal.md` /
`docs/issue-13/reports/refactoring-legacy.md` for the gate-house A+
remediation that migrated these gates onto core's shared library.
