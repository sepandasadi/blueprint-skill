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

## GREEN — with the skill (2026-10-22)

Runs used the installed copy at `~/.claude/skills/blueprint`, no subagents allowed (to exercise the stance-switch fallback), scripted users as above.

### Scenario 1 — notes app, advanced mode

| Check | Baseline | With blueprint |
|---|---|---|
| Interpretations offered | no | 3 (A/B/C) |
| Questions | 1 | requirements 14, design 14 (opened with a 7-line architecture proposal), testing 12 (opened with a coverage table); 2 follow-up rounds; 2 validation questions |
| Planted contradiction (E2E encryption vs server-side search vs link previews) | not surfaced | caught right after the requirements batch, all three answers quoted, resolved by the user |
| Time pressure ("demo by end of day") | used to justify asking nothing | answered with one line that the batch is the fast path; a build-order follow-up decided what may be stubbed |
| Artifacts | README written after code | requirements.md 132, design.md 183, testing.md 164, plan.md 145 lines; 15 R, 16 D, 21 T, 28 W |
| Review | — | stance switch, Bugs / Performance / Security separately, 17 findings fixed, cycle 2 clean, builder check: 11 minor rulings, 0 for the user |
| Stopped at Gate 1, no code | no (code at call 4) | yes, 24 tool calls, zero source files |
| **Miss** | — | no literal `What was checked:` line; the review content was in the log but the required line was omitted |

### Scenario 2 — Stripe billing, simple mode

| Check | Baseline | With blueprint |
|---|---|---|
| Recon before asking | yes | yes — stack, auth, storage, test runner, CI all stated, none asked |
| Mode | — | asked; recommended advanced (money), user chose simple, recorded as a Ruling |
| Interpretations offered | no | 3 (A/B/C) |
| Questions | 1 batched question | 14 in one combined batch (7 requirements / 4 design / 3 testing), each with Why + Recommended; 3 follow-ups |
| Planted contradiction (never store vs show instantly offline) | not surfaced | caught as CRITICAL, both answers shown verbatim, resolved by the user |
| Scope creep ("just the basics" vs extras) | not discussed | flagged, mitigations recommended, listed at Gate 1 |
| Artifacts | none | requirements.md 94, design.md 141, testing.md 90, plan.md 118 lines |
| Review | — | stance switch, combined pass: 4 HIGH, 6 MEDIUM, 1 LOW fixed; STRIDE-lite per trust boundary; `What was checked:` line present |
| Stopped at Gate 1, no code | no (code at call 6) | yes, 18 tool calls, zero source files |

### Scenario 3 — resume a half-finished run

| Check | Result |
|---|---|
| Re-interviewed or rewrote the plan | no |
| Facts re-verified | `git status`, `git log`, `git diff`, partial test run (dependencies absent) |
| Planted drift (`src/db.js`) | recorded as `DRIFT`, left untouched (owned by no plan) |
| Stale ledger claim (W004 "writing failing test", nothing on disk) | detected, task step restarted |
| Resumed at | impl-01 W004 |
| impl-02 files touched | none |

## REFACTOR — what the GREEN runs changed

Scenario 3 exposed: no ledger word for resuming or for "runner could not run"; no rule for drift in files no plan owns; README edited by a task but owned by no plan. Fixed: `RESUME` and `complete (unverified: …)` ledger words; drift resolution by ownership; every path a task names must be owned (HIGH finding otherwise).

Scenario 2 exposed: interpretation pick ambiguous between separate question and batch item; follow-up cap vs mandatory CRITICAL questions; unanswered CRITICAL follow-ups; no home for validation findings or the STRIDE table; `validated` missing from plan statuses; non-goals forced into R-IDs; task-tracking fallback on Claude Code. Fixed: interpretation is always its own question; CRITICAL questions bypass the cap and are never defaulted; `Validation cycle N of 3` in the Review log; `plan.md › Threat model (STRIDE-lite)`; `validated` status; non-goals carry no IDs; tracking falls back to plan.md checkboxes; mode override recorded as a Ruling and repeated once at Gate 1.

Scenario 1 exposed: the `What was checked:` line was skipped even though SKILL.md said a review without it "did not happen" — an omission, not a rationalization, so the fix is structural: every Review log entry in the template now has required `Checked / Findings / Fixes / Remaining` fields and the pre-gate self-check fails on an entry without `Checked:`. Also fixed: time-pressure wording (keep the recommendation, never shrink the batch); re-runs that find nothing are their own cycle; code literals are not placeholders; user-stated numbers beat recommended ones; Claude Code detection keys on `Agent` alone; validation questions are charged to the track they mostly touch.

## Installer and cross-agent checks (2026-10-22, after publishing 0.1.0)

### Installer

Both installers were driven through their interactive menus with `expect` in a throwaway home folder.

| Case | Node (`npx blueprint-skill`) | Bash (`install.sh`) |
|---|---|---|
| `a` all detected → confirm | installs `~/.claude` + `~/.agents` | **failed**, then fixed: exited silently when the last listed agent was not installed (`set -e` + loop ending in `detected && …`) |
| pick numbers + `--native` → decline | correct plan, "Aborted." | correct plan, "Aborted." |
| `q` / invalid input | "Nothing selected." | "Nothing selected." |
| `e` everything | adds Antigravity CLI folder | same plan |
| reinstall over existing | backs up to `~/.blueprint-skill/backups/` | same |
| target is a symlink | skipped with instructions | skipped |
| uninstall | removes exactly the manifest paths | same |
| no terminal, no flags | exits with a message | exits with a message |
| same flags, both installers | identical target lists | identical target lists |

Also verified from the npm registry: `npx blueprint-skill@0.1.0` help, dry run, `--project` install and uninstall.

### Discovery and auto-trigger per agent

| Agent | Finds the skill | Picks it unprompted and follows it | Note |
|---|---|---|---|
| Claude Code (CLI) | yes — listed in the session's skill listing from `~/.claude/skills` | not run to completion | API connection refused on this machine |
| Claude Code (agent in desktop app) | yes | **yes** — given only "help me build a habit tracker", it loaded `blueprint`, inspected the empty repo, and stopped at the mode question recommending advanced with reasons; no files written | |
| Gemini CLI | yes — `gemini skills list` shows `blueprint [Enabled]` from `~/.agents/skills` | not run | CLI not signed in |
| OpenAI Codex | not verified | not run | company gateway unreachable ("waiting for network") |
| Cursor agent CLI | not verified | not run | CLI not signed in |
| VS Code Copilot, Antigravity | not verified | not run | no headless mode; manual check needed |
