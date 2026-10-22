# Implementation plan 02 of 2 — Stripe checkout and webhook

plan: plan.md
status: not started
owner: unassigned

## Scope
Closes R-01 and R-04: checkout session creation and the verified, idempotent webhook that writes BillingSummary.

## Owns (files and globs — exclusive to this plan)
- src/routes/billing.js
- src/billing/webhook.js
- test/webhook.test.js
- src/server.js

## Depends on
- impl-01 W004 (account route consumes the summary the webhook writes)

## Interfaces
- consumes: `setSummary` from impl-01 (frozen in plan.md)

## Ambiguities (must be empty to proceed)

## Tasks
### W005 [R-01, D-03] Checkout session route — src/routes/billing.js
### W006 [R-04, D-02] Webhook handler with signature verification — src/billing/webhook.js
### W007 [T-04, T-05] Forged and replayed webhook tests — test/webhook.test.js

## Verification
```bash
npm test
```

## Review log
- Cycle 1 of 3 (2026-10-20, fresh-context): HIGH security W006 verify-before-store → fixed.

## Progress log
