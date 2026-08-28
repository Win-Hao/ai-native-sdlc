import { removeStock } from './inventory.js';
import { lineTotal, round2 } from './pricing.js';

let seq = 0;

export function resetOrderIds() {
  seq = 0;
}

// lines: [{ sku, qty }]. Deducts stock and returns the order record.
export function placeOrder(inventory, catalog, customerId, lines, placedAt = new Date()) {
  if (!Array.isArray(lines) || lines.length === 0) {
    throw new RangeError('an order needs at least one line');
  }
  const priced = lines.map(({ sku, qty }) => ({ sku, qty, total: lineTotal(catalog, sku, qty) }));
  for (const { sku, qty } of priced) removeStock(inventory, sku, qty);
  seq += 1;
  return {
    id: `ord-${String(seq).padStart(4, '0')}`,
    customerId,
    lines: priced,
    total: round2(priced.reduce((sum, line) => sum + line.total, 0)),
    placedAt: new Date(placedAt).toISOString(),
  };
}
