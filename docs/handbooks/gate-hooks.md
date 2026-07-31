# gate-hooks

Current state. Edited from now on to stay true.

## Methodology-enforcement gates (issue #10)

Three self-contained plugins at repo root — `proposal-norm/`,
`characterization-tests/`, `refactoring-steps/` — each carry a
`hooks/methodology-gate.sh` (PreToolUse, `Write|Edit|MultiEdit`) and a
`hooks/tests/run-gate-tests.sh` operational test-runner script. Run a
plugin's own test suite directly to exercise its gate as a real subprocess:

```
bash proposal-norm/hooks/tests/run-gate-tests.sh
bash characterization-tests/hooks/tests/run-gate-tests.sh
bash refactoring-steps/hooks/tests/run-gate-tests.sh
```

Each is fail-closed (JSON parse failure or unresolvable required state →
deny, exit 2) and independently disable-able via its own kill switch:
`PROPOSAL_NORM_GATE_OFF=1`, `CHARACTERIZATION_TESTS_GATE_OFF=1`,
`REFACTORING_STEPS_GATE_OFF=1`.

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
`docs/issue-10/reports/refactoring-legacy.md` for the design and what was
built.
