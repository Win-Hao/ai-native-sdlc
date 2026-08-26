---
name: watch
description: Stage 6 Maintain — close the loop. Set up deterministic control-band detection that invokes Claude without a human in the path, tiers what it may do, and writes findings back as a new intent.md.
argument-hint: "[setup | diagnose | triage]"
disable-model-invocation: true
allowed-tools: Read Write Edit Glob Grep Bash
---

# Stage 6 — Close the loop

A trigger invokes Claude with no person in the invocation path, and what it finds
re-enters the pipeline as `intent.md`. People triage and review that work; they
no longer have to start it.

---

## `setup` — build the harness

1. **Pick one metric** with a stable rolling baseline. Start with one: CI test
   failure rate, post-deploy 5xx rate, or PR cycle time.

2. **Write the detection script — no model involved.** Mean and standard
   deviation over a rolling window, with Western Electric rules so the bands
   catch slow drift as well as spikes. **Detection stays deterministic.** Version
   control the script and unit test it; a flaky detector poisons everything
   downstream.

3. **Define the tiers** in `bands.yaml` from `.sdlc/templates/bands.yaml` if the project has one, otherwise `${CLAUDE_PLUGIN_ROOT}/templates/bands.yaml`:

   | Band | Action | What Claude may do |
   |---|---|---|
   | 1σ | log | nothing — the script only records |
   | 2σ | diagnose | read-only tools |
   | 3σ | propose | open a PR into the review gate, or trigger a **pre-approved** runbook |

   Nothing above 3σ. There is no tier where the agent acts on production directly.

4. **Wire the trigger**: a scheduled CI workflow, a webhook from the monitoring
   stack, or a cron job inside the network. Claude runs stateless and
   non-interactive, so a loop can begin and end without anyone starting it.

5. **Rehearse rollback before you need it.** The 3σ tier may call it. If it is
   not a single command exercised regularly in staging, the tier is a liability —
   drop to 2σ until it is.

---

## `diagnose` — what the agent does when a band is breached

Read-only. Produce `intent.md` in the **Stage 1 format**, not a free-form report:

- **Problem** — the anomaly, with its evidence: the metric, the band, the window,
  the commits and deploys inside it.
- **Proposed outcome** — what "back to baseline" means.
- **Affected users and systems.**
- **Constraints** — what must not be touched while fixing it.
- **Open questions** — everything you could not determine read-only. Be explicit
  about uncertainty; a confident wrong diagnosis is worse than an open question.

Write it to `sdlc/<id>/intent.md` with `origin: alert`, and stop. From there it
goes through the pipeline like anything else.

---

## `triage` — the human end of the loop

Before deciding, **verify the claim**: re-run the detection over the window,
reproduce the symptom where there is one, and check whether the fix already
exists in the code or in an open change. An unverified finding is a signal for
"needs more information", not for "fix now".

Then: fix now, schedule, or dismiss. **Every dismissal records a reason and tunes
the bands** — set the intent to `status: rejected` with the reason under a
`## Rejected` heading; it stays in `sdlc/` so the next occurrence is recognised
(`/sdlc:intent` checks prior rejections before opening a change). When a fix
ships, add an eval for the incident (`/sdlc:evals add`) so the class is covered
from then on.

---

## Other entry points

The same pattern covers work arriving from elsewhere: a scheduled security scan,
a ticket, or an incident channel. The rule does not change — a bounded fix
arrives as a PR through the review gate, and anything larger becomes an
`intent.md` for Stage 1.
