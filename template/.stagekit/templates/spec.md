---
id: <NNNN-slug>            # 与 intent.md 相同
stage: design
status: draft              # draft | accepted
from_intent: ./intent.md
skills_applied: []         # 本次生成时加载的 skills，例如 [secure-api-review, brand]
created: <YYYY-MM-DD>
---

# Spec: <标题>

## Solution
<用户拿到的是什么，站在用户视角一段话说完。问题已经写在 intent.md 里——引用它，不要复述。>

## Requirements
| # | Requirement | Source | Acceptance |
|---|---|---|---|
| R1 | 作为 <角色>，我要 <能力>，以便 <收益> | intent.md#proposed-outcome | <怎么算通过> |

<要穷尽：每个角色、每种状态、失败路径。没人能检查的需求不是需求。>

## Design decisions
<写决策，不写工作：哪些模块新建或修改、它们的接口、API 契约、schema 变更、彼此怎么交互、为什么。
用项目自己的词汇（有 CONTEXT.md 就用它的），与 ADR 冲突要标出来。
**不写文件路径、不贴代码**——它们在开工前就会过期，路径归 plan.md。
唯一例外：原型产出的、比文字更精确表达决策的片段（schema、状态机、类型），裁到只剩决策本身。>

### Approach
<选定方案，以及被否决的替代方案和理由。>

### Interfaces / data
<契约：接口签名、数据结构、schema 变更、迁移。>

### UX
<关键界面与状态，或链接到 mock。>

## Testing decisions
<在哪个接缝测、为什么是那里。选能观察到该行为的**最高的现有接缝**，接缝越少越好，理想是一个。
只测外部行为，不测实现。指出仓库里已有的、长得像的测试作为先例。plan.md 的 Proof 从这一节写出来。>

## Non-functional
<性能、可用性、限流、可观测性、成本。>

## Policy application
<逐条说明本次应用了哪些组织政策（skills），以及怎么满足的。>

| Policy | How this spec satisfies it |
|---|---|
| <security / brand / ux / compliance> | <说明> |

## ⚠ Flagged concerns
<最重要的一节。写下无法同时满足的政策冲突、需要政策所有者拍板的点。>

| # | Concern | Policy owner | Status |
|---|---|---|---|
| C1 | <冲突或风险> | <谁来拍板> | open / resolved: <结论> |

## Answers to intent open questions
<逐条回答 intent.md 的 open questions；答不了的写明为什么、由谁在何时回答。>

## Out of scope
<继承 intent.md 并补充。>

## Notes
<plan 阶段还需要知道的其他事。>
