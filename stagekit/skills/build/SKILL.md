---
name: build
description: Stage 3 Build (b) — implement an approved plan.md, keeping the plan and the diff in sync, running the feedback loop, and stopping at anything the plan did not authorize. With `tdd`, every slice goes red before green.
when_to_use: When the user asks to implement an approved plan.md or runs /stagekit:build, or when this repo's StageKit driver is on (`drive: auto`) and plan.md is approved.
argument-hint: "[change id] [tdd]"
allowed-tools: Read Write Edit Glob Grep Bash
---

# Stage 3b — Implement from the approved plan

> **Defaults:** without `.stagekit/config.json` the artifact directory is `stagekit/` and the templates are the plugin's. Say once that `/stagekit:init` configures gates, templates and the driver, then carry on.

With a solid plan the implementation is often a single pass. Your job is to
follow it, not to improve on it mid-flight.

## Input

`stagekit/<id>/plan.md`. If it is still `draft`, say so and ask — the user may
approve it in chat, in which case set `status: approved` and go; implementing
a plan nobody approved defeats the stage. Without a plan.md there is nothing to
build from: offer `/stagekit:plan`, or do the work as ordinary implementation if
the user prefers.

## Steps

1. **Read `plan.md`, `CLAUDE.md`, and the skills that apply.** Work the steps in
   the order the plan gives.

2. **`tdd` — one slice at a time.** When the user passes `tdd` (or the pipeline
   runs build as `/stagekit:build tdd`), every slice in Order of work goes red
   before green. Proof names the seams (from `spec.md` Testing decisions), the
   cases and the expected outputs; if it is too vague to write a test from —
   "tests pass", "it works" — stop and go back to `/stagekit:plan`. Per slice:
   write its tests at the agreed seam — behaviour through the interface, never
   internals, expected values from the spec or a known-good literal, never
   recomputed the way the code will compute them → run them red and paste the
   output (a test that errors on a missing import is broken, not red) → commit
   them alone, `test(<id>): red — <slice>` → `touch .stagekit/lock-tests` →
   implement with the least code that passes, nothing for later slices →
   `rm .stagekit/lock-tests`, saying so → next slice. Writing every test before
   any implementation tests the shape you imagined, not behaviour; each
   slice's tests respond to what the last one taught you. The lock only moves
   between slices with a red commit in between, so git shows every unlock
   followed by one. Refactor only once a slice is green and while its tests
   are still locked — the lock is what makes the refactor safe.

   If a locked test looks wrong, **stop and say so**. Do not ask for the lock to
   be lifted as a matter of routine; that request is the exact failure the lock
   exists to catch.

3. **Run the feedback loop continuously, not at the end.** After each step of
   the plan, run the verification command from `CLAUDE.md` and fix what it
   catches. What reaches the human should already have passed.

4. **When you need to depart from the plan, stop and say so first.** Three cases:

   | Situation | What to do |
   |---|---|
   | A file not in "Files that change" needs editing | Say which file and why. Update `plan.md` (Files that change + Deviations) **in the same commit** as the code. |
   | A step turns out to be wrong | Stop. Report the finding and the options. Do not silently redesign. |
   | The spec turns out to be unimplementable | Stop. This goes back to Stage 2, not into a workaround. |

   The plan-sync gate asks for confirmation on commit if the staged diff names
   files the plan does not (`CLAUDE.md`, `REVIEW.md`, `evals/` and `.claude/` are
   exempt — the loop writes those itself). Treat that prompt as a signal you
   skipped this step, not as an obstacle.

5. **Do not weaken the proof.** Never edit a test to make it pass, never delete a
   failing test, never lower a threshold. If a test is genuinely wrong, say so
   and stop — that is a human decision.

6. **Before reporting done**, run build + test + lint and paste the literal
   output. When every step of the plan is done and the checks are green, set
   `plan.md` to `status: implemented` and commit it with the last code commit
   (`build(<id>): <title>`). That is this stage's gate — the driver stays on
   "build" until it sees it. Then run `/stagekit:verify`.

## Parallel work

Independent streams (different files, per the plan) go in separate worktrees:
`claude --worktree <name>`. Two or three sessions is a sensible start; the
ceiling is how many you can review properly, so add one only while review keeps
up. Tasks that share files run in one session, one after another.

## Auto mode

Auto-accept is appropriate when all four hold: a tight `spec.md`, a small blast
radius, code the tests already cover, and the gates from `/stagekit:gate` in place.
Otherwise stay on per-edit approval. Autonomy is earned by the guardrails, not
by the size of the task.

Usually next: `/stagekit:verify`
