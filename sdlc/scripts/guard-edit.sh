#!/bin/bash
# Stage 4 test lock + Stage 3 protected paths.
IN=$(cat)
source "$(dirname "$0")/_common.sh"
CWD=$(hook_cwd)
ROOT=$(sdlc_root "$CWD") || exit 0
need_jq gate

# Edit/Write send file_path; NotebookEdit sends notebook_path.
FILE=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$IN")
[ -z "$FILE" ] && exit 0
REL=$(rel_path "$FILE")

# --- test lock: an agent fixing code must not be able to weaken the check on it
if gate_on test_lock && [ -f "$ROOT/.sdlc/lock-tests" ]; then
  while IFS= read -r g; do
    [ -z "$g" ] && continue
    if match_glob "$REL" "$g"; then
      deny "Test files are locked for this fix task ($REL).

The failing test was committed before the fix and is the proof the bug is gone.
Fix the code, not the test.

If the test itself is genuinely wrong, stop and say so — the human removes the
lock with: rm .sdlc/lock-tests"
    fi
  done < <(cfg '.gates.test_lock.test_globs[]?')
fi

# --- protected paths
if gate_on protected_paths; then
  while IFS= read -r g; do
    [ -z "$g" ] && continue
    if match_glob "$REL" "$g"; then
      deny "$REL is a protected path (.sdlc/config.json → gates.protected_paths).

Generated code, migrations and CI config are not edited by an agent session.
Route: raise it in plan.md under Risks, or have a human edit the source of truth."
    fi
  done < <(cfg '.gates.protected_paths.paths[]?')
fi
exit 0
