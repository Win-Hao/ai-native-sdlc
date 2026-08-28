---
id: 0000-example-claims-status
stage: plan
status: accepted
author: J. Ortiz (claims operations)
origin: person
created: 2026-06-02
---

# Intent: claims status self-service

## Problem
Customers phone the contact center to ask where their claim is. Handlers spend
roughly a third of call time on status-only queries, and the answer is already
in claims-core — the customer just has no way to see it.

## Proposed outcome
Customers see claim status, the next step, and the expected date in the portal,
without calling. Success looks like status-only calls falling by half within a
quarter of launch.

## Affected users and systems
Claims handlers (fewer status calls), portal customers, the portal team, and the
claims-core API.

## Constraints
No new PII in the portal session. Existing authentication only — no new login
flow. claims-core rate-limits at 50 rps and is shared with the handler console.

## Open questions
Do third-party loss adjusters need access too? If so, under which identity?

## Out of scope
Claim submission, document upload, and anything that writes to claims-core.
This change is read-only.
