#!/bin/bash
# eval-resume-handoff — mechanical checks. Runs with cwd = workspace; see bin/lib.sh.
# Outcome bar = the same returns contract as eval-plan-before-code, reached across a handoff.
set -u
CASE="$(cd "$(dirname "$0")" && pwd)"; source "$CASE/../bin/lib.sh"
CHANGED=$(changed_files)

# ---- score (arm-neutral) ----
rc=$(run_tests npm-test.log)
emit score "$([ "$rc" = 0 ] && echo 1 || echo 0)" "Repository tests pass (npm test)" "exit $rc: $(grep -E '^ℹ (pass|fail)' npm-test.log | tr '\n' ' ')"

ok=0; [ -f src/returns.js ] && grep -q 'ReturnWindowExpired' src/returns.js && ok=1
emit score $ok "src/returns.js exists and defines ReturnWindowExpired" "$([ -f src/returns.js ] && echo 'file present' || echo 'file missing')"

added=$(printf '%s\n' "$CHANGED" | grep -E '^tests/' | grep -v 'zz-hidden' || true)
ok=0; [ -n "$added" ] && grep -lq 'returnItems' $added 2>/dev/null && ok=1
emit score $ok "Tests for the returns flow were added under tests/" "changed test files: ${added:-none}"

ok=1; for f in src/inventory.js src/pricing.js src/orders.js; do printf '%s\n' "$CHANGED" | grep -qx "$f" && ok=0; done
emit score $ok "Unrelated modules untouched (inventory, pricing, orders)" "src changes: $(printf '%s\n' "$CHANGED" | grep '^src/' | tr '\n' ' ')"

hidden_check "$CASE/../eval-plan-before-code/hidden/returns.acceptance.test.js" zz-hidden-returns.test.js

# ---- indicators (with-only) ----
plan=$(ls stagekit/*/plan.md 2>/dev/null | head -1)
pi=$(first_commit_touching '^stagekit/[^/]+/plan\.md$'); si=$(first_commit_touching '^src/')
ok=0; [ -n "$pi" ] && [ -n "$si" ] && [ "$pi" -lt "$si" ] && ok=1
emit indicator $ok "plan.md was committed before the first commit touching src/" "plan commit #${pi:-none}, first src commit #${si:-none}"
if [ -n "$plan" ]; then
  st=$(artifact_status "$plan")
  emit indicator "$([ "$st" = implemented ] && echo 1 || echo 0)" "plan.md reached status: implemented by the end of phase B" "status: ${st:-none}"
else
  emit indicator 0 "plan.md reached status: implemented by the end of phase B" "no plan.md"
fi
intent=$(ls stagekit/*/intent.md 2>/dev/null | head -1)
emit indicator "$([ -n "$intent" ] && echo 1 || echo 0)" "intent.md was written" "${intent:-none}"
