---
name: intent
description: Stage 1 Plan — brainstorm a problem into a committed intent.md. Captures what is wanted, why, and under which constraints, in the originator's own words, before anyone talks about implementation.
when_to_use: When the user asks to capture, write up or start an intent (or runs /sdlc:intent), when an alert, ticket or scan finding needs writing up as intent.md, or when this repo's SDLC driver is on (`drive: auto` in .sdlc/config.json) and new work arrives.
argument-hint: "[one line: what you want]"
allowed-tools: Read Write Edit Glob Grep Bash(mkdir:*) Bash(git:*) Bash(cat:*) Bash(date:*)
---

# Stage 1 — Capture intent

> **Defaults:** without `.sdlc/config.json` the artifact directory is `sdlc/` and the templates are the plugin's. Say once that `/sdlc:init` configures gates, templates and the driver, then carry on.

Ideas stop waiting for someone to write them up. Produce one artifact:
`sdlc/<id>/intent.md`.

## The one rule

**Do not discuss implementation in this stage.** Not files, not libraries, not
architecture. If the user starts designing, note it and steer back — the design
belongs in `/sdlc:spec`, and mixing them is what makes intent unreviewable.

## Steps

1. **Let them describe the problem in their own words.** No formal language
   required. Useful openers: what can't you do today, who is affected, what does
   better look like, what is explicitly out of scope.

   When the intent arrives as a ticket, alert, scan finding or channel message
   (`origin` other than `person`), **verify the claim before anything else**:
   reproduce a reported bug from its steps, or search the code for an existing
   implementation of what is asked. What you found goes into Problem; a claim
   that does not hold up is an open question, not a requirement.

2. **Check the history.** Search `sdlc/*/intent.md` for earlier changes on the
   same ground. Open: join it instead of starting a second. Shipped (`closed:`):
   the ask may already be built — check the code. `rejected`: reopen only with
   what has changed since, and say so in Problem.

3. **Interview in rounds until it is concrete.** The intent is a design tree:
   every answer opens the questions that hang off it. Each round, ask the whole
   **frontier** — every question answerable now without guessing at an answer
   you have not heard — numbered, each with your recommended answer, so the
   user can accept in a word. A question that depends on one still open waits
   for the next round. Facts are your job: anything you can look up (the code,
   the tracker, the docs) you look up, in a subagent if it is slow; only
   decisions go to the user.

   ```
   ❓ **Q1 — <title>**: <the question, with the choices where there are some>
   ➡️ <your recommended answer>
   ```

   The threads an analyst would pull:
   - Scope: what is the smallest version that is still worth building?
   - Users: who does this serve, and who else is affected?
   - Constraints: data classification, authentication, performance, cost, dependencies you cannot touch, deadlines.
   - Success: what would you measure to know it worked?
   - Out of scope: what will people assume is included that isn't?
   - Terms: if the repo has a `CONTEXT.md` glossary, check the user's words
     against it and ask which meaning is meant when they differ — a term
     sharpened now is cheaper than a spec built on the wrong one.

   Push back on vagueness. "Make it faster" is not an intent; "status queries
   return in under 300ms at p95" is. If the user cannot answer something, that
   is an **open question**, not a gap to paper over. The interview is done when
   the frontier is empty — nothing left silently assumed.

4. **Allocate an id.** `<NNNN>-<slug>`, where NNNN is the next number in `sdlc/`
   (zero-padded to 4). Create `sdlc/<id>/`.

5. **Write `intent.md`** from `.sdlc/templates/intent.md` if the project has one, otherwise `${CLAUDE_PLUGIN_ROOT}/templates/intent.md`.
   Keep the originator's words where you can; do not translate their problem
   into your vocabulary. Fill the frontmatter, including `origin`.

6. **Read it back and correct it.** Show the file. Ask directly whether anything
   was misunderstood. Fix what they flag before committing.

7. **Set the active change**: write the id to `.sdlc/current`.

8. **Commit** `sdlc/<id>/intent.md` and `.sdlc/current`. Author and timestamp
   join the record. Commit message: `intent(<id>): <title>`.

## The gate

`intent.md` is **draft** until the user accepts it. Say so; a word in chat is
enough — when they say accept, set `status: accepted` for them. A rejection
stays in `sdlc/` with its reason under a `## Rejected` heading — date, who,
why — so the same ask is recognised next time.

Usually next: `/sdlc:spec`, or `/sdlc:plan` in a flow without a spec stage.
