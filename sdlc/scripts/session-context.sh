#!/bin/bash
# Frame the session according to .sdlc/config.json → drive:
#   off      (default) nothing — the commands are a toolbox; CLAUDE.md holds the pointers
#   suggest  where the change stands + "mention the stage command once, then do what was asked"
#   auto     the full loop rules: the agent drives the stages and stops at each gate
IN=$(cat)
source "$(dirname "$0")/_common.sh"
CWD=$(hook_cwd)
ROOT=$(sdlc_root "$CWD") || exit 0
need_jq context
DRIVE=$(drive_mode); [ "$DRIVE" = off ] && exit 0

DIR=$(cfg '.artifact_dir'); DIR=${DIR:-sdlc}
ID=$(current_id)
CHAIN=$(pipeline_chain)

if [ -z "$ID" ]; then
  STATE="## State
No active change (\`.sdlc/current\` is empty). \`$(pipeline_first_cmd)\` opens one."
else
  pipeline_state "$ROOT/$DIR/$ID"
  LOCK=""
  [ -f "$ROOT/.sdlc/lock-tests" ] && LOCK="
**Test files are locked** — a fix task is in progress. Fix the code, not the test."
  W=""; [ "$PS_WAITING" = 1 ] && W=" (waiting on the user)"
  STATE="## State
Active change: \`$ID\`  (\`$DIR/$ID/\`)
  $PS_STATE

Current stage: $PS_STAGE$W
Next: $PS_NEXT$LOCK"
fi

if [ "$DRIVE" = suggest ]; then
  RULES="# SDLC toolbox (drive: suggest)

Change artifacts live in \`$DIR/<id>/\`; this project's stages are
$CHAIN; the active change id is in \`.sdlc/current\`. The stage commands
(/sdlc:intent /sdlc:spec /sdlc:plan /sdlc:build /sdlc:verify /sdlc:review
/sdlc:done) are the user's to run.

- When the user brings non-trivial new work, say once which command would
  capture it — then do what they asked.
- When a stage artifact lands, name the usual next command. Do not insist.
- The status values in the artifacts are the user's decisions: set one only
  when they say so."
else
  RULES="# You are operating under the AI-native SDLC (drive: auto)

This repo runs a staged loop. Artifacts live in \`$DIR/<id>/\`, the active change
id is in \`.sdlc/current\`, and **this project's pipeline is**:

  $CHAIN

The pipeline is defined in \`.sdlc/config.json\` → \`pipeline\`. It is this
project's flow, not a fixed one — follow the stages listed above, not a
remembered six-stage default.

**Drive this loop for the user. Do not wait to be told the next command.**

- A new feature, problem or idea starts at the first stage. Invoke its command —
  do not start designing or coding in the conversation.
- Each stage ends by committing its artifact. When one lands, name the next gate
  out loud and offer to run it.
- **Never write implementation code before the plan stage's gate is met.** If
  asked to implement early, say so and run the current stage's command instead.
- You do not cross gates on your own. The user's word is the gate: when they
  say accept or approve, set the status for them and move on. Otherwise,
  present and wait.
- If the user pushes past a stage deliberately, follow them — say once what is
  being skipped, then do the work.
- A change stays open until the user runs \`/sdlc:done\`. Do not run it for them."
fi

jq -n --arg c "$RULES

$STATE" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$c}}'
