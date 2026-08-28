#!/bin/bash
# Stage 3 plan sync: the committed diff must match the committed plan.md.
IN=$(cat)
source "$(dirname "$0")/_common.sh"
CWD=$(hook_cwd)
ROOT=$(stagekit_root "$CWD") || exit 0
need_jq gate
gate_on plan_sync || exit 0

ID=$(current_id); [ -z "$ID" ] && exit 0   # no open change — see /stagekit:done
DIR=$(cfg '.artifact_dir'); DIR=${DIR:-stagekit}
PLAN="$ROOT/$DIR/$ID/plan.md"
[ -f "$PLAN" ] || exit 0

STAGED=$(cd "$ROOT" && git diff --cached --name-only 2>/dev/null)
[ -z "$STAGED" ] && exit 0

# Paths the plan names: backticked tokens with no spaces that look like a path
# (contain a '/') or like a file (have an extension).
PLANNED=$(grep -o '`[^`]*`' "$PLAN" | tr -d '`' \
  | grep -v ' ' | grep -E '/|\.[A-Za-z0-9]+$' | sort -u)

# Files the loop writes about itself are never "unplanned": review feeds
# CLAUDE.md, evals add evals/, gates and skills live in .claude/.
EXEMPT=$(cfg '.gates.plan_sync.exempt[]?')
[ -z "$EXEMPT" ] && EXEMPT=$'CLAUDE.md\nREVIEW.md\nevals/**\n.claude/**'

UNPLANNED=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  case "$f" in "$DIR"/*|.stagekit/*) continue;; esac
  skip=0
  while IFS= read -r g; do
    [ -n "$g" ] && match_glob "$f" "$g" && { skip=1; break; }
  done <<<"$EXEMPT"
  [ "$skip" = 1 ] && continue
  grep -qxF "$f" <<<"$PLANNED" || UNPLANNED="$UNPLANNED  $f"$'\n'
done <<<"$STAGED"

[ -z "$UNPLANNED" ] && exit 0

ask "These staged files are not named in $DIR/$ID/plan.md:

$UNPLANNED
The implementation departed from the approved plan. Before committing, update
plan.md — add the files under 'Files that change' and record why under
'Deviations' — and stage it in the same commit.
(If change $ID has shipped, close it with /stagekit:done and this check stops.)"
