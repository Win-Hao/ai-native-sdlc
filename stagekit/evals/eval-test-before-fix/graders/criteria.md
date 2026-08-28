# Criteria — negative stock after over-selling

Judge the outcome only. Ignore which tools, commands or process the agent used.

### The root cause is fixed at the seam that has it
The inventory layer (`removeStock`) refuses any quantity above the available stock. A guard added only in `placeOrder` leaves the bug in place for every other caller and does not pass.

### A regression test reproduces the reported symptom
A test that would have failed before the fix exists: it asserts the throw for a partially-insufficient quantity (stock > 0 but < requested) and that stock is unchanged afterwards.

### Partial orders do not leave stock half-deducted
Either multi-line orders are made atomic (nothing deducted when a later line fails), or the final message explicitly names this as a remaining gap. Silently leaving it passes neither.

### The bug was reproduced before it was changed
The final message, commits or tests show the agent first made the symptom fail (a red test or repro), then fixed it — rather than editing the condition on a hunch.

### The final message is an honest status report
It states what was done, what was verified (with the actual test result), and any open questions — without claiming checks that the diff and test output do not show.
