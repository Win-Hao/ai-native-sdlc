# StageKit eval — does the plugin improve outcomes?

An A/B ablation: the same prompt runs against the same fixture repo with the plugin
(`with_skill`) and without it (`without_skill`), N times each, and every run is
scored by the same checks. The delta in pass rate, tokens and time is the answer.

Cases are laid out the way `claude plugin eval` expects (`<case>/prompt.md` +
`graders/*.md`), so once that command is enabled for your account,
`claude plugin eval stagekit --ablation with-without --runs 3` runs the same suite.
Until then, `bin/` runs it with `claude -p`.

## Layout

```
fixture/                     tiny Node library (11 tests) — the repo every run starts from
  .stagekit/config.json      drive: auto, lean pipeline, test_lock on
  .claude/skills/data-policy customer-data policy the third case collides with
  docs/data-retention.md     90-day retention table (policy source of truth)
eval-plan-before-code/       feature spanning ≥5 files (returns flow, fixed contract)
eval-test-before-fix/        seeded bug: removeStock only refuses when stock is exactly 0
eval-flag-not-resolve/       request that conflicts with the policy; setup.sh switches to the full pipeline
  prompt.md                  identical for both arms (natural language, no /stagekit commands)
  graders/criteria.md        rubric for the blind LLM judge (### headings = criteria)
  hidden/*.test.js           acceptance tests copied in at grading time only
  check.sh                   mechanical checks → JSON lines (see bin/lib.sh)
bin/run.sh                   run cases × arms × N   → workspace/iteration-<I>/…
bin/grade.sh                 check.sh (+ -j blind judge) → grading.json per run
bin/aggregate.sh             skill-creator's aggregate_benchmark → benchmark.md, viewer
```

## Run

```bash
# prerequisites: claude CLI logged in, jq, node ≥ 21, git; skill-creator skill for aggregate
bin/run.sh -n 1 -a with_skill eval-test-before-fix   # smoke test one run first, read its transcript
bin/run.sh -n 3                                      # 3 cases × 2 arms × 3 runs (≈18 runs)
bin/grade.sh -j                                      # mechanical checks + blind judge (haiku)
bin/aggregate.sh                                     # benchmark.md + the viewer command
```

Knobs: `MODEL` (executor, default `claude-opus-5`, passed explicitly to both arms so the CLI default never leaks in), `MAX_BUDGET_USD` (per run, default 20 — a runaway guard, not a budget; a with-arm run reports \$3–6),
`JUDGE_MODEL` (default sonnet — haiku dropped and misjudged criteria in testing), `ALLOWED_TOOLS`, `-i N` for a new iteration after changing
the plugin. Finished runs are skipped, so an interrupted batch resumes.

During a run the *installed* `stagekit` plugin is disabled (re-enabled on exit): the with
arm loads the plugin from this checkout via `--plugin-dir`, the without arm loads nothing
and has `.stagekit/` stripped from its workspace.

## Scoring

Each `check.sh` line has a scope:

- **score** — arm-neutral outcome quality: repo tests pass, hidden acceptance tests
  (one expectation per test), scope discipline, policy not violated. Counts toward
  `pass_rate` in both arms. `-j` adds the judge's criteria to the same pool.
- **indicator** — "did the plugin's process happen": plan.md committed before src/,
  failing test committed before the fix, flagged concern with an owner. With-only;
  reported, never scored — the same split `claude plugin eval` makes for with-only graders.

Read `benchmark.md` with the analyst's questions: which score expectations pass in both
arms regardless (they measure nothing — retire them), which cases have high variance
(flaky — more runs or a sharper prompt), and what the token/time delta buys.

## What the cases are trying to catch

| Case | Baseline failure it is designed to expose | Hard evidence |
|---|---|---|
| plan-before-code | coding a multi-file change without a plan → contract details missed, unrelated files touched | 4 hidden acceptance tests; untouched-module check; plan.md ⊇ changed files (indicator) |
| test-before-fix | patching the visible symptom (`placeOrder`) instead of the seam (`removeStock`), no regression test, non-atomic orders left silently | 4 hidden tests incl. the atomicity stretch; test commit precedes fix commit (indicator) |
| flag-not-resolve | silently storing email/name on orders and rewriting retention to 2 years because the user asked | grep for `email` in src/; retention doc unchanged; owners named in the final message; flagged-concern row (indicator) |

## Limitations — read before trusting a number

- **Human gates are pre-authorised.** Headless runs cannot stop for a person, so every
  prompt says checkpoints that only need the user's OK count as approved. The suite
  measures the artifact chain and the ordering discipline, not the value of a human
  actually reading `plan.md`.
- **Plan mode does not exist in `-p`.** `EnterPlanMode`/`ExitPlanMode` are unavailable headless;
  the plan skill falls back to interrogating the plan inline (observed in the smoke run). The
  plan-before-code ordering still holds, but the harness-enforced edit block does not.
- **Judge blindness is partial.** The diff shown to the judge excludes `stagekit/` and
  `.stagekit/`, but the final message may mention commands or artifacts. The rubric tells
  the judge to ignore process; mechanical checks carry the weight.
- **Three cases is a probe, not a verdict.** Add cases from real work (the incidents and
  the changes that went wrong) before drawing conclusions, and do not tune the skills
  to these three prompts.
- **Subagents must be asked for.** The Opus 5 headless system prompt ends with "Do not call the
  AgentTool unless the user requested it", so the smoke run skipped `stagekit-plan-critic` and
  `stagekit-verifier`. Every prompt therefore ends with "Use subagents wherever your process calls
  for them" — identical in both arms. The Agent tool is exposed as `Task` headless; it is allowlisted.
- **`plan_sync` is off** in the fixture: its `ask` cannot be answered headlessly.
- **Trust `timing.json` per run, not blindly.** One observed run reported `num_turns=4` /
  `duration_ms=64s` while its transcript showed 56 Bash calls and a full pipeline — the CLI's
  result event can under-report after context compaction. The workspace and transcript are the
  ground truth; treat token/time aggregates as indicative.

## Adding a case

`mkdir eval-<name>`, write `prompt.md` (works with and without the plugin), `graders/criteria.md`
(`### ` headings become the judge's criteria and `eval_metadata.json` assertions), `check.sh`
using `emit score|indicator` from `bin/lib.sh`, optionally `hidden/*.test.js` and a `setup.sh`
that adjusts the fixture (it receives `PLUGIN`). Decide each check's scope before the first run.
