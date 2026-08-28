---
name: status
description: Show where the active change sits in the AI-native SDLC loop — which artifacts exist, which gate is next, and what is blocking. Use when resuming work or when unsure which stage command comes next.
when_to_use: When the user asks where a change stands, what to do next in the stage pipeline, or resumes work on a repo that has a stagekit/ artifact directory.
allowed-tools: Read Glob Grep Bash(git status:*) Bash(git log:*) Bash(cat:*) Bash(ls:*)
---

# Where is this change in the loop?

1. Read `.stagekit/current` for the active change id. If absent, list `stagekit/*/` and
   ask which change is active (or `/stagekit:intent` to start one). A change whose
   `intent.md` carries `closed:` is finished; do not reopen it silently.
2. For that change, report the state of each artifact in `stagekit/<id>/`:

   | Artifact | Stage | Status |
   |---|---|---|
   | `intent.md` | 1 Plan | frontmatter `status`, or missing |
   | `spec.md` | 2 Design | `status`, plus count of **open** flagged concerns |
   | `plan.md` | 3 Build | `status`, plus whether `Deviations` is non-empty |
   | `findings.md` | 5 Deploy | `reviewed` date and `important` / `nits`; missing = not reviewed |

3. Report the working state:
   - `git status --short` — is the diff consistent with `plan.md` "Files that change"? Name any file changed that the plan did not name.
   - Does `.stagekit/lock-tests` exist? (a fix task is in progress; test files are locked)
   - Last commit touching `stagekit/<id>/`.

4. Name **the usual next action** and its command — a suggestion, not a rule;
   the user runs what they want. Use this order, stopping at the first unmet
   condition:

   | Condition | Next |
   |---|---|
   | no `intent.md` | `/stagekit:intent` |
   | `intent.md` not accepted | human reviews and accepts it |
   | no `spec.md` | `/stagekit:spec` |
   | `spec.md` has open flagged concerns | resolve them with the policy owner |
   | no `plan.md` | `/stagekit:plan` |
   | `plan.md` not approved | interrogate it, then approve |
   | plan approved, work not done | `/stagekit:build` |
   | code changed, not verified | `/stagekit:verify` |
   | verified, not reviewed | `/stagekit:review` |
   | reviewed, shipping | `/stagekit:gate` if a gate is missing |
   | merged and live | the human runs `/stagekit:done` — closes the change, clears `.stagekit/current` |

Keep the report short. The point is to name the next gate, not to summarize the change.
