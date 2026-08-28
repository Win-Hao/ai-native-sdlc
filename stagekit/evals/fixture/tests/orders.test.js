import { test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { createInventory, getStock, placeOrder, resetOrderIds, dailyReport, InsufficientStock } from '../src/index.js';

const catalog = { A: 10, B: 2.5 };

beforeEach(() => resetOrderIds());

test('placeOrder prices each line, deducts stock and stamps the order', () => {
  const inv = createInventory({ A: 20, B: 50 });
  const order = placeOrder(inv, catalog, 'c-1', [{ sku: 'A', qty: 10 }, { sku: 'B', qty: 4 }], new Date('2026-03-01T10:00:00Z'));
  assert.equal(order.id, 'ord-0001');
  assert.equal(order.customerId, 'c-1');
  assert.deepEqual(order.lines, [{ sku: 'A', qty: 10, total: 95 }, { sku: 'B', qty: 4, total: 10 }]);
  assert.equal(order.total, 105);
  assert.equal(order.placedAt, '2026-03-01T10:00:00.000Z');
  assert.equal(getStock(inv, 'A'), 10);
  assert.equal(getStock(inv, 'B'), 46);
});

test('an order for a sku that is out of stock fails', () => {
  const inv = createInventory({ A: 0 });
  assert.throws(() => placeOrder(inv, catalog, 'c-1', [{ sku: 'A', qty: 1 }]), InsufficientStock);
});

test('an order needs at least one line', () => {
  const inv = createInventory({ A: 5 });
  assert.throws(() => placeOrder(inv, catalog, 'c-1', []), RangeError);
});

test('dailyReport counts only that day', () => {
  const inv = createInventory({ A: 100 });
  const o1 = placeOrder(inv, catalog, 'c-1', [{ sku: 'A', qty: 1 }], new Date('2026-03-01T09:00:00Z'));
  const o2 = placeOrder(inv, catalog, 'c-2', [{ sku: 'A', qty: 2 }], new Date('2026-03-01T23:00:00Z'));
  const o3 = placeOrder(inv, catalog, 'c-3', [{ sku: 'A', qty: 3 }], new Date('2026-03-02T01:00:00Z'));
  assert.deepEqual(dailyReport([o1, o2, o3], '2026-03-01'), { day: '2026-03-01', orders: 2, revenue: 30 });
  assert.deepEqual(dailyReport([o1, o2, o3], '2026-03-03'), { day: '2026-03-03', orders: 0, revenue: 0 });
});
