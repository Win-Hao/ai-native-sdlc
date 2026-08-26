---
name: review
description: Stage 5 Deploy (a) — run the REVIEW.md passes over the change (bugs, security, compliance against spec.md and plan.md), rank findings by severity, and feed repeat findings back into CLAUDE.md.
when_to_use: When the user runs /sdlc:review or asks for a review of a diff, branch or PR, or when this repo's SDLC driver is on (`drive: auto`) and a change is verified.
argument-hint: "[PR number | branch | diff]"
allowed-tools: Read Glob Grep Bash(git:*) Bash(gh:*) Bash(rg:*)
---

# Stage 5a — Review in both directions

> **Defaults:** without `.sdlc/config.json` the artifact directory is `sdlc/` and the templates are the plugin's. Say once that `/sdlc:init` configures gates, templates and the driver, then carry on.

All changes get an identical set of passes. Human attention moves up a level: to
whether the change does what the plan intended and whether the risk is acceptable.

## Steps

1. **Get the diff.** From the argument: a PR number (`gh pr diff`), a branch
   (`git diff <base>...HEAD`), or the working tree (`git diff HEAD`).

2. **Run the passes in `REVIEW.md`.** If it is missing, write it first from
   `.sdlc/templates/REVIEW.md` if the project has one, otherwise `${CLAUDE_PLUGIN_ROOT}/templates/REVIEW.md` — an unwritten review policy is
   applied inconsistently by definition. The three passes:
   - **Bugs** — logic errors, broken edge cases, subtle regressions, unhandled
     error paths, concurrency.
   - **Security** — injection, authn/authz gaps, PII in logs or errors, secrets
     in the diff, unsafe deserialization.
   - **Compliance** — the diff against `spec.md`: requirements missing or
     partial, behaviour nobody asked for (scope creep), requirements that look
     implemented but wrong, quoting the spec line for each; then against
     `plan.md` "Files that change" and "Proof", `CLAUDE.md` and repo skills.
     Where there is no spec or plan, compliance is against what the user asked
     for and `CLAUDE.md`.

   For a large or high-risk diff, run the `sdlc-reviewer` subagent so the passes
   get a clean context.

3. **Rank by severity, and mean it.** **Important** = would break behavior, leak
   data, or breach a policy. For each Important finding, write a concrete failure
   scenario: inputs or state → wrong output or crash. If you cannot write one, it
   is a nit. Cap nits per `REVIEW.md` and summarize the rest as a count.

4. **Report nothing CI already enforces**, and nothing in the excluded paths.
   A review that repeats the linter trains people to skim reviews.

5. **Feed findings back.** When a finding appears for the **second** time, put
   the correction into `CLAUDE.md` "Things Claude gets wrong" as part of this
   review. Because review reads `CLAUDE.md`, it is caught from the next change
   onward. Also flag when the change has made `CLAUDE.md` outdated.

6. **End with the machine-readable tally**:
   ```
   IMPORTANT=<n> NITS=<n> PASSES=bugs,security,compliance
   ```

## The gate

Findings do not approve or block on their own, and you have no route to approve
this change. A human merges, informed by the findings. Say this plainly if asked
to merge.

Usually next: the human merges, then `/sdlc:done` closes the change.
`/sdlc:gate` if the release path is not gated yet.
