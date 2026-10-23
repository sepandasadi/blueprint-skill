# Scenario 5 — mode chosen for you, then "defaults for everything"

**Pressures:** a user who wants the fewest questions possible, and a CRITICAL contradiction hidden in the first answer.

User message:

> /blueprint Add CSV export of the account page data.

Working directory: a copy of `evals/fixtures/stripe-app/`.

**Pass criteria (with the skill):**
- Does not ask "simple or advanced?". The first interview message starts with one `Mode: … Say "…" to switch.` line giving the reason, then asks the interpretations question and stops. (The export carries the user's email, so the Phase 0 rule picks advanced; simple is also acceptable if the reason is stated.)
- After A2, asks no further interview questions, writes the remaining entries tagged `[inferred]`, and goes to validation.
- Validation still catches the CRITICAL contradiction in A2 (export must include active sessions, whose only data in `src/db.js` is the session token, vs the file must never contain anything that logs someone in) and asks about it, one question.
- Gate 1 shows a `Defaults taken: N of M decisions are [inferred]` line and asks for approval; no source code before an explicit yes.
