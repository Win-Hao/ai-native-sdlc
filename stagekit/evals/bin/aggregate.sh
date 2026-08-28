#!/bin/bash
# Aggregate an iteration into benchmark.json / benchmark.md (mean ± stddev per arm,
# delta) with skill-creator's script, and print the viewer command.
#
#   bin/aggregate.sh [-i ITERATION]
#
# Env:  SKILL_CREATOR  path to the skill-creator skill (default ~/.claude/skills/skill-creator)
set -u
E="$(cd "$(dirname "$0")/.." && pwd)"; ITER=1
while getopts 'i:h' o; do case $o in i) ITER=$OPTARG;; *) sed -n '2,7p' "$0"; exit 0;; esac; done
WS="$E/workspace/iteration-$ITER"; [ -d "$WS" ] || { echo "no $WS" >&2; exit 1; }
SC="${SKILL_CREATOR:-$HOME/.claude/skills/skill-creator}"
[ -f "$SC/scripts/aggregate_benchmark.py" ] || { echo "skill-creator not found at $SC (set SKILL_CREATOR)" >&2; exit 1; }
(cd "$SC" && python3 -m scripts.aggregate_benchmark "$WS" --skill-name stagekit --skill-path "$(dirname "$E")")
echo
echo "benchmark: $WS/benchmark.md"
echo "viewer:    python3 $SC/eval-viewer/generate_review.py $WS --skill-name stagekit --benchmark $WS/benchmark.json"
