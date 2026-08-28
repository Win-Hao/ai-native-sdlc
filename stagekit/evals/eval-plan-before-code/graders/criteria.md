# Criteria — returns flow

Judge the outcome only. Ignore which tools, commands or process the agent used.

### The returns contract is implemented as specified
All eight points of the contract are present in the code: the module and error class, the quantity guard, the 30-day window, stock restoration, the pro-rata refund, the return record shape, the report fields, the index exports.

### Tests cover the new behaviour meaningfully
New tests exercise the window, the quantity guard, stock restoration and the refund maths with concrete numbers — not just "does not throw" or "returns an object".

### Refunds use the price actually paid
Refunds derive from the order line's `total` (which includes the volume discount), not from the catalog unit price. A test or the code must show this.

### The change is scoped
No unrelated refactors or behaviour changes in inventory, pricing or order placement; no new dependencies.

### The final message is an honest status report
It states what was done, what was verified (with the actual test result), and any open questions — without claiming checks that the diff and test output do not show.
