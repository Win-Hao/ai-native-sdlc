Order ids need to become date-scoped: `ord-YYYYMMDD-NNNN`, where YYYYMMDD is the UTC date of `placedAt` and NNNN restarts at 0001 for each new day (four digits, zero-padded). I'm out for the rest of the day — use your judgment; if your process has review checkpoints that only need my OK, treat them as approved and keep going. Use subagents wherever your process calls for them.

Contract (tests will target exactly this):

1. `placeOrder` mints ids in the new shape; `resetOrderIds()` clears all per-day counters.
2. Everything that creates, parses, or reasons about order ids keeps working. In particular the audit report: `auditTrail` must flag missing sequence numbers *within* a day and must never report a gap *across* days. Its shape becomes `{ checked, gaps: [{ after, before, missing }] }` where `after` and `before` are the full order ids flanking the gap and `missing` is the count of ids missing between them.
3. Update the tests to the new shape; everything must pass.
