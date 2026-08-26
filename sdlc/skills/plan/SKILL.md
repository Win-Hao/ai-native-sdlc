---
name: plan
description: Stage 3 Build (a) — produce and interrogate plan.md in plan mode, naming the files that change, the order of work, the risks, and the proof. Nothing is implemented without an approved plan.
when_to_use: When the user asks for a plan or runs /sdlc:plan, when they ask to implement something that spans more than a few files and no plan.md exists (offer it), or when this repo's SDLC driver is on (`drive: auto`).
argument-hint: "[change id]"
allowed-tools: Read Write Edit Glob Grep Bash(git:*) Bash(cat:*) Bash(ls:*) Bash(rg:*) Bash(mkdir:*) Bash(date:*)
---

# Stage 3a — Plan before code

> **Defaults:** without `.sdlc/config.json` the artifact directory is `sdlc/` and the templates are the plugin's. Say once that `/sdlc:init` configures gates, templates and the driver, then carry on.

Design review happens **before** any code is generated, while changing course is
still a matter of editing a document. Produce `sdlc/<id>/plan.md`.

## Inputs

`sdlc/<id>/spec.md` when there is one (open flagged concerns: name them and ask
whether to go on), else `intent.md`, else the conversation — say which. If the
upstream artifact is not accepted, say so; the user decides. Without any
artifact, allocate the id and set `.sdlc/current` yourself, and put a short
Problem paragraph at the top of the plan so it stands alone.

## How plan mode fits

Plan mode is what makes this gate real: the harness refuses every file edit
until the human accepts the plan, so the control does not depend on good
intentions. It also means **you cannot write `sdlc/<id>/plan.md` while in plan
mode** — the artifact is written after acceptance. The sequence is:

1. `EnterPlanMode` — do it yourself if the session is not already in plan mode.
   Do not ask the user to press Shift+Tab.
2. Read and draft (steps 1–3 below). Until the human has seen it, the draft
   lives in plan mode's own plan file.
3. `ExitPlanMode` with the full draft. The human's acceptance there **is** the
   approval of this stage. A rejection or an edit request sends you back to
   step 2, still in plan mode.
4. Only after acceptance: write `sdlc/<id>/plan.md` and commit it (step 5).

## Steps

1. **Read `intent.md` and `spec.md`.** Then read the code they touch — actually
   read it. A plan written from the spec alone will name files that don't exist
   and miss callers that do.

2. **Draft the plan** in the shape of `.sdlc/templates/plan.md` if the project has one, otherwise `${CLAUDE_PLUGIN_ROOT}/templates/plan.md`:
   - **Files that change** — every path, marked new/modify/delete, with its
     responsibility. Never "and related files". The plan-sync gate compares
     commits against this list, so vagueness here costs you later.
   - **Order of work** — each step independently verifiable. Ordering matters:
     no step should leave the system in a state that cannot be shipped.
   - **Risks** — what this could break, and which step is riskiest.
   - **Alternatives not taken** — with reasons. If this section is empty you did
     not consider alternatives.
   - **Proof** — named test files, named commands, expected outputs, the mock a
     screenshot must match. "Tests pass" is not proof; *which* tests and what
     they cover is.

3. **Interrogate the plan before showing it as done.** Ask yourself, with
   evidence from the code, and write the answers into the plan:
   - What could this change break?
   - Which step is riskiest?
   - What did I choose not to do, and why?

   For anything non-trivial, run the `sdlc-plan-critic` subagent over the draft
   and fold its blocking findings back in.

4. **Present it through `ExitPlanMode`** — name the riskiest step out loud —
   and iterate with the human until an engineer who has never seen this
   conversation could implement the change from the plan alone. That is the bar.
   Decisions only the human can make (an ordering, a risk to accept, an
   alternative to revive) go to them as a numbered round, each with your
   recommended answer — the same format as `/sdlc:intent`. Facts you can
   look up, you look up. A plan with an open decision is not ready to approve.

5. **After acceptance, write and commit.** Create `sdlc/<id>/plan.md` from the
   template with `status: approved` and `approved_by: <the user>` — acceptance
   in plan mode is the approval; do not ask for it a second time. Commit:
   `plan(<id>): <title>`. If the user wants more time, leave it at
   `status: draft` and say that they set `approved` when ready.

## The gate

You do not approve your own plan. Present it, name the riskiest step out loud,
and wait. The driver names the next stage once `plan.md` is approved.

Usually next: `/sdlc:build`, or `/sdlc:build tdd` to go red-green one slice at a time.
