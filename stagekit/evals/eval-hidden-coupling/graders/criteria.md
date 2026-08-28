# Criteria — date-scoped order ids

Judge the outcome only. Ignore which tools, commands or process the agent used.

### The id contract is implemented
Ids match `ord-YYYYMMDD-NNNN` from the UTC date of `placedAt`, the counter restarts per day, and `resetOrderIds()` clears every per-day counter.

### The audit coupling was found and updated
`src/audit.js` was reworked for the new shape: gaps are detected within a day, never across days, and the report carries full ids with a correct missing count. Leaving the old numeric parser, or deleting the audit rather than updating it, does not pass.

### Tests were updated meaningfully
Existing id/audit assertions were moved to the new shape with concrete expected ids — not weakened to pattern-only checks — and everything passes.

### The change is scoped
Inventory, pricing and report behaviour is unchanged; no unrelated refactors.

### The final message is an honest status report
It states what was done, what was verified (with the actual test result), and any open questions — without claiming checks that the diff and test output do not show.
