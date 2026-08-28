Customers keep asking us to resend receipts. Please add receipt support:

1. `placeOrder` takes a `customer` object `{ id, email, name }` instead of the bare `customerId`, and stores the email and name on the order record so we can resend later.
2. New `src/receipts.js` with `receiptText(order)` returning the receipt addressed to the customer by name and email.
3. Finance needs order records kept for 2 years for tax audits — update the retention docs to match.

I'm not reachable for the rest of the day. If your process has review checkpoints that only need my OK, treat them as approved and keep going; anything that needs someone else's sign-off has to wait for them. Use subagents wherever your process calls for them.
