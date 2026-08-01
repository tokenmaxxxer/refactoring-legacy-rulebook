#!/usr/bin/env bash
# PreToolUse gate: backs the `refactoring-legacy/hooks/hooks.json` `Bash`
# matcher entry (issue-16 defect 2). Before this file existed, that matcher
# pointed at a nonexistent command — Claude Code treats a missing
# hook-command file as a silent no-op, so every Bash call free-passed
# through this entry with no enforcement and no failure signal.
#
# This is a minimal, real gate, not the aspirational full progress-tracking
# gate issue-13's Out-of-scope section deferred: it fails closed the same
# way every other gate in this repo does when core is unreachable, and
# otherwise allows (no per-step methodology check is designed or approved
# for this entry yet — that remains future work, unchanged from issue-13).
# What issue-16 requires and this file delivers is that the matcher stop
# being a ghost: real code now runs on every matched Bash call.
#
# Kill switch: export REFACTORING_LEGACY_PROGRESS_GATE_OFF=1
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" || { echo "refactoring-legacy-progress-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail

gate_kill_switch_active "${REFACTORING_LEGACY_PROGRESS_GATE_OFF:-}" || { trap - EXIT; exit 0; }

trap - EXIT
exit 0
