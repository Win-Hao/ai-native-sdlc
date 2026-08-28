#!/bin/bash
# Grade every run of an iteration: the case's mechanical check.sh, plus the blind
# LLM judge with -j. Writes grading.json per run (skill-creator schema) and
# eval_metadata.json per case.
#
#   bin/grade.sh [-i ITERATION] [-j] [eval-case ...]
#
# Env:  JUDGE_MODEL  judge model for -j (default haiku)
set -u
E="$(cd "$(dirname "$0")/.." && pwd)"
ITER=1; JUDGE=0
while getopts 'i:jh' o; do case $o in i) ITER=$OPTARG;; j) JUDGE=1;; *) sed -n '2,8p' "$0"; exit 0;; esac; done
shift $((OPTIND-1))
WS="$E/workspace/iteration-$ITER"; [ -d "$WS" ] || { echo "no $WS" >&2; exit 1; }
CASES=("$@"); [ ${#CASES[@]} -eq 0 ] && CASES=($(cd "$WS" && ls -d eval-* 2>/dev/null))
id=0
for c in "${CASES[@]}"; do
  id=$((id+1))
  titles=$(grep '^### ' "$E/$c/graders/criteria.md" | sed 's/^### //')
  jq -n --argjson id "$id" --arg name "$c" --rawfile prompt "$E/$c/prompt.md" --arg t "$titles" \
    '{eval_id:$id, eval_name:$name, prompt:$prompt, assertions:($t|split("\n")|map(select(length>0)))}' >"$WS/$c/eval_metadata.json"
  for D in "$WS/$c"/*/run-*; do
    [ -d "$D/workspace" ] || continue
    echo "grade $c/$(basename "$(dirname "$D")")/$(basename "$D")"
    [ -f "$D/timing.json" ] || echo '{}' >"$D/timing.json"
    checks=$(cd "$D/workspace" && RUN_DIR="$D" bash "$E/$c/check.sh")
    judged='[]'; [ "$JUDGE" = 1 ] && judged=$(bash "$E/bin/judge.sh" "$E/$c" "$D")
    printf '%s\n' "$checks" | jq -s --argjson j "$judged" --slurpfile t "$D/timing.json" '
      (map(select(.scope=="score")) + ($j|map(.+{scope:"judge"}))) as $score
      | { expectations: ($score|map({text,passed,evidence,scope})),
          indicators:   (map(select(.scope=="indicator"))|map({text,passed,evidence})),
          summary: { passed: ($score|map(select(.passed))|length),
                     failed: ($score|map(select(.passed|not))|length),
                     total:  ($score|length),
                     pass_rate: (if ($score|length)>0 then ((($score|map(select(.passed))|length)/($score|length))*100|round/100) else 0 end) },
          execution_metrics: { tool_calls: ($t[0].tool_calls // {}), total_tool_calls: ($t[0].total_tool_calls // 0), errors_encountered: 0 } }' >"$D/grading.json"
    jq -r '"  score \(.summary.passed)/\(.summary.total)   indicators \([.indicators[]|select(.passed)]|length)/\(.indicators|length)"' "$D/grading.json"
  done
done
echo "next: bin/aggregate.sh -i $ITER"
