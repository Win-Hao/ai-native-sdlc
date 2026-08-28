#!/bin/bash
# eval-test-before-fix — mechanical checks. Runs with cwd = workspace; see bin/lib.sh.
set -u
CASE="$(cd "$(dirname "$0")" && pwd)"; source "$CASE/../bin/lib.sh"
CHANGED=$(changed_files)

# ---- score (arm-neutral) ----
rc=$(run_tests npm-test.log)
emit score "$([ "$rc" = 0 ] && echo 1 || echo 0)" "Repository tests pass (npm test)" "exit $rc: $(grep -E '^ℹ (pass|fail)' npm-test.log | tr '\n' ' ')"

tests_changed=$(printf '%s\n' "$CHANGED" | grep -E '^tests/' | grep -v 'zz-hidden' || true)
ok=0; [ -n "$tests_changed" ] && git diff --cached start -- $tests_changed | grep -qE '^\+.*throws' && ok=1
emit score $ok "A regression test asserting the throw was added under tests/" "test files changed: ${tests_changed:-none}"

emit score "$(printf '%s\n' "$CHANGED" | grep -qx 'src/inventory.js' && echo 1 || echo 0)" "The fix touches the inventory layer (src/inventory.js)" "src changes: $(printf '%s\n' "$CHANGED" | grep '^src/' | tr '\n' ' ')"

hidden_check "$CASE/hidden/oversell.acceptance.test.js" zz-hidden-oversell.test.js

# ---- indicators (with-only) ----
ti=$(first_commit_touching '^tests/'); si=$(first_commit_touching '^src/')
ok=0; [ -n "$ti" ] && [ -n "$si" ] && [ "$ti" -lt "$si" ] && ok=1
emit indicator $ok "The failing test was committed before the fix (tests/ commit precedes src/ commit)" "first tests commit #${ti:-none}, first src commit #${si:-none}"
n=$(git rev-list --count start..HEAD 2>/dev/null || echo 0)
emit indicator "$([ "$n" -ge 2 ] && echo 1 || echo 0)" "Test and fix landed as separate commits" "commits after start: $n"
emit indicator "$(git log start..HEAD --format=%s | grep -qiE '^(test|fix)\b' && echo 1 || echo 0)" "Commit messages follow the test(...)/fix(...) convention" "$(git log start..HEAD --format=%s | head -3 | tr '\n' '|')"
