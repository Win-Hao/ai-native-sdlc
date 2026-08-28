import { round2 } from './pricing.js';

// day: 'YYYY-MM-DD'
export function dailyReport(orders, day) {
  const todays = orders.filter((order) => order.placedAt.slice(0, 10) === day);
  return {
    day,
    orders: todays.length,
    revenue: round2(todays.reduce((sum, order) => sum + order.total, 0)),
  };
}
