#!/bin/bash
# Run the StageKit A/B eval headlessly: every case × arm × N runs.
#
#   bin/run.sh [-n RUNS] [-i ITERATION] [-a with_skill|without_skill|both] [eval-case ...]
#
# Env:  MODEL           executor model (default claude-opus-5; always passed explicitly, same for both arms)
#       MAX_BUDGET_USD  per-run cost ceiling passed to claude (default 5)
#       ALLOWED_TOOLS   comma-separated allowlist (default below; headless denies everything else)
#       SYSTEM_APPEND   optional system-prompt addition given to BOTH arms (default: none)
#       CLAUDE_BIN      claude binary (default: claude)
#
# Layout — the one skill-creator's aggregate_benchmark.py expects:
#   workspace/iteration-<I>/<eval-case>/<arm>/run-<n>/
#     workspace/         the fixture after the run; git tag `start` = pristine state
#     transcript.jsonl   stream-json events
#     result.json        the final result event (usage, cost, duration)
#     timing.json        {total_tokens, duration_ms, total_duration_seconds, cost_usd, num_turns}
#     final-message.md   the agent's last message
# A run that already has result.json is skipped, so an interrupted batch resumes.
set -u
E="$(cd "$(dirname "$0")/.." && pwd)"; PLUGIN="$(dirname "$E")"; export PLUGIN
RUNS=3; ITER=1; ARMS="with_skill without_skill"; CLAUDE_BIN="${CLAUDE_BIN:-claude}"
while getopts 'n:i:a:h' o; do case $o in
  n) RUNS=$OPTARG;; i) ITER=$OPTARG;;
  a) case $OPTARG in both) ;; with_skill|without_skill) ARMS=$OPTARG;; *) echo "bad arm: $OPTARG" >&2; exit 2;; esac;;
  *) sed -n '2,19p' "$0"; exit 0;; esac; done
shift $((OPTIND-1))
CASES=("$@"); [ ${#CASES[@]} -eq 0 ] && CASES=($(cd "$E" && ls -d eval-*))
for c in "${CASES[@]}"; do [ -f "$E/$c/prompt.md" ] || { echo "no such case: $c" >&2; exit 2; }; done
for t in jq node git "$CLAUDE_BIN"; do command -v "$t" >/dev/null || { echo "$t is required" >&2; exit 1; }; done

ALLOWED="${ALLOWED_TOOLS:-Read,Write,Edit,MultiEdit,Glob,Grep,Agent,Task,Skill,TodoWrite,EnterPlanMode,ExitPlanMode,Bash(npm *),Bash(node *),Bash(git *),Bash(mkdir *),Bash(ls *),Bash(cat *),Bash(date *),Bash(rg *),Bash(grep *),Bash(jq *),Bash(touch *),Bash(rm *),Bash(sed *),Bash(head *),Bash(tail *),Bash(wc *),Bash(diff *),Bash(find *),Bash(echo *),Bash(printf *),Bash(cp *),Bash(mv *),Bash(cd *),Bash(pwd),Bash(true)}"
MAX_BUDGET_USD="${MAX_BUDGET_USD:-20}"
MODEL="${MODEL:-claude-opus-5}"   # executor model — fixed explicitly so the CLI default never leaks in
# Optional system-prompt addition for BOTH arms (default: none — the prompts already ask for subagents).
SYSTEM_APPEND="${SYSTEM_APPEND:-}"
WS="$E/workspace/iteration-$ITER"; mkdir -p "$WS"

# Neither arm may load the *installed* copy of the plugin: --plugin-dir is the only
# source in the with arm, nothing in the without arm. Re-enabled on exit.
REENABLE=0
if "$CLAUDE_BIN" plugin list 2>/dev/null | grep -A3 'stagekit@' | grep -q 'enabled'; then
  "$CLAUDE_BIN" plugin disable stagekit >/dev/null 2>&1 && REENABLE=1 && echo "(installed stagekit plugin disabled for the duration of the run)"
fi
trap '[ "$REENABLE" = 1 ] && "$CLAUDE_BIN" plugin enable stagekit >/dev/null 2>&1' EXIT

run_one() { # case arm n
  local c=$1 arm=$2 n=$3 D W
  D="$WS/$c/$arm/run-$n"; W="$D/workspace"
  if [ -f "$D/result.json" ]; then echo "skip $c/$arm/run-$n (done)"; return; fi
  rm -rf "$D"; mkdir -p "$W"
  cp -R "$E/fixture/." "$W"
  [ -f "$E/$c/setup.sh" ] && (cd "$W" && bash "$E/$c/setup.sh")
  [ "$arm" = without_skill ] && rm -rf "$W/.stagekit" "$W/stagekit"
  (cd "$W" && git init -q && git config user.email eval@example.com && git config user.name eval \
     && git add -A && git commit -qm "fixture: starting point" && git tag start)
  local args=(-p "$(cat "$E/$c/prompt.md")" --output-format stream-json --verbose \
              --permission-mode acceptEdits --allowedTools "$ALLOWED" --max-budget-usd "$MAX_BUDGET_USD")
  [ -n "$SYSTEM_APPEND" ] && args+=(--append-system-prompt "$SYSTEM_APPEND")
  [ "$arm" = with_skill ] && args+=(--plugin-dir "$PLUGIN")
  args+=(--model "$MODEL")
  echo "run  $c/$arm/run-$n"
  (cd "$W" && "$CLAUDE_BIN" "${args[@]}") >"$D/transcript.jsonl" 2>"$D/stderr.log"
  jq -c 'select(.type=="result")' "$D/transcript.jsonl" 2>/dev/null | tail -1 >"$D/result.json"
  if [ ! -s "$D/result.json" ]; then echo "  no result event — see $D/stderr.log"; rm -f "$D/result.json"; return; fi
  jq '{total_tokens: ((.usage.input_tokens//0)+(.usage.output_tokens//0)+(.usage.cache_read_input_tokens//0)+(.usage.cache_creation_input_tokens//0)),
       output_tokens: (.usage.output_tokens//0), duration_ms: (.duration_ms//0),
       total_duration_seconds: ((.duration_ms//0)/1000), cost_usd: (.total_cost_usd//0), num_turns: (.num_turns//0), model: $m}' --arg m "$MODEL" \
     "$D/result.json" >"$D/timing.json"
  jq -c 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | .name' "$D/transcript.jsonl" 2>/dev/null \
    | jq -s 'group_by(.) | map({key: .[0], value: length}) | from_entries | {tool_calls: ., total_tool_calls: (map(.) | add // 0)}' >"$D/tools.json"
  jq -s '.[0] + .[1]' "$D/timing.json" "$D/tools.json" >"$D/timing.tmp" && mv "$D/timing.tmp" "$D/timing.json"
  jq -r '.result // ""' "$D/result.json" >"$D/final-message.md"
  jq -r --arg m "$MODEL" '"  model=\($m) turns=\(.num_turns) tokens=\(.total_tokens) cost=$\(.cost_usd) time=\(.total_duration_seconds)s"' "$D/timing.json"
}

for c in "${CASES[@]}"; do for n in $(seq 1 "$RUNS"); do for arm in $ARMS; do run_one "$c" "$arm" "$n"; done; done; done
echo "done → $WS"; echo "next: bin/grade.sh -i $ITER [-j]"
