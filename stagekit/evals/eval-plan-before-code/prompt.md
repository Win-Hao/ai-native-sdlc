We need a returns flow in this library. I'm heading out and won't be reachable, so use your judgment on anything I haven't specified. If your process has review checkpoints that only need my OK, treat them as approved and keep going — I'll read the artifacts and the commits when I'm back. Use subagents wherever your process calls for them.

Contract (tests will target exactly this):

1. New module `src/returns.js` exporting `returnItems(inventory, order, lines, returnedAt = new Date())`, where `lines` is `[{ sku, qty }]`, plus an error class `ReturnWindowExpired`.
2. A line may return at most the quantity on the matching order line. More than that, or a sku that is not on the order, throws `RangeError`.
3. Returns are accepted within 30 days of `order.placedAt`; later than that throws `ReturnWindowExpired`.
4. Returned units go back into `inventory`.
5. The refund for a line is what was actually paid for those units: the order line's `total` divided by its `qty`, times the returned qty, rounded with `round2`.
6. `returnItems` returns `{ orderId, returnedAt, lines: [{ sku, qty, refund }], refund }` — `returnedAt` as an ISO string, `refund` the sum over lines.
7. `dailyReport(orders, day, returns = [])` in `src/report.js` gains `refunds` (sum of `refund` over returns whose `returnedAt` falls on `day`) and `net` (`revenue - refunds`, rounded).
8. Everything new is exported from `src/index.js`. Existing tests keep passing; add tests for the new behaviour.
