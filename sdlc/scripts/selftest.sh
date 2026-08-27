#!/bin/bash
# Self-test for the SDLC hook scripts. Builds a throwaway repo, drives every
# hook with the JSON Claude Code sends, and checks the decisions — both
# directions: the blocked case blocks, the normal case stays silent.
# Run it after touching anything in scripts/:
#   ${CLAUDE_PLUGIN_ROOT}/scripts/selftest.sh
set -u
S="$(cd "$(dirname "$0")" && pwd)"; P="$(dirname "$S")"
command -v jq >/dev/null 2>&1 || { echo "FAIL  jq is required"; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export CLAUDE_PROJECT_DIR="$T" CLAUDE_PLUGIN_ROOT="$P"
unset SDLC_RELEASE_APPROVAL
cd "$T" || exit 1
git init -q && git config user.email t@t && git config user.name t
mkdir -p src tests .github/workflows .sdlc sdlc/0001-x evals
echo x > src/a.js; echo x > src/b.js; echo x > tests/a.test.js; echo x > .github/workflows/ci.yml
printf '# fixture\n\n## Commands\n- Test: `true`\n\n## Verifying your work\nRun the tests.\n' > CLAUDE.md; cp "$P/templates/REVIEW.md" REVIEW.md
git add -A && git commit -qm init

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); }
bad() { FAIL=$((FAIL+1)); echo "FAIL  $1"; echo "      got: $(printf '%s' "$2" | tr '\n' ' ' | head -c 240)"; }
hook() { # $1 script  $2 tool_input json  -> stdout
  jq -nc --arg cwd "$T" --argjson ti "$2" '{cwd:$cwd,tool_input:$ti}' | /bin/bash "$S/$1.sh" 2>/dev/null
}
decision() { # $1 label  $2 script  $3 tool_input  $4 want (none|allow|deny|ask)
  local out d; out=$(hook "$2" "$3")
  if [ -z "$out" ]; then d=none
  elif ! jq -e . >/dev/null 2>&1 <<<"$out"; then bad "$1: hook output is not JSON" "$out"; return
  else d=$(jq -r '.hookSpecificOutput.permissionDecision // "none"' <<<"$out"); fi
  [ "$d" = "$4" ] && ok || bad "$1: want $4, got $d" "$out"
}
contains() { # $1 label  $2 haystack  $3 needle
  case "$2" in *"$3"*) ok;; *) bad "$1: expected '$3'" "$2";; esac
}
context() { # $1 script -> additionalContext text (asserts valid JSON)
  local out; out=$(hook "$1" '{}')
  jq -e . >/dev/null 2>&1 <<<"$out" || { bad "$1: output is not JSON" "$out"; return; }
  jq -r '.hookSpecificOutput.additionalContext // ""' <<<"$out"
}
art() { # $1 file  $2 status line
  printf -- '---\nid: 0001-x\n%s\n---\n\n# body\nstatus: not-frontmatter\n' "$2" > "sdlc/0001-x/$1"
}

echo "== not adopted: no .sdlc/config.json → every hook is silent"
touch .sdlc/lock-tests
decision "edit w/o config"   guard-edit '{"file_path":"tests/a.test.js"}' none
[ -z "$(hook session-context '{}')" ] && ok || bad "session-context w/o config" "$(hook session-context '{}')"
[ -z "$(hook prompt-context '{}')" ]  && ok || bad "prompt-context w/o config" "$(hook prompt-context '{}')"
rm .sdlc/lock-tests
cp "$P/presets/generic.json" .sdlc/config.json

echo "== drive off (default): context hooks silent, gates live"
[ -z "$(hook session-context '{}')" ] && ok || bad "session-context with drive off" "$(hook session-context '{}')"
[ -z "$(hook prompt-context '{}')" ]  && ok || bad "prompt-context with drive off" "$(hook prompt-context '{}')"
touch .sdlc/lock-tests
decision "gate live with drive off"  guard-edit '{"file_path":"'"$T"'/tests/a.test.js"}' deny
rm .sdlc/lock-tests
jq '.drive="suggest"' .sdlc/config.json > t.json && mv t.json .sdlc/config.json
contains "suggest injects the pointer" "$(context session-context)" "drive: suggest"
[ -z "$(hook prompt-context '{}')" ]  && ok || bad "prompt-context silent in suggest" "$(hook prompt-context '{}')"
jq '.drive="auto"' .sdlc/config.json > t.json && mv t.json .sdlc/config.json

