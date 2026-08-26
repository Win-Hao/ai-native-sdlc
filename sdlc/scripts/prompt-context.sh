#!/bin/bash
# One terse line per turn so the loop does not drift over a long session.
IN=$(cat)
source "$(dirname "$0")/_common.sh"
CWD=$(hook_cwd)
ROOT=$(sdlc_root "$CWD") || exit 0
need_jq context
[ "$(drive_mode)" = auto ] || exit 0   # the per-turn line only matters when the agent drives

DIR=$(cfg '.artifact_dir'); DIR=${DIR:-sdlc}
ID=$(current_id)
if [ -z "$ID" ]; then
  FIRST=$(pipeline_first_cmd)
  jq -n --arg c "[SDLC] No active change. Anything beyond a trivial edit starts with $FIRST." \
    '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$c}}'
  exit 0
fi

pipeline_state "$ROOT/$DIR/$ID"
GUARD="Current stage: $PS_STAGE. Next: $PS_NEXT."
[ "$PS_STAGE" = "done" ] && GUARD="All artifact gates met. Next: $PS_NEXT."
[ -f "$ROOT/.sdlc/lock-tests" ] && GUARD="$GUARD Test files are LOCKED."

jq -n --arg c "[SDLC] change=$ID $PS_STATE. $GUARD" \
  '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$c}}'
