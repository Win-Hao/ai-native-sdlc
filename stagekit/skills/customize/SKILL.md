---
name: customize
description: Adapt StageKit to this project — change the stage pipeline (add, remove or reorder stages), override the artifact templates, and point stages at project-specific skills. Use when the default six stages do not fit how this project actually works.
argument-hint: "[pipeline | templates | show]"
disable-model-invocation: true
allowed-tools: Read Write Edit Glob Grep Bash
---

# Adapt StageKit to this project

Three things are project-owned. Everything else comes from the plugin.

| What | Lives in | Overrides |
|---|---|---|
| The stage pipeline | `.stagekit/config.json` → `pipeline` | the built-in six stages |
| Artifact templates | `.stagekit/templates/*.md` | `${CLAUDE_PLUGIN_ROOT}/templates/` |
| Policy skills | `.claude/skills/<name>/SKILL.md` | nothing — these are additive |

If the argument is `show`, print the current pipeline, which templates are
overridden, and which project skills the pipeline references. Then stop.

---

## `pipeline` — change the stages

The pipeline is what `/stagekit:status` and the driver (`drive: suggest | auto`)
follow; with `drive: off` it only orders the status report. It is an ordered
list in `.stagekit/config.json`. Each entry:

```json
{
  "id": "threat-model",
  "artifact": "threat-model.md",
  "done_when": "signed-off",
  "command": "/threat-model",
  "draft_hint": "Security owner reviews and sets status: signed-off."
}
```

| Field | Meaning |
|---|---|
| `id` | Stage name shown in the driver |
| `artifact` | File in `stagekit/<id>/` whose frontmatter `status` is the gate. `null` = an action with no artifact to observe (like verify); the driver carries it as "then" into the next stage's Next |
| `done_when` | The `status` value that opens the next stage |
| `command` | What the agent runs for this stage — a plugin skill or **any project skill** |
| `draft_hint` | Shown while the gate is unmet. **Present = a human moves this gate. `null` = an agent action that just has not run yet.** |

Rules that the driver relies on:

- **Order is the flow.** The first stage whose gate is unmet is the current stage.
- **Several stages may share one artifact.** Their `done_when` values become that
  file's progression, in pipeline order — `plan.md` goes `approved` then
  `implemented`, so `/stagekit:plan` and `/stagekit:build` are two stages on one file.
- **`draft_hint` decides who acts.** Getting this wrong is the common mistake: a
  hint on an agent stage makes the loop sit and wait for a human who was never
  asked to do anything.

Start from a shipped pipeline rather than a blank list:

| Preset | Stages | For |
|---|---|---|
| `${CLAUDE_PLUGIN_ROOT}/pipelines/full.json` | intent → spec → plan → build → verify → review | the default |
| `${CLAUDE_PLUGIN_ROOT}/pipelines/lean.json` | intent → plan → build → verify | small projects; intent and design collapse into one artifact |
| `${CLAUDE_PLUGIN_ROOT}/pipelines/regulated.json` | + threat-model, change-record | named sign-offs that must survive |
| `${CLAUDE_PLUGIN_ROOT}/pipelines/tdd.json` | build runs as `/stagekit:build tdd` | red-green on features, one slice at a time |

Install one with:
```
jq --slurpfile p <preset> '.pipeline=$p[0]' .stagekit/config.json > t && mv t .stagekit/config.json
```

### Adding a custom stage

1. Write the stage as a **project skill** at `.claude/skills/<name>/SKILL.md`. It
   should end by writing `stagekit/<id>/<artifact>` with a `status` frontmatter field.
2. Add a pipeline entry pointing `command` at `/<name>`.
3. Add a template at `.stagekit/templates/<artifact>` so the shape is consistent.
4. Verify: `${CLAUDE_PLUGIN_ROOT}/scripts/doctor.sh`, then check that the driver
   reports your stage — create the artifact by hand at each status value and
   confirm the reported "Current stage" and "Next" are what you intended.

**Do not skip step 4.** A pipeline entry whose `done_when` never matches what the
skill actually writes leaves the loop stuck on that stage forever.

---

## `templates` — change the artifact shapes

```
mkdir -p .stagekit/templates
cp ${CLAUDE_PLUGIN_ROOT}/templates/intent.md .stagekit/templates/
```

Every skill reads `.stagekit/templates/<name>` first and falls back to the plugin's.
Copy only the ones you change; an unmodified copy is a file that silently stops
tracking plugin updates.

Keep the frontmatter fields the driver reads — `id`, `status`, and whatever the
pipeline's `done_when` values are. Everything below the frontmatter is yours.

---

## What not to customize here

- **Gates** (`.stagekit/config.json` → `gates`) — use `/stagekit:gate`.
- **Repo conventions** — `CLAUDE.md`.
- **Review policy** — `REVIEW.md`.
- **Organizational policy** — a skill in `.claude/skills/`, per the playbook:
  write a skill for institutional knowledge that must be applied consistently.

## Report

Print the resulting pipeline as a chain, say which stages are human-gated and
which are agent actions, and name anything you changed that the driver has not
been tested against yet.