echo "== jq missing → gates fail closed with a message, not silently open"
mkdir -p "$T/nojq"; ln -s "$(command -v cat)" "$T/nojq/cat"; ln -s "$(command -v dirname)" "$T/nojq/dirname"
touch .sdlc/lock-tests
ERR=$(printf '{"cwd":"%s","tool_input":{"file_path":"tests/a.test.js"}}' "$T" | PATH="$T/nojq" /bin/bash "$S/guard-edit.sh" 2>&1 >/dev/null); RC=$?
[ "$RC" = 2 ] && ok || bad "guard-edit without jq: want exit 2, got $RC" "$ERR"
contains "guard-edit without jq names jq" "$ERR" "jq is not installed"
OUT=$(printf '{"cwd":"%s"}' "$T" | PATH="$T/nojq" /bin/bash "$S/session-context.sh" 2>/dev/null)
contains "session-context without jq warns in context" "$OUT" "jq is not installed"
rm .sdlc/lock-tests

echo "== driver: no active change"
: > .sdlc/current
contains "session no change" "$(context session-context)" "No active change"
contains "prompt no change"  "$(context prompt-context)"  "/sdlc:intent"
[ -z "$(hook stage-advanced '{}')" ] && ok || bad "stage-advanced no change" "x"

echo "== driver: status parsing and stage progression"
echo 0001-x > .sdlc/current
art intent.md 'status: draft              # draft | accepted | rejected'
C=$(context prompt-context); contains "trailing comment stripped" "$C" "intent=draft spec=-"; contains "stage intent" "$C" "Current stage: intent"
art intent.md 'status: "accepted"'
contains "quoted status" "$(context prompt-context)" "Current stage: spec. Next: /sdlc:spec"
art spec.md 'status: accepted'
contains "plan waiting" "$(context prompt-context)" "Current stage: plan"
art plan.md 'status: draft'
contains "plan draft waits on human" "$(context session-context)" "waiting on the user"
art plan.md 'status: approved'
contains "build next" "$(context prompt-context)" "Current stage: build. Next: /sdlc:build"
art plan.md 'status: implemented'
C=$(context prompt-context); contains "review next" "$C" "Current stage: review"; contains "verify rides along" "$C" "/sdlc:verify then /sdlc:review"
art findings.md 'status: reviewed'
C=$(context prompt-context); contains "gates met" "$C" "All artifact gates met"; contains "done offered" "$C" "/sdlc:done"
rm sdlc/0001-x/findings.md

echo "== stop hook: speaks only when the state changes"
rm -f .sdlc/.laststate
[ -z "$(hook stage-advanced '{}')" ] && ok || bad "first observation silent" "x"
[ -z "$(hook stage-advanced '{}')" ] && ok || bad "unchanged state silent" "x"
art plan.md 'status: approved'
contains "advance announced" "$(hook stage-advanced '{}')" "systemMessage"

echo "== guard-edit: test lock, protected paths, notebooks"
decision "test file, no lock"        guard-edit '{"file_path":"'"$T"'/tests/a.test.js"}' none
touch .sdlc/lock-tests
decision "test file, locked"         guard-edit '{"file_path":"'"$T"'/tests/a.test.js"}' deny
decision "src file, locked"          guard-edit '{"file_path":"'"$T"'/src/a.js"}' none
decision "notebook in tests, locked" guard-edit '{"notebook_path":"'"$T"'/tests/nb.ipynb"}' deny
rm .sdlc/lock-tests
decision "protected workflow (abs)"  guard-edit '{"file_path":"'"$T"'/.github/workflows/ci.yml"}' deny
decision "protected workflow (rel)"  guard-edit '{"file_path":".github/workflows/ci.yml"}' deny
decision "ordinary file"             guard-edit '{"file_path":"'"$T"'/src/a.js"}' none

