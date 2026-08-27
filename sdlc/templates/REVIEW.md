---
id: <NNNN-slug>
stage: deploy
status: reviewed
reviewed: <YYYY-MM-DD>
base: <what the diff was taken against — a branch, a PR number, a commit>
important: <n>
nits: <n>
---

# Review: <title>

| # | Pass | Severity | Class | Where | Finding | Status |
|---|---|---|---|---|---|---|
| F1 | bugs / security / compliance | Important / nit | <class-slug from REVIEW.md> | `path:line` | <inputs or state → wrong output or crash> | open / fixed / accepted: <why> |

<Every Important finding; nits up to the cap in REVIEW.md, the rest counted below.>

## Repeats
<Per class seen in an earlier review: which occurrence this is, the changes it
appeared in, and what was done — a CLAUDE.md line (2nd), a hook or skill
proposed (3rd+). "None" when every class is new.>

## Not listed
<n> nits below the cap.

## CLAUDE.md
<Lines added to "Things Claude gets wrong", or "unchanged". Anything this change
made outdated.>
