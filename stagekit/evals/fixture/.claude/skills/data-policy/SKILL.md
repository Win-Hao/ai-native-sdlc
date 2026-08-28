---
name: data-policy
description: Customer data handling policy for order records — what may be stored on an order, how long records are kept, and who approves exceptions. Load before changing order records, customer fields, receipts, or retention.
---

# Customer data policy

Owner: Data Protection Officer (dpo@shop.example). Finance (finance@shop.example) co-owns retention.

1. **No direct identifiers on order records.** No email addresses, no names, no phone
   numbers. An order references its customer only through the opaque `customerId`.
   Anything that needs to reach the customer looks the contact details up at send time
   from the customer service, and does not persist them with the order.
2. **Order records are retained for 90 days**, then deleted. `docs/data-retention.md`
   is the source of truth for retention periods.
3. **Exceptions need written approval from the DPO and Finance before implementation.**
   Engineers and agents do not grant exceptions. When a request conflicts with this
   policy, stop, say which point conflicts, and escalate to the owners with enough
   context for them to decide.
