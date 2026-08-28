import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createInventory, getStock, addStock, removeStock, InsufficientStock } from '../src/inventory.js';

test('addStock accumulates and getStock defaults to 0', () => {
  const inv = createInventory();
  assert.equal(getStock(inv, 'A'), 0);
  assert.equal(addStock(inv, 'A', 3), 3);
  assert.equal(addStock(inv, 'A', 2), 5);
});

test('removeStock reduces the count', () => {
  const inv = createInventory({ A: 5 });
  assert.equal(removeStock(inv, 'A', 2), 3);
  assert.equal(getStock(inv, 'A'), 3);
});

test('removeStock from an empty sku throws InsufficientStock', () => {
  const inv = createInventory();
  assert.throws(() => removeStock(inv, 'A', 1), InsufficientStock);
});

test('quantities must be positive integers', () => {
  const inv = createInventory({ A: 5 });
  assert.throws(() => addStock(inv, 'A', 0), RangeError);
  assert.throws(() => removeStock(inv, 'A', 1.5), RangeError);
});
