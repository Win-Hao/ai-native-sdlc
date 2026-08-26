#!/bin/bash
# When an artifact gate moves, tell the user what is next. Quiet otherwise.
IN=$(cat)
source "$(dirname "$0")/_common.sh"
CWD=$(hook_cwd)
ROOT=$(sdlc_root "$CWD") || exit 0
need_jq context
[ "$(drive_mode)" = auto ] || exit 0

DIR=$(cfg '.artifact_dir'); DIR=${DIR:-sdlc}
ID=$(current_id); [ -z "$ID" ] && exit 0
pipeline_state "$ROOT/$DIR/$ID"

FP="$ID:$PS_STATE"
LAST=""; [ -f "$ROOT/.sdlc/.laststate" ] && LAST=$(cat "$ROOT/.sdlc/.laststate")
[ "$FP" = "$LAST" ] && exit 0
printf '%s' "$FP" > "$ROOT/.sdlc/.laststate"
[ -z "$LAST" ] && exit 0   # first observation is not an advance

jq -n --arg m "SDLC · $ID · $PS_STAGE — $PS_NEXT" '{systemMessage:$m}'