echo "== guard-bash: production gate and irreversible actions"
decision "plain ls"                  guard-bash '{"command":"ls -la"}' none
decision "deploy prod, no approval"  guard-bash '{"command":"make deploy-prod"}' deny
SDLC_RELEASE_APPROVAL=someone; export SDLC_RELEASE_APPROVAL
decision "deploy prod, approved"     guard-bash '{"command":"make deploy-prod"}' none
unset SDLC_RELEASE_APPROVAL
decision "rm -rf /tmp/build is fine" guard-bash '{"command":"rm -rf /tmp/build"}' none
decision "rm -rf ./dist is fine"     guard-bash '{"command":"rm -rf ./dist"}' none
decision "rm -rf / asks"             guard-bash '{"command":"rm -rf /"}' ask
decision "rm -rf /* asks"            guard-bash '{"command":"sudo rm -rf /*"}' ask
decision "force push asks"           guard-bash '{"command":"git push --force origin main"}' ask
decision "reset --hard asks"         guard-bash '{"command":"git reset --hard HEAD~1"}' ask
decision "DROP TABLE asks"           guard-bash '{"command":"psql -c \"DROP TABLE users\""}' ask

echo "== guard-commit: plan sync"
printf '# Plan\n\n## Files that change\n- `src/b.js` (modify)\n' > sdlc/0001-x/plan.md
echo y >> src/a.js; git add src/a.js
decision "unplanned file asks"       guard-commit '{"command":"git commit -m x"}' ask
contains "message points at /sdlc:done" "$(hook guard-commit '{"command":"git commit -m x"}')" "/sdlc:done"
git reset -q; git checkout -q src/a.js
echo y >> src/b.js; git add src/b.js
decision "planned file silent"       guard-commit '{"command":"git commit -m x"}' none
git reset -q; git checkout -q src/b.js
echo y >> CLAUDE.md; echo '{}' > evals/0001.json; git add CLAUDE.md evals/0001.json
decision "loop artifacts exempt"     guard-commit '{"command":"git commit -m x"}' none
git reset -q; git checkout -q CLAUDE.md; rm evals/0001.json
echo y >> src/a.js; git add src/a.js
: > .sdlc/current
decision "closed change silent"      guard-commit '{"command":"git commit -m x"}' none
echo 0001-x > .sdlc/current
git reset -q; git checkout -q src/a.js

echo "== format.sh: code only, never artifacts or prose"
printf '#!/bin/bash\necho "$1" >> "%s/fmt.log"\n' "$T" > "$T/fmt.sh"; chmod +x "$T/fmt.sh"
jq --arg f "$T/fmt.sh" '.format_command=$f' .sdlc/config.json > t.json && mv t.json .sdlc/config.json
hook format '{"file_path":"'"$T"'/src/a.js"}' >/dev/null
hook format '{"file_path":"'"$T"'/sdlc/0001-x/intent.md"}' >/dev/null
hook format '{"file_path":"'"$T"'/README.md"}' >/dev/null
LOG=$(cat "$T/fmt.log" 2>/dev/null)
contains "code file formatted" "$LOG" "src/a.js"
case "$LOG" in *intent.md*|*README.md*) bad "artifact/prose formatted" "$LOG";; *) ok;; esac

echo "== doctor: dead globs fail only when the gate is on; preview mode"
jq '.gates.test_lock.test_globs=["**/nothing_*"]' .sdlc/config.json > "$T/dead.json"
"$S/doctor.sh" "$T" "$T/dead.json" >/dev/null 2>&1 && bad "dead test glob should FAIL" "$("$S/doctor.sh" "$T" "$T/dead.json" 2>&1 | tail -2)" || ok
jq '.gates.test_lock.enabled=false | ._gate_level="minimal"' "$T/dead.json" > "$T/off.json"
OUT=$("$S/doctor.sh" "$T" "$T/off.json" 2>&1); RC=$?
[ "$RC" = 0 ] && ok || bad "disabled gate must not fail" "$OUT"
contains "preview banner" "$OUT" "PREVIEW"
contains "level shown" "$OUT" "gate level: minimal"
contains "disabled reported" "$OUT" "test_lock is disabled"

echo "== doctor runs clean on the fixture"
"$S/doctor.sh" "$T" >/dev/null 2>&1 && ok || bad "doctor exit status" "$("$S/doctor.sh" "$T" 2>&1 | tail -3)"

echo
echo "RESULT pass=$PASS fail=$FAIL"
[ "$FAIL" -eq 0 ]
