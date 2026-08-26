---
id: 0000-example-claims-status
stage: build
status: approved
from_spec: ./spec.md
approved_by: M. Chen (tech lead)
created: 2026-06-04
---

# Plan: claims status self-service (from spec.md 2026-06-03)

## Files that change
- `claims-api/routes/status.py` (new) — the endpoint, projection, and cache read
- `claims-api/cache.py` (modify) — add a 60s per-claim TTL namespace
- `claims-api/tests/test_status.py` (new) — the four states, auth rejection, PII absence, cache behavior
- `portal/src/claims/StatusPanel.tsx` (new) — the panel
- `portal/src/claims/ClaimsList.tsx` (modify) — mount the panel per claim
- `portal/src/claims/StatusPanel.test.tsx` (new) — renders four states plus the stale-cache case

## Order of work
1. Add the status endpoint behind the existing gateway JWT, projecting only the
   four fields. No cache yet — verify the projection and the auth rejection first.
2. Add the 60s cache namespace and wire the endpoint through it. Verify a second
   request inside the window does not reach claims-core.
3. Build `StatusPanel` against the endpoint, all four states plus the timeout path.
4. Mount it in `ClaimsList`.

Each step ships independently: after step 1 the endpoint is correct but uncached,
which is a shippable state.

## Risks
- claims-core rate-limits at 50 rps and is shared with the handler console.
  **Step 2 is the riskiest** — if the cache namespace collides with an existing
  key prefix, the handler console reads stale claim data. Check `cache.py`
  prefixes before adding one.
- The claims-core schema tags PII per field. If a field is retagged upstream,
  the projection silently starts leaking. Test R3 by asserting on the allowed
  field list, not on the absence of known-bad names.

## Alternatives not taken
- **Portal reads claims-core directly** — rejected in the spec: second consumer
  on the rate limit, PII in the browser.
- **Server-sent events instead of polling** — no rate-limit pressure, but adds a
  connection type the portal does not use anywhere else. Not worth it for a
  60s-granularity value.

## Proof
- `claims-api/tests/test_status.py` covers: the four claim states; request
  without JWT returns 401; response keys equal exactly the four allowed fields;
  second request within 60s does not call claims-core.
- `portal/src/claims/StatusPanel.test.tsx` covers the four states and the
  timeout path rendering last-known status with `updated_at`.
- `make test` green, `make lint` zero warnings.
- Screenshot of the claims list matches `design/mock-claims-status.png`.

## Deviations
None.
