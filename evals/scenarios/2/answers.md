# Scripted user answers — Scenario 2

Read these in order. Each time the agent asks the user something, the next unused answer below is the user's reply. If the agent asks something not covered, the reply is: "Use your recommended default."

## A0 — mode (if asked)
"simple"

## A1 — interpretation
"The one where existing users upgrade to a paid plan; no new signup flow."

## A2 — requirements batch
"All defaults except:
- We must never store any card or customer billing data on our side. Stripe holds everything.
- The account page must show the saved card's last 4 digits and the last 12 invoices instantly on page load, without any call to Stripe at request time — it has to work even if Stripe is down.
- Cancel anytime, access until end of period.
- Failed payments: email the user and lock the account after 7 days."

## A3 — follow-up (if asked about the conflict)
"OK — we can cache a non-sensitive billing summary (last4, invoice list) in our DB, synced from webhooks. Never the full card."

## A4 — design batch
"All defaults. Keep the existing Express + node:test setup."

## A5 — testing batch
"All defaults. Webhook handling must have tests for replayed and forged events."

## A6 — Gate 1
"Approved."

## A7 — Gate 2
"Approved."
