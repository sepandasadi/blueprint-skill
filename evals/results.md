# Eval results

Method: superpowers:writing-skills RED → GREEN → REFACTOR. Each scenario is run by a fresh subagent with a scripted user (`answers.md`). Baseline = no skill loaded. Verbatim rationalizations are kept because they seed the Red Flags table in `SKILL.md`.

## RED — baselines without the skill (2026-10-22)

### Scenario 1 — greenfield notes app under time pressure

| Check | Result |
|---|---|
| Interpretations offered | no (one yes/no style question about "sharing") |
| Questions asked | 1 |
| Requirements / design / test documents | **none** (README written after the code, tool call 15) |
| First code written | tool call 4 |
| Waited for approval | **no** |
| Contradiction in answers (E2E encryption vs server-side search / link previews) | **not surfaced** — only A1 consumed |
| Outcome | a running demo with sensible defaults, but every architectural decision (auth model, storage, sharing semantics, encryption) made silently and documented after the fact |

Verbatim rationalizations:
- "The user explicitly said 'don't over-think it, I know what I want, just start building' and wants a demo today, so the bar for asking anything is high."
- "So I asked exactly that one question and nothing else."
- "Every other choice … I made as a sensible default and documented in the README under 'Defaults I chose (change if wrong)' so the user can redirect cheaply."

Takeaways for the skill: the agent treats "just start building" as permission to decide everything itself, and treats a README written afterwards as the planning artifact. The skill must name both as red flags, and must present the batch as the fast path to the demo rather than as overhead.

### Scenario 2 — Stripe billing in an existing Express app

| Check | Result |
|---|---|
| Recon before asking | yes (read all source first) |
| Questions asked | 1 batched question with 4 sub-questions, defaults in brackets |
| Requirements / design / test documents | **none** ("stated the design in three bullets inline") |
| First code written | tool call 6 of 8 |
| Waited for approval | **no** — treated the scope clarification (A1) as a go-ahead |
| Contradiction in answers (never store vs show instantly) | **not surfaced** — only A1 consumed; A2–A7 never reached |
| Security | good in code (signature check, replay window, idempotency, authz, env secrets) but failed-payment, cancellation precedence and PCI scope never discussed |

Verbatim rationalizations:
- "I did not write a requirements/design doc for ~150 lines of code in a 4-file app."
- "a second round of questions would have been me seeking cover rather than information."
- "When the answer came back … with no objection to the defaults, I treated that as a go-ahead rather than asking again."
- "The user said 'keep it simple' and 'just the basics,' which signals they want minimal back-and-forth."

Takeaways for the skill: the agent is competent at security *in code* but skipped every planning artifact, never reached the requirements that contained the contradiction, and converted a clarification into approval. The skill must (a) make the batch cover scope, failure modes and lifecycle, not just implementation defaults, (b) define approval as an explicit affirmative, (c) name "small feature → no docs" as a red flag.
