---
id: <NNNN-slug>
stage: deploy
status: reviewed
reviewed: <YYYY-MM-DD>
base: <diff 对照的基准——分支、PR 号或 commit>
important: <n>
nits: <n>
---

# Review: <标题>

| # | Pass | Severity | Class | Where | Finding | Status |
|---|---|---|---|---|---|---|
| F1 | bugs / security / compliance | Important / nit | <REVIEW.md 里的 class slug> | `path:line` | <什么输入或状态 → 什么错误输出或崩溃> | open / fixed / accepted: <理由> |

<Important 全部列出；nit 列到 REVIEW.md 的上限，其余在下面计数。>

## Repeats
<每个在以前 review 里出现过的 class：这是第几次、出现在哪些变更、做了什么——第 2 次写进 CLAUDE.md，第 3 次起提议 hook 或 skill。全是新 class 就写 None。>

## Not listed
<n> 条 nit 超出上限未列。

## CLAUDE.md
<写进 "Things Claude gets wrong" 的条目，或 unchanged；这个变更让 CLAUDE.md 哪里过时了。>
