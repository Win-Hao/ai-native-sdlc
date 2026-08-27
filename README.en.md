# AI-Native SDLC for Claude Code

[中文](README.md) · English

The six stages of [The AI-Native SDLC Playbook](https://claude.com/blog/the-ai-native-sdlc-playbook)
as a Claude Code plugin: **14 commands, 3 agents, one set of artifact templates**. Run a command
whenever you want; it writes its artifact to `sdlc/<id>/`. Gates (hooks) and the loop driver are
optional and off by default.

## Install

```bash
claude plugin marketplace add Win-Hao/ai-native-sdlc
claude plugin install sdlc@ai-native-sdlc
```

Requires `jq` (ships with macOS 15+; otherwise `brew install jq` / `apt install jq`).

## Quick start

```
cd <your-project> && claude
/sdlc:init
```

`/sdlc:init` asks four questions, each with a recommended answer: template language (English / 中文),
gate level (recommended `minimal`), whether the agent drives the stages (recommended `off`), and which
files it may write. The configuration is previewed before it goes live. The commands also work without
init (defaults: `sdlc/` and the plugin's templates).

### Build a feature

```
/sdlc:intent   interviews you and writes intent.md; say "accept" to pass the gate
/sdlc:spec     reads the intent, loads your organisation's skills, agrees the test seams with you first;
               you resolve the flagged concerns
/sdlc:plan     drafts in plan mode, has the critic agent interrogate it, shows it to you; accepting is approval
/sdlc:build    implements the plan (add `tdd` to go red before green, one slice at a time)
/sdlc:verify   runs build/test/lint, checks every item of Proof, gets an independent agent's verdict
/sdlc:review   three passes — bugs / security / compliance — as findings; you merge
/sdlc:done     closes the change
```

Small projects can skip the spec; `/sdlc:plan` can also draft straight from the conversation and
allocate the id itself.

### Fix a bug

```
/sdlc:fix      builds a feedback loop that goes red on the bug → minimises → hypothesises →
               commits the failing test before the fix → locks the tests → fixes → cleans up
```

Or just say "this is broken" — the agent uses the same discipline. No intent or plan needed.

### Small edits

Just ask; the agent edits. Nothing stops you unless you hit a gate (`rm -rf /`, force push, a
production deploy).

## Command reference

| Command | Reads | Produces |
|---|---|---|
| `/sdlc:init` | the repo as it is | `.sdlc/config.json`, an `## SDLC` pointer block in `CLAUDE.md`, `REVIEW.md` |
| `/sdlc:intent` | your words; for tickets/alerts it verifies the claim first, then checks `sdlc/` for a prior change | `intent.md`: problem, proposed outcome, affected users and systems, constraints, open questions, out of scope |
| `/sdlc:spec` | `intent.md` (or the conversation) + `.claude/skills/` policies + `CONTEXT.md` / ADRs | `spec.md`: requirements with acceptance, design decisions (no file paths), testing decisions, policy application, flagged concerns |
| `/sdlc:plan` | `spec.md` or `intent.md`, plus the real code | `plan.md`: files that change, order of work, risks, alternatives not taken, Proof |
| `/sdlc:build [tdd]` | `plan.md` | the diff; deviations recorded in the same commit; `tdd` = each slice's red tests committed alone → lock → green |
| `/sdlc:fix` | the symptom you describe | a failing test committed before the fix, then the fix |
| `/sdlc:verify` | `plan.md` Proof | literal build/test/lint output, Proof item by item, `sdlc-verifier` verdict |
| `/sdlc:review` | `REVIEW.md` + spec + plan + earlier `findings.md` files | `findings.md`: three passes of findings, each with a class and its repeat count; 2nd occurrence → a CLAUDE.md line, 3rd → a hook or skill proposed |
| `/sdlc:done` | — | `closed:` / `outcome:` in `intent.md`, `.sdlc/current` cleared |
| `/sdlc:status` | `sdlc/<id>/` | where the change stands and the usual next step |
| `/sdlc:gate` | `.sdlc/config.json` | audit / add gates / prove a gate fires |
| `/sdlc:evals` | real tasks, incidents | `evals/*.json` + a CI threshold |
| `/sdlc:watch` | production metrics | `bands.yaml`; a breached band writes a new `intent.md` |
| `/sdlc:customize` | — | change the pipeline, override templates |

Agents (called by the commands): `sdlc-plan-critic` interrogates a plan, `sdlc-verifier` runs the
change in a fresh context, `sdlc-reviewer` runs the review passes.

## Artifacts and status

```
sdlc/0001-claims-status/
  intent.md    status: draft → accepted | rejected
  spec.md      status: draft → accepted
  plan.md      status: draft → approved → implemented
  findings.md  review findings + tally; repeats counted across changes
.sdlc/current  the active change id
```

- `status:` is your decision: edit the file, or say so in chat and the agent sets it for you
- Each stage ends with one commit (`intent(0001): …`, `spec(0001): …`, `plan(0001): …`); git history is the audit trail
- Folders are never deleted or archived; `/sdlc:done` writes `closed:` and `/sdlc:intent` checks history to avoid duplicates
- `template/sdlc/0000-example-claims-status/` is a complete worked example of the chain

## Gates (optional)

| Level | Gates on |
|---|---|
| `minimal` | irreversible commands (`rm -rf /`, force push, …) ask first; production deploys need `SDLC_RELEASE_APPROVAL=<who>` |
| `standard` | + test files are read-only during a fix (while `.sdlc/lock-tests` exists); generated code, migrations and CI config cannot be edited by the agent |
| `full` | + a commit touching files the plan does not name asks first (`CLAUDE.md`, `REVIEW.md`, `evals/`, `.claude/` exempt) |

Chosen in `/sdlc:init`, raised any time with `/sdlc:gate`. Repos that never ran init are untouched.

## Driver (optional)

`.sdlc/config.json` → `drive`:

| Value | Behaviour |
|---|---|
| `off` (default) | the agent only answers commands |
| `suggest` | when you bring new work it mentions once that `/sdlc:intent` would capture it, then does what you asked |
| `auto` | the agent opens the intent itself, proposes the next stage, writes no implementation before an approved plan, and stops at every gate for you. The flow is the `pipeline`: `full` / `lean` / `regulated` / `tdd`, or your own stages |

## Customise

| What | Where |
|---|---|
| Artifact templates | `.sdlc/templates/*.md` (override the plugin's; init can install the 中文 set) |
| Organisation policy (security, brand, API conventions) | `.claude/skills/<name>/SKILL.md`, loaded as constraints by the spec stage |
| Stage flow (used by the driver) | `.sdlc/config.json` → `pipeline` |
| Gates | `.sdlc/config.json` → `gates` |

A custom stage is one skill + one pipeline entry + one template; see `/sdlc:customize`.

## Without Claude Code

`cp -r template/. your-repo/` gives you `CLAUDE.md`, `REVIEW.md`, the gate config, the eval
harness, the 中文 templates and the worked example. See [ADOPTING.md](template/ADOPTING.md) (中文).

## Layout

```
.claude-plugin/marketplace.json   distribution entry point
sdlc/                             the plugin: skills / agents / hooks / scripts / templates / presets / pipelines
template/                         the plain-files layer
docs/                             archived copy of the playbook
```

## References

[The AI-Native SDLC Playbook](https://claude.com/blog/the-ai-native-sdlc-playbook); the spec,
interview, bug-fix and TDD disciplines draw on [mattpocock/skills](https://github.com/mattpocock/skills).
