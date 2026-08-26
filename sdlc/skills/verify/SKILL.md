---
name: verify
description: Stage 4 Test — verify the current change before a human sees it. Runs build, test and lint, checks every item of plan.md's Proof, and gets an independent verdict from the sdlc-verifier subagent.
when_to_use: When the user runs /sdlc:verify or asks to verify a change before review, or when this repo's SDLC driver is on (`drive: auto`) and a change is implemented.
argument-hint: "[change id]"
allowed-tools: Read Write Edit Glob Grep Bash
---

# Stage 4 — Verify the change

> **Defaults:** without `.sdlc/config.json` the artifact directory is `sdlc/` and the templates are the plugin's. Say once that `/sdlc:init` configures gates, templates and the driver, then carry on.

A session that can check its own work stops the human being the bottleneck.
This command is that check. The ways of building that make it pass are
`/sdlc:fix` (a bug, test first) and `/sdlc:build tdd` (a feature, one slice at
a time).

## Steps

1. **Run build, test and lint** — the commands in `CLAUDE.md`. Paste the literal
   output: the evidence comes from the toolchain, not from your summary of it.
   If `CLAUDE.md` has no single verification command, say so and point at
   `/sdlc:init`, which sets one up. A check you could not run is not a pass.

2. **Check the target.** With a `plan.md`, every item of its **Proof**; without
   one, what the user asked for. A target has to be checkable — "all tests in
   `test_status.py` pass", "the endpoint returns 200 with the new field", "the
   screenshot matches `design/mock-x.png`" — and each is reported as met or
   unmet.

3. **For UI work, close the loop visually.** Screenshot, compare with the mock,
   adjust; two or three rounds is normal and each should be visibly better.

4. **For anything non-trivial, run the `sdlc-verifier` subagent.** A fresh
   context gives a verdict uncoloured by the assumptions that produced the code.

5. **If something fails, fix the code and repeat.** Never a test to make it
   pass, never a threshold to make it green. Do not report done with a red check
   and an explanation of why it does not matter.

Report the tally honestly, including what you did not run and why.

Usually next: `/sdlc:review`
