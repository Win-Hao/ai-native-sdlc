#!/bin/bash
# Check that .stagekit/config.json actually matches this repo.
# A preset that matches nothing is a gate that protects nothing.
# Usage: doctor.sh [repo-root] [config-file]
#   config-file defaults to <repo-root>/.stagekit/config.json. Pass a candidate
#   file to preview a configuration before it goes live.
ROOT="${1:-${CLAUDE_PROJECT_DIR:-$PWD}}"
command -v jq >/dev/null 2>&1 || { echo "FAIL  jq is not installed — every StageKit hook and this doctor need it (macOS: brew install jq — Debian/Ubuntu: apt install jq)"; exit 1; }
LIVE="$ROOT/.stagekit/config.json"
CFG="${2:-$LIVE}"
[ -f "$CFG" ] || { echo "FAIL  no $CFG — run /stagekit:init"; exit 1; }
jq -e . "$CFG" >/dev/null 2>&1 || { echo "FAIL  $CFG is not valid JSON"; exit 1; }
cd "$ROOT" || exit 1

WARN=0; FAIL=0
say() { printf '%-6s %s\n' "$1" "$2"; }
enabled() { [ "$(jq -r ".gates.$1.enabled // false" "$CFG")" = "true" ]; }

files() { git ls-files 2>/dev/null || find . -type f -not -path './.git/*'; }
ALL=$(files | sed 's|^\./||')

count_glob() { # $1=glob  -> number of tracked files matching
  local g="$1" n=0 p
  while IFS= read -r p; do
    [[ "$p" == $g ]] && { n=$((n+1)); continue; }
    local a="${g#\*\*/}"; [[ "$p" == $a ]] && { n=$((n+1)); continue; }
    local b="${g%/\*\*}"; [[ "$p" == $b ]] && n=$((n+1))
  done <<<"$ALL"
  echo "$n"
}

[ "$CFG" != "$LIVE" ] && echo "== PREVIEW of $CFG — nothing is enforced until it is at .stagekit/config.json"
echo "== preset: $(jq -r '._preset // "custom"' "$CFG")  gate level: $(jq -r '._gate_level // "full"' "$CFG")  drive: $(jq -r '.drive // "off"' "$CFG")  files tracked: $(wc -l <<<"$ALL" | tr -d ' ')"

echo
echo "-- test_lock: globs that match no file are dead gates"
if enabled test_lock; then
  TOTAL_TESTS=0
  while IFS= read -r g; do
    [ -z "$g" ] && continue
    n=$(count_glob "$g"); TOTAL_TESTS=$((TOTAL_TESTS+n))
    [ "$n" -eq 0 ] && { say "WARN" "delete or fix — matches no file  $g"; WARN=$((WARN+1)); } || say "ok" "$n files  $g"
  done < <(jq -r '.gates.test_lock.test_globs[]? // empty' "$CFG")
  [ "$TOTAL_TESTS" -eq 0 ] && { say "FAIL" "no test file matches any glob — the test lock protects nothing"; FAIL=$((FAIL+1)); }
else
  say "off" "test_lock is disabled — /stagekit:gate raises the level"
fi

echo
echo "-- protected_paths"
if enabled protected_paths; then
  while IFS= read -r g; do
    [ -z "$g" ] && continue
    n=$(count_glob "$g")
    [ "$n" -eq 0 ] && { say "WARN" "delete or fix — matches no file  $g"; WARN=$((WARN+1)); } || say "ok" "$n files  $g"
  done < <(jq -r '.gates.protected_paths.paths[]? // empty' "$CFG")
else
  say "off" "protected_paths is disabled — /stagekit:gate raises the level"
fi

echo
echo "-- production_gate: patterns should appear in real deploy commands"
if enabled production_gate; then
  HAY=$(cat Makefile justfile package.json .github/workflows/* .gitlab-ci.yml 2>/dev/null)
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    # every literal segment of the pattern must appear somewhere in the build/CI files
    hit=1; rest="$HAY"
    IFS='*' read -ra segs <<<"$p"
    for s in "${segs[@]}"; do
      [ -z "$s" ] && continue
      case "$rest" in
        *"$s"*) rest="${rest#*"$s"}" ;;
        *) hit=0; break ;;
      esac
    done
    if [ "$hit" = 1 ]; then say "ok" "$p"; else say "WARN" "delete or fix — not found in Makefile/package.json/CI  $p"; WARN=$((WARN+1)); fi
  done < <(jq -r '.gates.production_gate.match[]? // empty' "$CFG")
else
  say "off" "production_gate is disabled"
fi

echo
echo "-- irreversible / plan_sync"
enabled irreversible && say "ok" "irreversible: $(jq -r '.gates.irreversible.match // [] | length' "$CFG") patterns ask before they run" || say "off" "irreversible is disabled"
enabled plan_sync && say "ok" "plan_sync: commits are checked against plan.md" || say "off" "plan_sync is disabled — turn it on once plan.md is read before every implementation"

echo
echo "-- feedback loop"
if [ -f CLAUDE.md ]; then
  grep -qi '^## Commands' CLAUDE.md && say "ok" "CLAUDE.md has a Commands section" || { say "FAIL" "CLAUDE.md has no ## Commands section"; FAIL=$((FAIL+1)); }
  grep -qi 'verif' CLAUDE.md && say "ok" "CLAUDE.md states how to verify work" || { say "WARN" "CLAUDE.md has no verification block"; WARN=$((WARN+1)); }
  L=$(wc -l < CLAUDE.md | tr -d ' ')
  [ "$L" -gt 80 ] && { say "WARN" "CLAUDE.md is $L lines — it is read in full every session; cut to ~one page"; WARN=$((WARN+1)); } || say "ok" "CLAUDE.md is $L lines"
else
  say "FAIL" "no CLAUDE.md"; FAIL=$((FAIL+1))
fi
[ -f REVIEW.md ] && say "ok" "REVIEW.md present" || { say "WARN" "no REVIEW.md — review passes will be inconsistent"; WARN=$((WARN+1)); }

FMT=$(jq -r '.format_command // empty' "$CFG")
if [ -n "$FMT" ]; then
  BIN="${FMT%% *}"
  case "$BIN" in
    npx) # npx downloads whatever is not installed — check the local binary instead
      PKG=$(echo "$FMT" | awk '{for(i=2;i<=NF;i++) if ($i !~ /^-/) {print $i; exit}}')
      [ -x "node_modules/.bin/$PKG" ] && say "ok" "format_command: $FMT (node_modules/.bin/$PKG)" \
        || { say "WARN" "format_command: $PKG is not installed locally — npx would download it on every edit. npm i -D $PKG, or set format_command to null"; WARN=$((WARN+1)); } ;;
    *)
      { [ -x "$BIN" ] || command -v "$BIN" >/dev/null 2>&1; } && say "ok" "format_command: $FMT" \
        || { say "WARN" "format_command not found: $FMT — install it or set format_command to null"; WARN=$((WARN+1)); } ;;
  esac
fi

echo
echo "-- artifact chain"
if [ "$CFG" = "$LIVE" ]; then
  DIR=$(jq -r '.artifact_dir // "stagekit"' "$CFG")
  [ -d "$DIR" ] && say "ok" "$DIR/ exists ($(ls -1 "$DIR" 2>/dev/null | grep -c '^[0-9]') changes)" || { say "WARN" "no $DIR/ directory"; WARN=$((WARN+1)); }
  [ -s .stagekit/current ] && say "ok" "active change: $(tr -d '[:space:]' < .stagekit/current)" || say "ok" "no active change — /stagekit:intent starts one"
else
  say "skip" "preview — the artifact chain is checked once the config is live"
fi

echo
echo "RESULT fail=$FAIL warn=$WARN"
[ "$FAIL" -gt 0 ] && exit 1 || exit 0
