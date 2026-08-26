---
name: done
description: Close the active change once it has shipped or been abandoned — record the outcome in its intent.md, clear .sdlc/current so the stage driver and the plan-sync gate stop pointing at it, and commit. Manual only; finishing a change is the human's decision.
argument-hint: "[change id]"
disable-model-invocation: true
allowed-tools: Read Write Edit Glob Grep Bash(git:*) Bash(cat:*) Bash(ls:*) Bash(date:*) Bash(rm -f .sdlc/*)
---

# Close the change

> **First check:** if this repo has no `.sdlc/config.json`, this skill does not apply — say so and stop.

A change is open from `/sdlc:intent` until this command. While it is open the
driver names its next gate every turn and the plan-sync gate checks every
commit against its `plan.md`. Closing it is a decision, which is why the model
cannot invoke this skill on its own.

## Steps

1. **Identify the change.** The argument, else `.sdlc/current`. If neither
   names one, say so and stop.

2. **Report where it stands.** For each artifact in `sdlc/<id>/`, its `status`.
   Then, plainly:
   - artifact gates still unmet (intent not accepted, plan not implemented, …)
   - `.sdlc/lock-tests` still present (a fix task that was never unlocked)
   - uncommitted changes in the working tree

   If anything is unmet, say so and ask whether to close anyway. Closing an
   unfinished change is allowed — abandoning work is a legitimate outcome —
   but the record has to say that is what happened.

3. **Record the outcome in `intent.md`** frontmatter: add
   `closed: <YYYY-MM-DD>` and `outcome: shipped | abandoned | superseded by <id>`.
   Do not touch any `status` field; those are the gate history.

4. **Clear the session state.** Write an empty `.sdlc/current`, and remove
   `.sdlc/lock-tests` and `.sdlc/.laststate` if present.

5. **Commit** `sdlc/<id>/intent.md` and `.sdlc/current`:
   `done(<id>): <outcome>`.

## Report

One line: the id, the outcome, and that the next non-trivial request starts a
new change at the pipeline's first stage. If the change fixed an incident,
remind the user that `/sdlc:evals add` is how it stays fixed.
