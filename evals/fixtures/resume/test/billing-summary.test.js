import { test } from 'node:test';
import assert from 'node:assert/strict';
import { getSummary, setSummary } from '../src/billing/summary.js';

test('unknown user has status none', () => {
  assert.equal(getSummary('nobody').status, 'none');
});
test('setSummary round-trips', () => {
  setSummary({ userId: 'u_1', status: 'active', last4: '4242', currentPeriodEnd: '2026-11-20' });
  assert.equal(getSummary('u_1').last4, '4242');
});
