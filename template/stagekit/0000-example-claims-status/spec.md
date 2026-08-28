---
id: 0000-example-claims-status
stage: design
status: accepted
from_intent: ./intent.md
skills_applied: [secure-api-review, brand, portal-ux]
created: 2026-06-03
---

# Spec: claims status self-service

## Solution
Add a read-only claim status endpoint behind the existing portal auth, and a
panel in the portal that renders status, next step, and expected date.

## Requirements
| # | Requirement | Source | Acceptance |
|---|---|---|---|
| R1 | Portal shows status, next step, expected date for the signed-in customer's claims | intent.md#proposed-outcome | Panel renders all four claim states with the values claims-core returns |
| R2 | No authentication change | intent.md#constraints | Endpoint rejects any request without the gateway JWT |
| R3 | No new PII in the portal session | intent.md#constraints | Response contains no fields tagged `pii` in the claims-core schema |
| R4 | Does not exhaust the claims-core rate limit | intent.md#constraints | Panel reads through a cache; sustained portal load adds <5 rps to claims-core |

## Design decisions
### Approach
New `GET /claims/{id}/status` in claims-api, behind the existing gateway JWT,
projecting only the four non-PII fields from claims-core. A 60s per-claim cache
in claims-api absorbs portal polling. The portal adds `StatusPanel`, which reads
the endpoint and renders the four states.

Rejected: reading claims-core directly from the portal (would put a second
consumer on the rate limit and push PII into the browser).

### Interfaces / data
`GET /claims/{id}/status` → `{ status, next_step, expected_date, updated_at }`.
`status` is one of `received | assessing | awaiting_documents | settled`.

### UX
One panel per claim in the existing claims list. Each of the four states has a
distinct label and colour from the brand palette. Unknown state renders the
generic "in progress" copy rather than an error.

## Testing decisions
Two seams, both existing. The claims-api HTTP layer through the test client in
`claims-api/tests/`: R1–R4 are all observable there (status per state, 401
without the JWT, the exact field list, a second request not reaching
claims-core). And the portal component tests for `StatusPanel`. Nothing is
tested below the endpoint — the projection and the cache are implementation.
Prior art: `test_claims.py` for endpoint tests with the JWT fixture,
`ClaimsList.test.tsx` for state rendering.

## Non-functional
p95 under 300ms served from cache. Cache miss falls through to claims-core with
a 2s timeout; on timeout the panel shows last-known status with its `updated_at`.

## Policy application
| Policy | How this spec satisfies it |
|---|---|
| secure-api-review | Gateway JWT required (R2); request validated against the OpenAPI schema; state-changing audit events not needed — endpoint is read-only; no `pii`-tagged field is projected (R3) |
| brand | Four state labels and colours taken from the brand palette |
| portal-ux | Failure renders last-known state, not an error banner |

## ⚠ Flagged concerns
| # | Concern | Policy owner | Status |
|---|---|---|---|
| C1 | `expected_date` is an internal estimate. Showing it to customers may create a commitment the business does not intend | Claims ops lead | resolved: ship as "estimated", with the disclaimer copy the legal team supplied |
| C2 | A 60s cache means a handler and a customer can see different status for up to a minute | Claims ops lead | resolved: accepted; the panel shows `updated_at` so the difference is visible |

## Answers to intent open questions
Loss adjusters: **out of scope for this change.** They authenticate through a
different identity provider, which R2 forbids touching. Carried forward as a
separate intent, owned by the claims ops lead.

## Out of scope
Everything in intent.md, plus loss-adjuster access.

## Notes
None.
