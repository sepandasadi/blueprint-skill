# Implementation plan 01 of 2 — Billing summary and account page

plan: plan.md
status: in progress
owner: implementer-01

## Scope
Closes R-02 and R-03: a cached BillingSummary and the account route that returns it.

## Owns (files and globs — exclusive to this plan)
- src/billing/summary.js
- src/routes/account.js
- test/billing-summary.test.js
- test/account.test.js

## Depends on
- none

## Interfaces
- produces: `BillingSummary`, `getSummary(userId)`, `setSummary(summary)` for impl-02 (frozen in plan.md)

## Ambiguities (must be empty to proceed)

## Tasks
### W001 [R-02, D-01] BillingSummary type — src/billing/summary.js
### W002 [R-02, D-01] In-memory summary store — src/billing/summary.js
### W003 [T-02] Summary store tests — test/billing-summary.test.js
### W004 [R-03, T-03] Account route returns billing summary — src/routes/account.js, test/account.test.js
1. Failing test: GET /account for tok_ana includes `billing: { status: 'none', last4: null }`. Expected: `✖ account includes billing summary`
2. Implement: import getSummary, add `billing` field to the response. Expected: `✔ account includes billing summary`
3. Document: README `GET /account` line mentions the billing field.

## Verification
```bash
npm test
```

## Review log
- Cycle 1 of 3 (2026-10-20, fresh-context): no CRITICAL/HIGH.

## Progress log
2026-10-20 15:02 START impl-01 by implementer-01 (model tier: standard)
2026-10-20 15:10 W001 complete (files: src/billing/summary.js; tests: n/a)
2026-10-20 15:14 W002 complete (files: src/billing/summary.js; tests: n/a)
2026-10-20 15:25 W003 complete (files: test/billing-summary.test.js; tests: npm test → 3 passed)
2026-10-20 15:30 W004 started: writing failing test in test/account.test.js
