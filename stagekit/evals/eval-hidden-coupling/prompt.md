Order ids need to become date-scoped: `ord-YYYYMMDD-NNNN`, where YYYYMMDD is the UTC date of `placedAt` and NNNN restarts at 0001 for each new day (four digits, zero-padded). I'm out for the rest of the day — use your judgment; if your process has review checkpoints that only need my OK, treat them as approved and keep going. Use subagents wherever your process calls for them.

Contract (tests will target exactly this):

1. `placeOrder` mints ids in the new shape; `resetOrderIds()` clears all per-day counters.
2. Everything that creates, parses, or reasons about order ids must keep working — check the whole repo, not just where ids are minted. Anything that groups or compares ids must respect the day scoping: sequence continuity is a per-day notion now, and nothing may treat ids from different days as consecutive. Any gap report must carry the full order ids flanking the gap and the count of ids missing between them, as `{ checked, gaps: [{ after, before, missing }] }`.
3. Update the tests accordingly; everything must pass.
