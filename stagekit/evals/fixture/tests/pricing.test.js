import { test } from 'node:test';
import assert from 'node:assert/strict';
import { lineTotal, unitPrice, discountRate } from '../src/pricing.js';

const catalog = { A: 10, B: 2.5 };

test('unknown skus are rejected', () => {
  assert.throws(() => unitPrice(catalog, 'Z'), /unknown sku/);
});

test('volume tiers', () => {
  assert.equal(discountRate(1), 0);
  assert.equal(discountRate(10), 0.05);
  assert.equal(discountRate(100), 0.15);
});

test('line totals apply the tier and round to cents', () => {
  assert.equal(lineTotal(catalog, 'A', 1), 10);
  assert.equal(lineTotal(catalog, 'A', 10), 95);
  assert.equal(lineTotal(catalog, 'B', 3), 7.5);
  assert.equal(lineTotal(catalog, 'B', 100), 212.5);
});
