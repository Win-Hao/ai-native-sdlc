import { test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { createInventory, placeOrder, resetOrderIds, auditTrail } from '../src/index.js';

const catalog = { A: 10 };

beforeEach(() => resetOrderIds());

test('ids are date-scoped and restart each day', () => {
  const inv = createInventory({ A: 100 });
  const a1 = placeOrder(inv, catalog, 'c', [{ sku: 'A', qty: 1 }], new Date('2026-03-01T10:00:00Z'));
  const a2 = placeOrder(inv, catalog, 'c', [{ sku: 'A', qty: 1 }], new Date('2026-03-01T11:00:00Z'));
  const b1 = placeOrder(inv, catalog, 'c', [{ sku: 'A', qty: 1 }], new Date('2026-03-02T09:00:00Z'));
  assert.equal(a1.id, 'ord-20260301-0001');
  assert.equal(a2.id, 'ord-20260301-0002');
  assert.equal(b1.id, 'ord-20260302-0001');
});

test('audit flags a gap within a day', () => {
  const r = auditTrail([{ id: 'ord-20260301-0001' }, { id: 'ord-20260301-0004' }]);
  assert.deepEqual(r.gaps, [{ after: 'ord-20260301-0001', before: 'ord-20260301-0004', missing: 2 }]);
});

test('audit never reports a gap across days', () => {
  const r = auditTrail([{ id: 'ord-20260301-0001' }, { id: 'ord-20260301-0002' }, { id: 'ord-20260302-0001' }]);
  assert.deepEqual(r.gaps, []);
});
