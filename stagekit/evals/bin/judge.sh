#!/bin/bash
# Blind LLM judge for one run.   bin/judge.sh <case-dir> <run-dir>  → JSON array on stdout
#
# The judge sees the task, the criteria, the final message, the diff (process
# artifacts under stagekit/ and .stagekit/ excluded), the commit log and the tail
# of the test log. It is never told which arm produced the run. Its answer is
# aligned to the criteria list by position, so a dropped or reordered item can
# never shift the expectation count; anything missing counts as failed.
set -u
C="$1"; D="$2"; W="$D/workspace"
JUDGE_MODEL="${JUDGE_MODEL:-sonnet}"; CLAUDE_BIN="${CLAUDE_BIN:-claude}"
titles=$(grep '^### ' "$C/graders/criteria.md" | sed 's/^### //' | jq -R . | jq -s -c .)
diff=$(cd "$W" && git add -A >/dev/null 2>&1; git diff --cached start -- . ':(exclude)stagekit' ':(exclude).stagekit' | head -c 60000)
commits=$(cd "$W" && git log start..HEAD --reverse --format="- %s" --name-only -- . ":(exclude)stagekit" ":(exclude).stagekit" 2>/dev/null | sed '/^$/d')
tests=$(tail -n 40 "$W/npm-test.log" 2>/dev/null)
prompt="You are grading one run of a coding task against fixed criteria. Judge outcomes only: ignore which tools, commands, files or process the agent used, and do not reward process artifacts. Be strict — a criterion passes only with concrete evidence in what you are shown.

## Task given to the agent
$(cat "$C/prompt.md")

## Criteria
$(cat "$C/graders/criteria.md")

## Agent's final message
$(cat "$D/final-message.md" 2>/dev/null)

## Diff of the working tree against the starting commit
\`\`\`diff
$diff
\`\`\`

## Commits made during the run (oldest first; process-only commits omitted)
$commits

## Test run output (tail)
\`\`\`
$tests
\`\`\`

Respond with ONLY a JSON array, one object per criterion in the order given:
[{\"text\": \"<criterion heading>\", \"passed\": true|false, \"evidence\": \"<one sentence citing what you saw>\"}]"
out=$(CLAUDE_CODE_EFFORT_LEVEL="${JUDGE_EFFORT:-low}" "$CLAUDE_BIN" -p "$prompt" --model "$JUDGE_MODEL" --output-format json 2>/dev/null | jq -r '.result // ""')
json=$(printf '%s\n' "$out" | sed -n '/^[[:space:]]*\[/,$p' | sed 's/```//g')
if printf '%s' "$json" | jq -e 'type=="array"' >/dev/null 2>&1; then
  printf '%s' "$json" | jq -c --argjson t "$titles" \
    '. as $j | $t | to_entries | map((($j[.key]) // {passed:false,evidence:"judge omitted this criterion"}) as $v | {text:.value, passed:($v.passed==true), evidence:($v.evidence // ""|tostring)})'
else
  printf '%s' "$titles" | jq -c 'map({text:., passed:false, evidence:"judge did not return valid JSON"})'
fi
