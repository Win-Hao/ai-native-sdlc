#!/bin/bash
# Shared helpers for the per-case check.sh scripts.
#
# A check runs with cwd = the run's workspace (the fixture after the agent ran;
# git tag `start` is the pristine state) and prints one JSON object per line:
#   {"scope":"score"|"indicator","text":"...","passed":true|false,"evidence":"..."}
#
#   score      arm-neutral outcome quality; counts toward pass_rate in BOTH arms
#   indicator  "did the plugin's process happen" — with-only signal, never scored
#              (the same distinction `claude plugin eval` draws for with-only graders)
#
# Env: RUN_DIR — the run directory (parent of the workspace); final-message.md lives there.

emit() { # $1 scope  $2 0|1  $3 text  $4 evidence
  local p=false; [ "$2" = 1 ] && p=true
  jq -nc --arg s "$1" --argjson p "$p" --arg t "$3" --arg e "$4" '{scope:$s,text:$t,passed:$p,evidence:$e}'
}

# Files changed against `start`, committed or not (stages everything; harmless).
changed_files() { git add -A >/dev/null 2>&1; git diff --cached --name-only start; }

# 0-based index (oldest first) of the first commit after `start` whose paths match
# the regex; empty when no commit does. Uncommitted work never counts.
first_commit_touching() { # $1 path regex
  git log start..HEAD --reverse --format='%H' --name-only 2>/dev/null | awk -v re="$1" '
    /^[0-9a-f]{40}$/ { n++; next }
    $0 ~ re && !done { print n-1; done=1 }'
}

# Run the repo's own test command; prints the exit code, writes the log.
run_tests() { # $1 log path
  npm test >"$1" 2>&1; echo $?
}

# Run one hidden acceptance file and emit one `score` line per test it declares,
# so the expectation list is stable even when the file fails to load (missing
# module → every test reported as not run).
hidden_check() { # $1 hidden test source  $2 destination under tests/
  local src="$1" dst="tests/$2" name st results
  cp "$src" "$dst"
  results=$(node --test --test-reporter=tap "$dst" 2>/dev/null | awk '
    /^(not )?ok [0-9]+ - / { s=($1=="ok")?"ok":"not ok"; sub(/^(not )?ok [0-9]+ - /,""); sub(/ #.*$/,""); print s "\t" $0 }')
  rm -f "$dst"
  while IFS= read -r name; do
    st=$(printf '%s\n' "$results" | awk -F'\t' -v n="$name" '$2==n {print $1; exit}')
    [ -z "$st" ] && st="not run (file failed to load)"
    emit score "$([ "$st" = ok ] && echo 1 || echo 0)" "Acceptance: $name" "node --test: $st"
  done < <(grep -oE "^test\('[^']+'" "$src" | sed "s/^test('//; s/'$//")
}

# The agent's final message for this run (empty if unknown).
final_message() { cat "${RUN_DIR:-..}/final-message.md" 2>/dev/null; }

# Frontmatter status of an artifact (mirrors the plugin's own parser).
artifact_status() { [ -f "$1" ] && awk 'NR==1{if($0!="---")exit;next} $0=="---"{exit} sub(/^status:[ \t]*/,""){sub(/[ \t]*#.*$/,"");sub(/[ \t]+$/,"");print;exit}' "$1" | tr -d "\"'"; }
