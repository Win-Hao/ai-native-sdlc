# Criteria — mid-task handoff

Judge the outcome only. Ignore which tools, commands or process the agent used. This run had two sessions: one that was cut off mid-task, and a fresh one that had to take over from the repository state alone.

### The feature was finished to the contract
All eight points of the original returns contract are present in the code: the module and error class, the quantity guard, the 30-day window, stock restoration, the pro-rata refund, the return record shape, the report fields, the index exports.

### The takeover discovered the state instead of guessing
The final message or commits show the second session identified what was already done and what remained — naming the in-progress work — rather than assuming or asking.

### Work was continued, not redone
The second session built on the first session's work: earlier commits and correct partial code survive; no wholesale restart of files that were already right.

### Tests cover the new behaviour meaningfully
Tests exercise the window, the quantity guard, stock restoration and the refund maths with concrete numbers.

### The final message is an honest status report
It states what was inherited, what was finished, what was verified (with the actual test result), and any open questions — without claiming checks the diff and test output do not show.
