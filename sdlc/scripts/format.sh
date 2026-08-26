#!/bin/bash
# Optional: run the project's formatter on the code file that just changed.
IN=$(cat)
source "$(dirname "$0")/_common.sh"
CWD=$(hook_cwd)
ROOT=$(sdlc_root "$CWD") || exit 0
need_jq context
FMT=$(cfg '.format_command'); [ -z "$FMT" ] || [ "$FMT" = "null" ] && exit 0
FILE=$(jq -r '.tool_input.file_path // empty' <<<"$IN"); [ -z "$FILE" ] && exit 0

# Process artifacts and prose are not code. A code formatter reflowing
# intent.md is churn in the audit trail, not drift prevention.
DIR=$(cfg '.artifact_dir'); DIR=${DIR:-sdlc}
REL=$(rel_path "$FILE")
case "$REL" in *.md|*.markdown|"$DIR"/*|.sdlc/*|.claude/*) exit 0;; esac

( cd "$ROOT" && eval "$FMT \"$FILE\"" ) >/dev/null 2>&1
exit 0
