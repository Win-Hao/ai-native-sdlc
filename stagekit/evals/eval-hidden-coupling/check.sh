#!/bin/bash
# eval-hidden-coupling — mechanical checks. Runs with cwd = workspace; see bin/lib.sh.
set -u
CASE="$(cd "$(dirname "$0")" && pwd)"; source "$CASE/../bin/lib.sh"
CHANGED=$(changed_files)

# ---- score (arm-neutral) ----
rc=$(run_tests npm-test.log)
emit score "$([ "$rc" = 0 ] && echo 1 || echo 0)" "Repository tests pass (npm test)" "exit $rc: $(grep -E '^ℹ (pass|fail)' npm-test.log | tr '\n' ' ')"

emit score "$(printf '%s\n' "$CHANGED" | grep -qx 'src/audit.js' && echo 1 || echo 0)" "The audit module was updated for the new id shape" "src changes: $(printf '%s\n' "$CHANGED" | grep '^src/' | tr '\n' ' ')"

ok=1; for f in src/inventory.js src/pricing.js src/report.js; do printf '%s\n' "$CHANGED" | grep -qx "$f" && ok=0; done
emit score $ok "Unrelated modules untouched (inventory, pricing, report)" "src changes: $(printf '%s\n' "$CHANGED" | grep '^src/' | tr '\n' ' ')"

hidden_check "$CASE/hidden/orderid.acceptance.test.js" zz-hidden-orderid.test.js

# ---- indicators (with-only) ----
plan=$(ls stagekit/*/plan.md 2>/dev/null | head -1)
pi=$(first_commit_touching '^stagekit/[^/]+/plan\.md$'); si=$(first_commit_touching '^src/')
ok=0; [ -n "$pi" ] && [ -n "$si" ] && [ "$pi" -lt "$si" ] && ok=1
emit indicator $ok "plan.md was committed before the first commit touching src/" "plan commit #${pi:-none}, first src commit #${si:-none}"
if [ -n "$plan" ]; then
  miss=""; for f in $(printf '%s\n' "$CHANGED" | grep '^src/'); do grep -q "$f" "$plan" || miss="$miss $f"; done
  emit indicator "$([ -z "$miss" ] && echo 1 || echo 0)" "Every changed src/ file is listed in plan.md" "not listed:${miss:- none}"
else
  emit indicator 0 "Every changed src/ file is listed in plan.md" "no plan.md"
fi
intent=$(ls stagekit/*/intent.md 2>/dev/null | head -1)
emit indicator "$([ -n "$intent" ] && echo 1 || echo 0)" "intent.md was written" "${intent:-none}"
