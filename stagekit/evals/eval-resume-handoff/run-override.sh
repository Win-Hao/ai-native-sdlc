#!/bin/bash
# Two-phase handoff run (cwd = workspace). Phase A starts the returns feature and
# is cut off by a small budget; phase B is a FRESH session that must discover the
# state from disk and finish. Owns the claude calls; leaves transcript.jsonl,
# result.json and timing.json (phases summed) for the shared pipeline.
set -u
phase() { # $1 prompt file  $2 budget  $3 tag
  local args=(-p "$(cat "$CASE_DIR/$1")" --output-format stream-json --verbose \
              --permission-mode acceptEdits --allowedTools "$ALLOWED" \
              --max-budget-usd "$2" --model "$MODEL")
  [ -n "${SYSTEM_APPEND:-}" ] && args+=(--append-system-prompt "$SYSTEM_APPEND")
  [ "$ARM" = with_skill ] && args+=(--plugin-dir "$PLUGIN")
  "$CLAUDE_BIN" "${args[@]}" >"$RUN_DIR/transcript-$3.jsonl" 2>>"$RUN_DIR/stderr.log"
  jq -c 'select(.type=="result")' "$RUN_DIR/transcript-$3.jsonl" 2>/dev/null | tail -1 >"$RUN_DIR/result-$3.json"
}
echo "  phase A (budget \$$PHASE_A_BUDGET — meant to be cut off)"
phase prompt.md "$PHASE_A_BUDGET" a
[ -s "$RUN_DIR/result-a.json" ] || { echo "  phase A produced no result event"; exit 0; }
echo "  phase B (fresh session, budget \$$MAX_BUDGET_USD)"
phase prompt-phase-b.md "$MAX_BUDGET_USD" b
[ -s "$RUN_DIR/result-b.json" ] || { echo "  phase B produced no result event"; exit 0; }
# Phase B is the graded session; timing sums both phases.
cp "$RUN_DIR/transcript-b.jsonl" "$RUN_DIR/transcript.jsonl"
cp "$RUN_DIR/result-b.json" "$RUN_DIR/result.json"
jq -s --arg m "$MODEL" '{
  total_tokens: (map((.usage.input_tokens//0)+(.usage.output_tokens//0)+(.usage.cache_read_input_tokens//0)+(.usage.cache_creation_input_tokens//0)) | add),
  output_tokens: (map(.usage.output_tokens//0) | add),
  duration_ms: (map(.duration_ms//0) | add),
  total_duration_seconds: ((map(.duration_ms//0) | add) / 1000),
  cost_usd: (map(.total_cost_usd//0) | add),
  num_turns: (map(.num_turns//0) | add),
  model: $m, phases: 2}' "$RUN_DIR/result-a.json" "$RUN_DIR/result-b.json" >"$RUN_DIR/timing.json"
