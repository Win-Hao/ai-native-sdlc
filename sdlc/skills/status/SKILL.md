---
name: status
description: Show where the active change sits in the AI-native SDLC loop — which artifacts exist, which gate is next, and what is blocking. Use when resuming work or when unsure which stage command comes next.
when_to_use: When the user asks where a change stands, what to do next in the SDLC, or resumes work on a repo that has an sdlc/ artifact directory.
allowed-tools: Read Glob Grep Bash(git status:*) Bash(git log:*) Bash(cat:*) Bash(ls:*)
---

# Where is this change in the loop?

1. Read `.sdlc/current` for the active change id. If absent, list `sdlc/*/` and
   ask which change is active (or `/sdlc:intent` to start one). A change whose
   `intent.md` carries `closed:` is finished; do not reopen it silently.
2. For that change, report the state of each artifact in `sdlc/<id>/`:

   | Artifact | Stage | Status |
   |---|---|---|
   | `intent.md` | 1 Plan | frontmatter `status`, or missing |
   | `spec.md` | 2 Design | `status`, plus count of **open** flagged concerns |
   | `plan.md` | 3 Build | `status`, plus whether `Deviations` is non-empty |

3. Report the working state:
   - `git status --short` — is the diff consistent with `plan.md` "Files that change"? Name any file changed that the plan did not name.
   - Does `.sdlc/lock-tests` exist? (a fix task is in progress; test files are locked)
   - Last commit touching `sdlc/<id>/`.

4. Name **the usual next action** and its command — a suggestion, not a rule;
   the user runs what they want. Use this order, stopping at the first unmet
   condition:

   | Condition | Next |
   |---|---|
   | no `intent.md` | `/sdlc:intent` |
   | `intent.md` not accepted | human reviews and accepts it |
   | no `spec.md` | `/sdlc:spec` |
   | `spec.md` has open flagged concerns | resolve them with the policy owner |
   | no `plan.md` | `/sdlc:plan` |
   | `plan.md` not approved | interrogate it, then approve |
   | plan approved, work not done | `/sdlc:build` |
   | code changed, not verified | `/sdlc:verify` |
   | verified, not reviewed | `/sdlc:review` |
   | reviewed, shipping | `/sdlc:gate` if a gate is missing |
   | merged and live | the human runs `/sdlc:done` — closes the change, clears `.sdlc/current` |

Keep the report short. The point is to name the next gate, not to summarize the change.
