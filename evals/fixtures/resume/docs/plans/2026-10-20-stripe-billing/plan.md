# Plan — Stripe billing

mode: advanced
quiz: off
status: implementing
created: 2026-10-20
constitution: none

## Now
impl-01 W004 in progress; impl-02 not started (depends on impl-01 W004).

## Goal
Existing users can subscribe to the single monthly plan via Stripe Checkout; the account page shows subscription status from a locally cached summary that only the webhook handler writes.

## Architecture
`src/billing/summary.js` (D-01 cached BillingSummary) · `src/billing/webhook.js` (D-02 verified webhook writes summary) · `src/routes/billing.js` (D-03 checkout session) · `src/routes/account.js` extended (R-03).

## Tech stack
Express 4, node:test (from recon). New: official `stripe` SDK (D-02).

## Global constraints
- No card data stored; summary holds status, last4, period end only (R-02).
- Every write from Stripe passes signature verification first (D-02).

## Review focus
1. Forged or replayed webhooks. 2. Account page with no summary row. 3. Webhook ordering. 4. Secret missing at boot. 5. Cancel then failed renewal precedence.

## Ambiguities (must be empty to proceed)

## Traceability matrix
| Requirement | Design | Tests | Tasks |
|---|---|---|---|
| R-01 Checkout for existing users | D-03 | T-01 | W005 |
| R-02 Never store card data; cache summary | D-01 | T-02 | W001, W002, W003 |
| R-03 Account page shows status instantly | D-01 | T-03 | W004 |
| R-04 Webhook verified, idempotent | D-02 | T-04, T-05 | W006, W007 |

## Pre-flight conflict table
| Shared file or interface | Plans involved | Frozen contract |
|---|---|---|
| `BillingSummary` type + `getSummary/setSummary` | impl-01 (produces), impl-02 (consumes) | `src/billing/summary.js` as of W003 |

## Tasks
### Sequential chain: summary and account (impl-01)
- [x] W001 [R-02, D-01] BillingSummary type — src/billing/summary.js
- [x] W002 [R-02, D-01] in-memory summary store — src/billing/summary.js
- [x] W003 [T-02] summary store tests — test/billing-summary.test.js
- [ ] W004 [R-03, T-03] account route returns billing summary — src/routes/account.js, test/account.test.js
### Sequential chain: Stripe integration (impl-02, depends on: W004)
- [ ] W005 [R-01, D-03] checkout session route — src/routes/billing.js
- [ ] W006 [R-04, D-02] webhook handler with signature verification — src/billing/webhook.js
- [ ] W007 [T-04, T-05] forged + replayed webhook tests — test/webhook.test.js

## Critical path
W001 → W004 → W006 → W007

## Review log
- Cycle 1 of 3 (2026-10-20, fresh-context): HIGH security W006 verify before store → fixed ordering; MEDIUM perf W004 none.

## Rulings
- Ruling: harness = Claude Code — detected from tool list — cost if wrong: dispatch falls back to sequential
- Ruling: use official stripe SDK — why: signature helper maintained upstream — cost if wrong: one adapter module to replace
