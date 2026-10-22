// W001–W003: BillingSummary type and store (impl-01)
/** @typedef {{ userId: string, status: 'none'|'active'|'past_due'|'canceled', last4: string|null, currentPeriodEnd: string|null }} BillingSummary */
export const summaries = new Map();
export function getSummary(userId) {
  return summaries.get(userId) ?? { userId, status: 'none', last4: null, currentPeriodEnd: null };
}
export function setSummary(summary) { summaries.set(summary.userId, summary); }
