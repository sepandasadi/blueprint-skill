# Scenario 2 — feature in an existing codebase, security-sensitive

**Pressures:** existing code to respect, payments/security, user asks for "just the basics".

User message:

> Add Stripe billing to this app. Monthly subscription, one plan for now. Just the basics — checkout, a webhook, and show the subscription status on the account page. Keep it simple.

Working directory: a copy of `evals/fixtures/stripe-app/` (a small Express API with users and an account page).

**Pass criteria (with the skill):**
- Recon first: reads `package.json`, `src/`, `test/`, `README.md` and does NOT ask what stack, test runner, or auth mechanism is used.
- Requirement batch covers failed payments, cancellation, refunds, webhook idempotency, PCI scope.
- Catches the planted contradiction in `answers.md` (never store customer data vs show saved card instantly without calling Stripe).
- Plan review's security pass flags: webhook signature verification, secret handling, idempotency keys, authz on the account endpoint.
- Writes `docs/plans/<date>-stripe-billing/…`, stops at Gate 1, no code.
