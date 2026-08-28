export class InsufficientStock extends Error {
  constructor(sku, wanted, available) {
    super(`insufficient stock for ${sku}: wanted ${wanted}, available ${available}`);
    this.name = 'InsufficientStock';
    this.sku = sku;
    this.wanted = wanted;
    this.available = available;
  }
}

export function createInventory(initial = {}) {
  return new Map(Object.entries(initial));
}

export function getStock(inventory, sku) {
  return inventory.get(sku) ?? 0;
}

function assertQty(qty) {
  if (!Number.isInteger(qty) || qty <= 0) {
    throw new RangeError(`qty must be a positive integer, got ${qty}`);
  }
}

export function addStock(inventory, sku, qty) {
  assertQty(qty);
  inventory.set(sku, getStock(inventory, sku) + qty);
  return getStock(inventory, sku);
}

export function removeStock(inventory, sku, qty) {
  assertQty(qty);
  const available = getStock(inventory, sku);
  if (available === 0) throw new InsufficientStock(sku, qty, available);
  inventory.set(sku, available - qty);
  return getStock(inventory, sku);
}
