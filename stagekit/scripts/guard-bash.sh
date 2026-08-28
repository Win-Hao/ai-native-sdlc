#!/bin/bash
# Stage 5 production gate + irreversible-action confirmation.
IN=$(cat)
source "$(dirname "$0")/_common.sh"
CWD=$(hook_cwd)
ROOT=$(stagekit_root "$CWD") || exit 0
need_jq gate

CMD=$(jq -r '.tool_input.command // empty' <<<"$IN")
[ -z "$CMD" ] && exit 0

# --- production gate: the agent acts up to the gate and cannot pass it
if gate_on production_gate; then
  ENVVAR=$(cfg '.gates.production_gate.approval_env'); ENVVAR=${ENVVAR:-STAGEKIT_RELEASE_APPROVAL}
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    if [[ "$CMD" == *$p* ]]; then
      if [ -z "${!ENVVAR}" ]; then
        deny "Production deploys need a named release authorization.

Matched gate pattern: '$p'
Set $ENVVAR=<who authorized it> in the environment before running this.

Prepare the release, then stop and hand the authorization to a human."
      fi
    fi
  done < <(cfg '.gates.production_gate.match[]?')
fi

# --- irreversible actions: ask, don't decide
if gate_on irreversible; then
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    if cmd_has "$CMD" "$p"; then
      ask "Irreversible action matched '$p'. Confirm before this runs."
    fi
  done < <(cfg '.gates.irreversible.match[]?')
fi
exit 0
