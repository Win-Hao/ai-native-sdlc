#!/bin/bash
# When an artifact gate moves, tell the user what is next. Quiet otherwise.
IN=$(cat)
source "$(dirname "$0")/_common.sh"
CWD=$(hook_cwd)
ROOT=$(stagekit_root "$CWD") || exit 0
need_jq context
[ "$(drive_mode)" = auto ] || exit 0

DIR=$(cfg '.artifact_dir'); DIR=${DIR:-stagekit}
ID=$(current_id); [ -z "$ID" ] && exit 0
pipeline_state "$ROOT/$DIR/$ID"

FP="$ID:$PS_STATE"
LAST=""; [ -f "$ROOT/.stagekit/.laststate" ] && LAST=$(cat "$ROOT/.stagekit/.laststate")
[ "$FP" = "$LAST" ] && exit 0
printf '%s' "$FP" > "$ROOT/.stagekit/.laststate"
[ -z "$LAST" ] && exit 0   # first observation is not an advance

jq -n --arg m "StageKit · $ID · $PS_STAGE — $PS_NEXT" '{systemMessage:$m}'
