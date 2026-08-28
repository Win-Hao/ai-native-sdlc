---
name: spec
description: Stage 2 Design — turn an accepted intent.md into spec.md, applying the organization's skills as constraints while the spec is written, with contradictions flagged rather than silently resolved.
when_to_use: When the user asks for a spec or runs /stagekit:spec, or when this repo's StageKit driver is on (`drive: auto`) and intent.md has been accepted.
argument-hint: "[change id]"
allowed-tools: Read Write Edit Glob Grep Bash(git:*) Bash(cat:*) Bash(ls:*)
---

# Stage 2 — Requirements and design collapse into one

> **Defaults:** without `.stagekit/config.json` the artifact directory is `stagekit/` and the templates are the plugin's. Say once that `/stagekit:init` configures gates, templates and the driver, then carry on.

Requirements and design happen in one session, constrained by policy at write
time instead of discovered in review weeks later. Produce `stagekit/<id>/spec.md`:
**the decisions a plan can be written from**, not the work itself.

## Inputs

`stagekit/<id>/intent.md` when there is one — the argument names the change, else
`.stagekit/current`. If its status is not `accepted`, say so and ask whether to go
on; the user decides (a spec on unaccepted intent is rework waiting to happen).
Without an intent.md, synthesize from the conversation — no interview — and say
so; the Solution section then carries the problem statement too. Allocate the
id (`<NNNN>-<slug>`, next number in `stagekit/`) and set `.stagekit/current` yourself.

## Steps

1. **Load the constraints.** Before writing anything, enumerate what applies:
   - Skills in `.claude/skills/` and any plugin skills covering security, brand,
     UX, API design, data handling.
   - `CLAUDE.md` conventions and architecture.
   - `CONTEXT.md` (or `CONTEXT-MAP.md`) and `docs/adr/` if the repo has them:
     use the glossary's terms, not synonyms, and treat a contradiction with an
     ADR as a flagged concern, never a silent override. When the intent uses a
     term the glossary defines differently, resolve it with the user and update
     `CONTEXT.md` in the same commit (create it on the first resolved term).
   - The existing code the change has to live in — read it. A spec that ignores
     the current design produces a plan that cannot be implemented.

   List what you loaded in the `skills_applied` frontmatter field. If a policy
   area you would expect (security, data) has no skill, say so — that is a gap
   in the organization's controls, not a licence to improvise.

2. **Pick the seams.** Sketch where the behaviour will be tested: the highest
   existing seam that can observe it, a new seam only if none exists, and as
   few as possible — the ideal number is one. Check them with the user before
   writing; this is the one question the stage asks. They become the spec's
   Testing decisions and, later, the plan's Proof.

3. **Write `spec.md`** from `.stagekit/templates/spec.md` if the project has one, otherwise `${CLAUDE_PLUGIN_ROOT}/templates/spec.md`:
   - **Requirements** are exhaustive — every actor, every state, the failure
     paths — each with an id, a source in `intent.md`, and an acceptance
     condition. A requirement no one can check is not a requirement.
   - **Design decisions**, not work: which modules change and their interfaces,
     contracts, schema changes, and why, naming real modules in the project's
     own vocabulary. **No file paths and no code** — they go stale before build
     starts, and paths belong in `plan.md`. The one exception is a snippet from
     a prototype that states a decision more precisely than prose (a schema, a
     state machine, a type), trimmed to the decision.
   - **Testing decisions** — the seams from step 2, what is observed at each,
     and the prior art in this repo the tests should resemble.
   - **Policy application** — say per policy how the spec satisfies it. Not "we
     followed the security standard": which rule, satisfied how.

4. **Record the durable decisions as ADRs.** A design decision that is hard to
   reverse, would surprise a reader who lacks the context, *and* came from a
   real trade-off gets `docs/adr/NNNN-<slug>.md` — one paragraph: the context,
   the decision, why — committed with the spec and linked from Design
   decisions. Anything failing one of the three tests stays in the spec. Follow
   the repo's existing ADR home if it has one; create `docs/adr/` on the first.

5. **Flag concerns; do not resolve them.** This is the most important section.
   Flag anything where:
   - Two policies contradict each other.
   - The intent cannot be satisfied within its stated constraints.
   - A decision needs an owner you are not.
   - The blast radius is larger than the intent implies.

   Name the policy owner for each. **Never quietly pick a side** in a policy
   conflict — that is the failure mode this stage exists to prevent.

6. **Answer the intent's open questions**, or carry them forward with a named
   owner and a reason.

7. **Commit** `spec.md` alongside `intent.md`. The pair records what was asked
   for and what was decided. Message: `spec(<id>): <title>`.

## The gate

Report the flagged concerns as the headline of your summary, not a footnote.
The human resolves each with its policy owner and records the resolution in the
file before build starts. A spec with open concerns does not go to `/stagekit:plan`.

When a policy owner is not in the session, offer a questionnaire they can
answer asynchronously: `stagekit/<id>/questions-<owner>.md` — the purpose and the
decision riding on it, one paragraph of context for someone who was not in
this conversation, how to answer (deadline, partial answers and "I don't know"
welcome), then one question per concern, most important first, each one idea
with a one-line *why this matters* and an answer stub. Their answers go back
into the Status column as `resolved: <decision>`; commit both files.

Usually next: `/stagekit:plan`
