---
name: evals
description: Stage 4 Test (b) — build and run the eval suite that regression-tests the configuration steering the agent (CLAUDE.md, skills, hooks), and turn each production incident into a permanent eval.
argument-hint: "[add | run | ci]"
disable-model-invocation: true
allowed-tools: Read Write Edit Glob Grep Bash
---

# Stage 4b — Continuous evals

Evals are the AI-native equivalent of stage-gate QA. `CLAUDE.md`, skills and
hooks steer the agent, so they deserve the regression testing code gets.

---

## `add` — write an eval

An eval is a prompt plus the checks that define acceptable. Source them from
real work, not invented tasks:

- **20–50 real tasks** from recent commits, with their accepted outcome.
- **Every production incident** becomes an eval, written by whoever owned the
  incident, and stays in the suite forever as a regression test.
- **Every fixed vulnerability** becomes an eval for its class.

Format: `evals/<id>.json`, from `.stagekit/templates/eval.example.json` if the project has one, otherwise `${CLAUDE_PLUGIN_ROOT}/templates/eval.example.json`.
Checks must be mechanical — exit codes, greps, file assertions. A check that
requires a human to read the output is not a check.

Keep the suite live: as models improve, cases that no longer discriminate get
retired and new ones added from monitoring.

---

## `run` — run the suite locally

```
for e in evals/*.json; do
  claude -p "$(jq -r '.prompt' "$e")" \
    --allowedTools "$(jq -r '.allowed_tools' "$e")" \
    --output-format json > result.json
  ./evals/check.sh "$e" result.json
done
```

Report the pass rate and, for each failure, which check failed and on what.
Compare against the last recorded run — the trend matters more than the number.

---

## `ci` — wire it into CI

Create `.github/workflows/agent-evals.yml` (adapt for other CI):

- Triggers: `pull_request` on paths `['CLAUDE.md', '.claude/**', 'REVIEW.md']`,
  plus a nightly schedule.
- Runs the suite non-interactively with a scoped `ANTHROPIC_API_KEY`.
- **Gates configuration changes on the pass rate.** A skill edit that drops the
  rate gets reviewed before it merges. Without the gate the suite is a dashboard,
  not a control.

Set a budget on the key before turning the schedule on, and say what it costs.
