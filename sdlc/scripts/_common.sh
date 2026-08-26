#!/bin/bash
# Shared helpers for SDLC gates. Every gate is a no-op unless the project
# has been initialized with /sdlc:init (i.e. .sdlc/config.json exists).
#
# Every hook script opens the same way:
#   IN=$(cat); source _common.sh; CWD=$(hook_cwd); ROOT=$(sdlc_root "$CWD") || exit 0; need_jq gate|context
# Neither the cwd nor the root lookup needs jq, so a repo that has not adopted
# the SDLC is never affected by a missing jq.

have_jq() { command -v jq >/dev/null 2>&1; }

# cwd from the hook payload. Without jq it is empty and sdlc_root falls back
# to CLAUDE_PROJECT_DIR / PWD.
hook_cwd() { have_jq && jq -r '.cwd // empty' <<<"$IN" 2>/dev/null; return 0; }

# Every hook needs jq. Gates fail closed: exit 2 blocks the tool call and the
# reason reaches Claude. Context hooks print the same warning on stdout, which
# SessionStart and UserPromptSubmit inject as context. Silence is not an
# option — it would mean gates that look installed and enforce nothing.
need_jq() {  # $1 = gate | context
  have_jq && return 0
  local m="[SDLC] jq is not installed, so the SDLC hooks cannot run. The gates fail closed: every Edit, Write and Bash call in this repo is blocked until jq is on PATH (macOS: brew install jq — Debian/Ubuntu: apt install jq). Tell the user now."
  if [ "$1" = gate ]; then echo "$m" >&2; exit 2; fi
  echo "$m"; exit 0
}

sdlc_root() {
  local d="${CLAUDE_PROJECT_DIR:-$1}"
  [ -z "$d" ] && d="$PWD"
  while [ "$d" != "/" ] && [ -n "$d" ]; do
    [ -f "$d/.sdlc/config.json" ] && { echo "$d"; return 0; }
    d="$(dirname "$d")"
  done
  return 1
}

cfg() { jq -r "$1 // empty" "$ROOT/.sdlc/config.json" 2>/dev/null; }

gate_on() { [ "$(cfg ".gates.$1.enabled")" = "true" ]; }

# .sdlc/config.json → drive: off (default) | suggest | auto. The gates never
# depend on it; only the three context hooks do.
drive_mode() { case "$(cfg '.drive')" in suggest|auto) cfg '.drive';; *) echo off;; esac; }

