// Sequence-gap audit over order ids. A minted id missing from the export means
// a lost record; finance reconciles from this report each month.
export function auditTrail(orders) {
  const seqs = orders
    .map((order) => Number.parseInt(order.id.slice(4), 10))
    .sort((a, b) => a - b);
  const gaps = [];
  for (let i = 1; i < seqs.length; i++) {
    if (seqs[i] - seqs[i - 1] > 1) {
      gaps.push({ after: seqs[i - 1], before: seqs[i], missing: seqs[i] - seqs[i - 1] - 1 });
    }
  }
  return { checked: orders.length, gaps };
}
