import { test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { createInventory, getStock, removeStock, placeOrder, resetOrderIds } from '../src/index.js';

const catalog = { A: 10, B: 2.5 };

beforeEach(() => resetOrderIds());

test('removing more than available throws and leaves stock unchanged', () => {
  const inv = createInventory({ A: 2 });
  assert.throws(() => removeStock(inv, 'A', 5));
  assert.equal(getStock(inv, 'A'), 2);
});

test('an order for more than available fails and deducts nothing', () => {
  const inv = createInventory({ A: 2 });
  assert.throws(() => placeOrder(inv, catalog, 'c-1', [{ sku: 'A', qty: 5 }]));
  assert.equal(getStock(inv, 'A'), 2);
});

test('removing exactly the available quantity still works', () => {
  const inv = createInventory({ A: 2 });
  assert.equal(removeStock(inv, 'A', 2), 0);
});

test('a multi-line order that cannot be fully filled deducts nothing (atomic)', () => {
  const inv = createInventory({ A: 10, B: 1 });
  assert.throws(() => placeOrder(inv, catalog, 'c-1', [{ sku: 'A', qty: 3 }, { sku: 'B', qty: 2 }]));
  assert.equal(getStock(inv, 'A'), 10);
  assert.equal(getStock(inv, 'B'), 1);
});
