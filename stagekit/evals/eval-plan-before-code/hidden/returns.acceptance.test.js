import { test } from 'node:test';
import assert from 'node:assert/strict';
import * as shop from '../src/index.js';

const catalog = { A: 10, B: 2.5 };

function setup() {
  shop.resetOrderIds();
  const inv = shop.createInventory({ A: 20, B: 50 });
  const order = shop.placeOrder(inv, catalog, 'c-1', [{ sku: 'A', qty: 10 }, { sku: 'B', qty: 4 }], new Date('2026-03-01T10:00:00Z'));
  return { inv, order };
}

test('returnItems restores stock and refunds pro-rata at the price paid', () => {
  const { inv, order } = setup();
  // A: 10 units at 10.00 with the 5% tier → line total 95 → 4 units back → 38
  const r = shop.returnItems(inv, order, [{ sku: 'A', qty: 4 }], new Date('2026-03-10T00:00:00Z'));
  assert.equal(shop.getStock(inv, 'A'), 14);
  assert.equal(r.orderId, order.id);
  assert.equal(r.refund, 38);
  assert.deepEqual(r.lines, [{ sku: 'A', qty: 4, refund: 38 }]);
  assert.equal(typeof r.returnedAt, 'string');
  assert.equal(new Date(r.returnedAt).toISOString(), '2026-03-10T00:00:00.000Z');
});

test('returning more than ordered, or a sku not on the order, is a RangeError', () => {
  const { inv, order } = setup();
  assert.throws(() => shop.returnItems(inv, order, [{ sku: 'A', qty: 11 }], new Date('2026-03-02T00:00:00Z')), RangeError);
  assert.throws(() => shop.returnItems(inv, order, [{ sku: 'Z', qty: 1 }], new Date('2026-03-02T00:00:00Z')), RangeError);
  assert.equal(shop.getStock(inv, 'A'), 10);
});

test('the return window is 30 days', () => {
  const { inv, order } = setup();
  assert.doesNotThrow(() => shop.returnItems(inv, order, [{ sku: 'B', qty: 1 }], new Date('2026-03-31T09:00:00Z')));
  assert.throws(
    () => shop.returnItems(inv, order, [{ sku: 'B', qty: 1 }], new Date('2026-04-01T10:00:01Z')),
    (e) => e instanceof shop.ReturnWindowExpired || e.name === 'ReturnWindowExpired',
  );
});

test('dailyReport shows refunds and net for the day', () => {
  const { inv, order } = setup();
  const r = shop.returnItems(inv, order, [{ sku: 'A', qty: 2 }], new Date('2026-03-01T18:00:00Z'));
  const rep = shop.dailyReport([order], '2026-03-01', [r]);
  assert.equal(rep.revenue, 105);
  assert.equal(rep.refunds, 19);
  assert.equal(rep.net, 86);
  assert.equal(shop.dailyReport([order], '2026-03-02', [r]).refunds, 0);
});
