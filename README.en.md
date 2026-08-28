# StageKit — AI-Native SDLC for Claude Code

[中文](README.md) · English

The six stages of [The AI-Native SDLC Playbook](https://claude.com/blog/the-ai-native-sdlc-playbook)
as a Claude Code plugin: **14 commands, 3 agents, one set of artifact templates**. Run a command
whenever you want; it writes its artifact to `stagekit/<id>/`. Gates (hooks) and the loop driver are
optional and off by default.

## Install

```bash
claude plugin marketplace add Win-Hao/ai-native-sdlc
claude plugin install stagekit
```

Requires `jq` (ships with macOS 15+; otherwise `brew install jq` / `apt install jq`).

## Quick start

```
cd <your-project> && claude
/stagekit:init
```

`/stagekit:init` asks four questions, each with a recommended answer: template language (English / 中文),
gate level (recommended `minimal`), whether the agent drives the stages (recommended `off`), and which
files it may write. The configuration is previewed before it goes live. The commands also work without
init (defaults: `stagekit/` and the plugin's templates).

### Build a feature

```
/stagekit:intent   interviews you and writes intent.md; say "accept" to pass the gate
/stagekit:spec     reads the intent, loads your organisation's skills, agrees the test seams with you first;
               you resolve the flagged concerns
/stagekit:plan     drafts in plan mode, has the critic agent interrogate it, shows it to you; accepting is approval
/stagekit:build    implements the plan (add `tdd` to go red before green, one slice at a time)
/stagekit:verify   runs build/test/lint, checks every item of Proof, gets an independent agent's verdict
/stagekit:review   three passes — bugs / security / compliance — as findings; you merge
/stagekit:done     closes the change
```

Small projects can skip the spec; `/stagekit:plan` can also draft straight from the conversation and
allocate the id itself.

### Fix a bug

```
/stagekit:fix      builds a feedback loop that goes red on the bug → minimises → hypothesises →
               commits the failing test before the fix → locks the tests → fixes → cleans up
```

Or just say "this is broken" — the agent uses the same discipline. No intent or plan needed.

### Small edits

Just ask; the agent edits. Nothing stops you unless you hit a gate (`rm -rf /`, force push, a
production deploy).

## Command reference

| Command | Reads | Produces |
|---|---|---|
| `/stagekit:init` | the repo as it is | `.stagekit/config.json`, an `## StageKit` pointer block in `CLAUDE.md`, `REVIEW.md` |
| `/stagekit:intent` | your words; for tickets/alerts it verifies the claim first, then checks `stagekit/` for a prior change | `intent.md`: problem, proposed outcome, affected users and systems, constraints, open questions, out of scope |
| `/stagekit:spec` | `intent.md` (or the conversation) + `.claude/skills/` policies + `CONTEXT.md` / ADRs | `spec.md`: requirements with acceptance, design decisions (no file paths), testing decisions, policy application, flagged concerns |
| `/stagekit:plan` | `spec.md` or `intent.md`, plus the real code | `plan.md`: files that change, order of work, risks, alternatives not taken, Proof |
| `/stagekit:build [tdd]` | `plan.md` | the diff; deviations recorded in the same commit; `tdd` = each slice's red tests committed alone → lock → green |
| `/stagekit:fix` | the symptom you describe | a failing test committed before the fix, then the fix |
| `/stagekit:verify` | `plan.md` Proof | literal build/test/lint output, Proof item by item, `stagekit-verifier` verdict |
| `/stagekit:review` | `REVIEW.md` + spec + plan + earlier `findings.md` files | `findings.md`: three passes of findings, each with a class and its repeat count; 2nd occurrence → a CLAUDE.md line, 3rd → a hook or skill proposed |
| `/stagekit:done` | — | `closed:` / `outcome:` in `intent.md`, `.stagekit/current` cleared |
| `/stagekit:status` | `stagekit/<id>/` | where the change stands and the usual next step |
| `/stagekit:gate` | `.stagekit/config.json` | audit / add gates / prove a gate fires |
| `/stagekit:evals` | real tasks, incidents | `evals/*.json` + a CI threshold |
| `/stagekit:watch` | production metrics | `bands.yaml`; a breached band writes a new `intent.md` |
| `/stagekit:customize` | — | change the pipeline, override templates |

Agents (called by the commands): `stagekit-plan-critic` interrogates a plan, `stagekit-verifier` runs the
change in a fresh context, `stagekit-reviewer` runs the review passes.

## Artifacts and status

```
stagekit/0001-claims-status/
  intent.md    status: draft → accepted | rejected
  spec.md      status: draft → accepted
  plan.md      status: draft → approved → implemented
  findings.md  review findings + tally; repeats counted across changes
.stagekit/current  the active change id
```

- `status:` is your decision: edit the file, or say so in chat and the agent sets it for you
- Each stage ends with one commit (`intent(0001): …`, `spec(0001): …`, `plan(0001): …`); git history is the audit trail
- Folders are never deleted or archived; `/stagekit:done` writes `closed:` and `/stagekit:intent` checks history to avoid duplicates
- `template/stagekit/0000-example-claims-status/` is a complete worked example of the chain

## Gates (optional)

| Level | Gates on |
|---|---|
| `minimal` | irreversible commands (`rm -rf /`, force push, …) ask first; production deploys need `STAGEKIT_RELEASE_APPROVAL=<who>` |
| `standard` | + test files are read-only during a fix (while `.stagekit/lock-tests` exists); generated code, migrations and CI config cannot be edited by the agent |
| `full` | + a commit touching files the plan does not name asks first (`CLAUDE.md`, `REVIEW.md`, `evals/`, `.claude/` exempt) |

Chosen in `/stagekit:init`, raised any time with `/stagekit:gate`. Repos that never ran init are untouched.

## Driver (optional)

`.stagekit/config.json` → `drive`:

| Value | Behaviour |
|---|---|
| `off` (default) | the agent only answers commands |
| `suggest` | when you bring new work it mentions once that `/stagekit:intent` would capture it, then does what you asked |
| `auto` | the agent opens the intent itself, proposes the next stage, writes no implementation before an approved plan, and stops at every gate for you. The flow is the `pipeline`: `full` / `lean` / `regulated` / `tdd`, or your own stages |

## Customise

| What | Where |
|---|---|
| Artifact templates | `.stagekit/templates/*.md` (override the plugin's; init can install the 中文 set) |
| Organisation policy (security, brand, API conventions) | `.claude/skills/<name>/SKILL.md`, loaded as constraints by the spec stage |
| Stage flow (used by the driver) | `.stagekit/config.json` → `pipeline` |
| Gates | `.stagekit/config.json` → `gates` |

A custom stage is one skill + one pipeline entry + one template; see `/stagekit:customize`.

## Without Claude Code

`cp -r template/. your-repo/` gives you `CLAUDE.md`, `REVIEW.md`, the gate config, the eval
harness, the 中文 templates and the worked example. See [ADOPTING.md](template/ADOPTING.md) (中文).

## Layout

```
.claude-plugin/marketplace.json   distribution entry point
stagekit/                         the plugin: skills / agents / hooks / scripts / templates / presets / pipelines
template/                         the plain-files layer
docs/                             archived copy of the playbook
```

## References

[The AI-Native SDLC Playbook](https://claude.com/blog/the-ai-native-sdlc-playbook); the spec,
interview, bug-fix and TDD disciplines draw on [mattpocock/skills](https://github.com/mattpocock/skills).
