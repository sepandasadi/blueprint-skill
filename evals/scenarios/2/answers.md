# Scripted user answers — Scenario 2

Read these in order. Each time the agent asks the user something, the next unused answer below is the user's reply. The agent must ask ONE question per message. For A2, A4 and A5, answer each question individually: if it concerns a topic named in the bullets, give that bullet; otherwise reply "Use your recommended default." If the agent shows more than one question in a message, record that as a failure. If the agent asks something not covered, the reply is: "Use your recommended default."

## A0 — mode (if asked)
"simple"

## A1 — interpretation
"The one where existing users upgrade to a paid plan; no new signup flow."

## A2 — requirements track
"Defaults, except where these apply:
- We must never store any card or customer billing data on our side. Stripe holds everything.
- The account page must show the saved card's last 4 digits and the last 12 invoices instantly on page load, without any call to Stripe at request time — it has to work even if Stripe is down.
- Cancel anytime, access until end of period.
- Failed payments: email the user and lock the account after 7 days."

## A3 — follow-up (if asked about the conflict)
"OK — we can cache a non-sensitive billing summary (last4, invoice list) in our DB, synced from webhooks. Never the full card."

## A4 — design track
"Use your recommended default for every question. Keep the existing Express + node:test setup."

## A5 — testing track
"Use your recommended default for every question. Webhook handling must have tests for replayed and forged events."

## A6 — Gate 1
"Approved."

## A7 — Gate 2
"Approved."