# Claude Code accepts exactly allow | deny | ask | defer. Anything else is
# rejected as invalid hook output — and an invalid output silently allows.
deny() {
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

ask() {
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'
  exit 0
}

# match_glob <path> <glob> — tolerates optional leading **/ and trailing /**
match_glob() {
  local p="$1" g="$2"
  [[ "$p" == $g ]] && return 0
  local a="${g#\*\*/}"; [[ "$p" == $a ]] && return 0
  local b="${g%/\*\*}"; [[ "$p" == $b ]] && return 0
  return 1
}

# cmd_has <command> <pattern> — the literal pattern on word boundaries, so
# 'rm -rf /' matches 'rm -rf /' and 'rm -rf /*' but not 'rm -rf /tmp/build'.
cmd_has() {
  local esc; esc=$(printf '%s' "$2" | sed 's,[][\.*^$+?(){}|],\\&,g')
  grep -Eq "(^|[^[:alnum:]_])${esc}(\$|[^[:alnum:]_])" <<<"$1"
}

rel_path() { local p="$1"; p="${p#$ROOT/}"; echo "${p#./}"; }

current_id() { [ -f "$ROOT/.sdlc/current" ] && tr -d '[:space:]' < "$ROOT/.sdlc/current"; }

# --- pipeline resolution ------------------------------------------------
# Reads .sdlc/config.json .pipeline (falls back to the built-in six stages).
# Sets: PS_STATE (per-artifact status), PS_STAGE (current stage id),
#       PS_NEXT (next action), PS_WAITING (1 if waiting on a human),
#       PS_CHAIN (stage ids joined for display).
DEFAULT_PIPELINE='[{"id":"intent","artifact":"intent.md","done_when":"accepted","command":"/sdlc:intent","draft_hint":"Review it — set status: accepted to open the next stage."},{"id":"spec","artifact":"spec.md","done_when":"accepted","command":"/sdlc:spec","draft_hint":"Resolve its flagged concerns, then set status: accepted."},{"id":"plan","artifact":"plan.md","done_when":"approved","command":"/sdlc:plan","draft_hint":"Interrogate it, then set status: approved."},{"id":"build","artifact":"plan.md","done_when":"implemented","command":"/sdlc:build","draft_hint":null},{"id":"verify","artifact":null,"command":"/sdlc:verify"},{"id":"review","artifact":null,"command":"/sdlc:review"}]'

# Unit separator, not tab: an IFS of whitespace collapses empty fields.
US=$'\x1f'

pipeline_rows() {
  jq -r --argjson d "$DEFAULT_PIPELINE" --arg us "$US" \
    '(.pipeline // $d)[] | [.id, (.artifact//""), (.done_when//""), (.command//""), (.draft_hint//"")] | join($us)' \
    "$ROOT/.sdlc/config.json" 2>/dev/null
}

pipeline_chain() { pipeline_rows | cut -d"$US" -f1 | tr '\n' '|' | sed 's/|$//; s/|/ -> /g'; }
pipeline_first_cmd() { pipeline_rows | head -1 | cut -d"$US" -f4; }
pipeline_first_id()  { pipeline_rows | head -1 | cut -d"$US" -f1; }

# status from the artifact's YAML frontmatter only. Trailing comments and
# quotes are ignored, so `status: accepted   # draft | accepted` is accepted.
artifact_status() {
  [ -f "$1" ] || return 0
  awk 'NR==1 { if ($0 != "---") exit; next }
       $0 == "---" { exit }
       sub(/^status:[ \t]*/, "") { sub(/[ \t]*#.*$/, ""); sub(/[ \t]+$/, ""); print; exit }' "$1" | tr -d "\"'"
}

pipeline_state() {  # $1 = absolute artifact dir of the active change
  local A="$1" id art dw cmd hint st
  PS_STATE=""; PS_STAGE=""; PS_NEXT=""; PS_WAITING=0
  local ids=() arts=() dws=() cmds=() hints=() tail_cmds="" seen_arts=""
  while IFS="$US" read -r id art dw cmd hint; do
    ids+=("$id"); arts+=("$art"); dws+=("$dw"); cmds+=("$cmd"); hints+=("$hint")
  done < <(pipeline_rows)

  # For an artifact touched by several stages, its done_when values form the
  # progression (plan.md: approved -> implemented). A stage is done once the
  # file's status has reached that point or later.
  progress_idx() {  # $1=artifact $2=value  -> index in the artifact's progression, -1 if absent
    local a="$1" v="$2" n=0 i
    for i in "${!ids[@]}"; do
      [ "${arts[$i]}" = "$a" ] || continue
      [ "${dws[$i]}" = "$v" ] && { echo "$n"; return; }
      n=$((n+1))
    done
    echo "-1"
  }

  local resolved=0 i
  for i in "${!ids[@]}"; do
    art="${arts[$i]}"
    if [ -z "$art" ]; then
      [ -z "$tail_cmds" ] && tail_cmds="${cmds[$i]}" || tail_cmds="$tail_cmds then ${cmds[$i]}"
      continue
    fi
    st=$(artifact_status "$A/$art"); [ -z "$st" ] && st="-"
    case "$US$seen_arts$US" in
      *"$US$art$US"*) ;;
      *) seen_arts="$seen_arts$art$US"; PS_STATE="$PS_STATE${art%.md}=$st " ;;
    esac
    [ "$resolved" = 1 ] && continue
    local mine cur
    mine=$(progress_idx "$art" "${dws[$i]}")
    cur=$(progress_idx "$art" "$st")
    if [ "$st" = "-" ]; then
      PS_STAGE="${ids[$i]}"; PS_NEXT="${cmds[$i]}"; resolved=1
    elif [ "$cur" -lt "$mine" ]; then
      PS_STAGE="${ids[$i]}"; resolved=1
      # A draft_hint means a human has to move this gate. No hint means the
      # stage is an agent action that simply has not run yet.
      if [ -n "${hints[$i]}" ]; then
        PS_WAITING=1; PS_NEXT="${hints[$i]}"
      else
        PS_NEXT="${cmds[$i]}"
      fi
    fi
  done
  if [ "$resolved" = 0 ]; then
    # Trailing stages (verify, review) have no artifact to check, so the driver
    # keeps naming them until the human closes the change with /sdlc:done.
    PS_STAGE="done"
    PS_NEXT="${tail_cmds:+$tail_cmds, then }/sdlc:done to close the change"
  fi
  PS_STATE="${PS_STATE% }"
}
