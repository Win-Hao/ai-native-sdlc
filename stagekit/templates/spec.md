---
id: <NNNN-slug>            # same as intent.md
stage: design
status: draft              # draft | accepted
from_intent: ./intent.md
skills_applied: []         # skills loaded while writing this, e.g. [secure-api-review, brand]
created: <YYYY-MM-DD>
---

# Spec: <title>

## Solution
<What the user gets, from the user's perspective, in one paragraph. The problem
is already in intent.md — link it, do not restate it.>

## Requirements
| # | Requirement | Source | Acceptance |
|---|---|---|---|
| R1 | As <actor>, I want <capability>, so that <benefit> | intent.md#proposed-outcome | <how it is checked> |

<Be exhaustive: every actor, every state, the failure paths. A requirement no
one can check is not a requirement.>

## Design decisions
<Decisions, not work: which modules are built or changed and their interfaces,
API contracts, schema changes, how they interact, and why. Use the project's
own vocabulary (CONTEXT.md if there is one) and flag any conflict with an ADR.
No file paths and no code — they go stale before build starts; paths belong in
plan.md. Exception: a snippet from a prototype that states a decision more
precisely than prose (a schema, a state machine, a type), trimmed to the
decision.>

### Approach
<The chosen approach, and the alternative rejected with the reason.>

### Interfaces / data
<Contracts: signatures, data shapes, schema changes, migrations.>

### UX
<Key screens and states, or a link to the mock.>

## Testing decisions
<Where the behaviour is tested and why there. Name the seam — the highest
existing one that can observe it; the ideal number of seams is one. Test
external behaviour, not implementation. Point at prior art: the tests in this
repo that already look like the ones needed. plan.md's Proof is written from
this section.>

## Non-functional
<Performance, availability, rate limits, observability, cost.>

## Policy application
<Per organizational policy (skill): which rule applies and how this spec satisfies it.>

| Policy | How this spec satisfies it |
|---|---|
| <security / brand / ux / compliance> | <how> |

## ⚠ Flagged concerns
<The most important section. Policies that cannot both be satisfied, and
decisions that need an owner who is not you. A concern freezes only the
requirements in its Blocks column; requirements no open concern touches are
clear to plan and build now.>

| # | Concern | Blocks | Policy owner | Status |
|---|---|---|---|---|
| C1 | <conflict or risk> | <requirement ids this freezes, e.g. R2 R5> | <who decides> | open / resolved: <decision> |

## Answers to intent open questions
<Answer each open question from intent.md. For any you cannot, say why, and
who answers it by when.>

## Out of scope
<Inherited from intent.md, plus anything added here.>

## Notes
<Anything else the plan stage should know.>
