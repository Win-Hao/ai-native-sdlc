---
name: fix
description: Fix a bug test-first — build a feedback loop that goes red on the bug, minimise and hypothesise, turn the repro into a failing test committed before the fix, lock the test files, fix, then unlock and clean up.
when_to_use: When the user reports something broken, throwing, failing or slow, asks to fix a bug, debug or diagnose, or runs /stagekit:fix.
argument-hint: "[what is broken]"
allowed-tools: Read Write Edit Glob Grep Bash
---

# Fix a bug, test first

> **Defaults:** without `.stagekit/config.json` the artifact directory is `stagekit/` and the templates are the plugin's. Say once that `/stagekit:init` configures gates, templates and the driver, then carry on.

This is how a bug fix is built. A test that existed before the fix, and that the
agent could not rewrite, is the proof the bug is gone. It needs no `plan.md`;
if the fix turns out to be wider than one seam, stop and open a change
(`/stagekit:intent` → `/stagekit:plan`) instead of growing it here.

`<id>` in the commit messages below is the active change (`.stagekit/current`) if
there is one; otherwise leave it out.

## Steps

1. **Build a feedback loop that goes red on this bug.** The ideal is a failing
   test at the seam that reaches the bug (`spec.md` Testing decisions, or the
   repo's existing tests, say where that is). When a test is not immediately
   possible, build a loop first — a curl against the dev server, a CLI run
   diffed against a known-good output, a headless-browser script, a replayed
   captured request, a throwaway harness around the code path, a fuzz loop for
   "sometimes wrong", a `git bisect run` harness, a differential run of old vs
   new — and **tighten** it: it asserts the user's exact symptom (not "didn't
   crash"), gives the same verdict every run (pin time, seed randomness,
   isolate the filesystem; for a flaky bug raise the reproduction rate until it
   is debuggable), finishes in seconds, and runs unattended. Show the command
   and its red output, secrets redacted. If you cannot build one, stop: say
   what you tried and which access or captured artifact (log, HAR, recording)
   would unblock it. No loop, no hypotheses.

2. **Minimise, then hypothesise.** Cut inputs, callers, config and steps one at a
   time until every remaining element is load-bearing. Then write 3–5 ranked,
   falsifiable hypotheses — "if X is the cause, changing Y makes it disappear"
   — and show the list before testing any; the user often re-ranks it
   instantly. Probe one variable at a time; a debugger or REPL beats logs, and
   every debug log carries one prefix (`[DEBUG-a4f2]`) so cleanup is a single
   grep. For a performance regression, measure a baseline first and bisect —
   logs are the wrong tool.

3. **Turn the minimised repro into the failing test** at the seam where the real
   bug pattern occurs. If the only seam is too shallow to reproduce the chain
   that triggered the bug, say so — that is a finding about the architecture,
   not a reason to skip the test. Confirm it fails *for the reason you expect*,
   not for a setup error.

4. **Commit that test on its own**, before any fix. `test(<id>): reproduce <bug>`.

5. **Lock the tests**: `touch .stagekit/lock-tests`. With the `test_lock` gate on
   (`standard` level or above) the hook denies every edit to test files from
   here; below that level the lock is a discipline you keep yourself — say so.
   An agent fixing code must not be able to weaken the check on that code.

6. **Fix the code until the test passes.** If the test looks wrong, stop and say
   so — do not ask for the lock to be lifted as a matter of course.

7. **Unlock and clean up**: `rm .stagekit/lock-tests`, and say that you did. Re-run
   the original, un-minimised loop. Grep the debug prefix and remove every
   probe; delete throwaway harnesses. Put the hypothesis that turned out right
   in the commit message, so the next debugger learns.

Usually next: `/stagekit:verify`, then `/stagekit:review`.
