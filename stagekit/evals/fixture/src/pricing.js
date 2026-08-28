export function round2(n) {
  return Math.round(n * 100) / 100;
}

export function unitPrice(catalog, sku) {
  const price = catalog[sku];
  if (price === undefined) throw new Error(`unknown sku: ${sku}`);
  return price;
}

// Volume tiers: 10+ units 5% off, 100+ units 15% off.
export function discountRate(qty) {
  if (qty >= 100) return 0.15;
  if (qty >= 10) return 0.05;
  return 0;
}

export function lineTotal(catalog, sku, qty) {
  return round2(unitPrice(catalog, sku) * qty * (1 - discountRate(qty)));
}
