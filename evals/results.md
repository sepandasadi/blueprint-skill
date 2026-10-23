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
| Gemini CLI | yes — `gemini skills list` shows `blueprint [Enabled]` from `~/.agents/skills` | not run | "Invalid auth method selected" even with `GEMINI_DEFAULT_AUTH_TYPE=gemini-api-key`; settings.json has no auth section |
| OpenAI Codex (0.154, `gpt-5.5` via company gateway) | yes — read `~/.agents/skills/blueprint/SKILL.md` | **yes** — loaded `blueprint` unprompted, read `harness-map.md` to detect the harness, noted the empty repo, stopped at "Simple or advanced?" recommending advanced with a reason; no files written | needed `-m gpt-5.5 -c web_search=disabled` because the gateway rejects the default model stream and the web-search tool field |
| Cursor agent CLI | not verified | not run | `cursor-agent status` and `agent status` both report not logged in (the Cursor app login does not carry over) |
| Antigravity (IDE inside Gemini.app, `agy` engine) | **no in 0.1.0** — installer wrote only `~/.agents/skills`; the engine loads global skills from `{appDataDir}/skills` = `~/.gemini/antigravity/skills` (strings in the `agy` binary; matches where the user's working hyperframes skills live). Fixed in 0.1.1 | manual check by the user | reported by the user: `/blueprint` showed nothing after restart |
| VS Code Copilot | not verified | not run | no headless mode; manual check needed |

## REFACTOR — one question at a time (2026-10-22)

Field report from a real Claude Code run: during the first requirement question the agent printed all 15 questions with recommendations at once. Root cause: the skill itself prescribed "one numbered batch per track" of 8–15 questions (`SKILL.md` Phase 1, `interview-requirements.md` batch rules, the harness map, README and diagrams), so the agent followed the instruction exactly. Fix: the interview is now one question per message (Why it matters + Recommended + short progress tag), the next question is chosen from the bank by what the last answer changed, each reply is recorded before the next question, and `defaults for the rest of this track` replaces `all defaults` as the shortcut. Scenarios 1 and 2 now fail a run that shows more than one question in a message. Not yet re-run with a fresh agent.

## Installer 0.2.0 — versions and updates (2026-10-22)

Both installers were run in throwaway home folders against a stub npm registry, then against the real one.

| Case | Node | Bash |
|---|---|---|
| `--version` | 0.2.0 | 0.2.0 |
| install writes `.blueprint-version` into every copy | yes | yes |
| install, newer version on npm | one-line notice with the update command | same |
| `doctor`, newer version on npm | every copy marked outdated, update command printed | same |
| `doctor`, npm equal to installer | copies shown current, no command | same |
| `update`, empty manifest | "Nothing was installed … yet" | same |
| `update --dry-run`, one copy at 0.1.1, one without a version file | lists both as stale, the current copy as current | same |
| `update` with no terminal and no `--yes` | refuses, exit 2 | same |
| `update --yes` while npm has a newer version | notes that `@latest` is newer, updates to its own version, backs up first | same |
| `update` again | "Already up to date." | same |
| registry refuses the connection | silent, no delay | same |
| registry accepts but never answers | gives up after 2.1 s | gives up after 2.6 s |
| `BLUEPRINT_SKILL_NO_UPDATE_CHECK=1` | no network call | same |
| real npm registry (0.1.1 published) | read 0.1.1; hint uses this build, not `@latest`, because `@latest` would go backwards | same |
| real machine, copies installed by 0.1.x | 9 copies "unknown version → 0.2.0", doctor clean afterwards | — |

## Behaviour runs after the one-question fix (2026-10-22)

Run in Claude Code through fresh subagents, one user message per turn, scripted answers from `answers.md`, with the installed copy at `~/.claude/skills/blueprint`. Codex, the Cursor agent CLI and Gemini CLI were installed but not signed in on this machine, so they could not be run; Antigravity and VS Code Copilot have no headless CLI here.

| Check | Scenario 1 (notes, advanced) | Scenario 2 (Stripe, simple) | Scenario 3 (resume) |
|---|---|---|---|
| Messages with more than one question | **0 of 16** | **0 of 14** | — |
| Every question had Why it matters + Recommended + progress tag | yes | yes | — |
| Mode and interpretation asked alone, first | yes | yes, after recon | — |
| Planted contradiction | caught on the turn it appeared, both answers quoted, no default | caught on the turn it appeared, both answers quoted, no default | — |
| Other conflicts raised as single questions | 2 more (new-device key, invite to a new user) | 2 more ("lock" vs display-only, never-store vs webhook status) | — |
| `defaults for the rest of this track` | honoured three times; skipped questions listed and tagged `[inferred]` | not used | — |
| Design opener / testing opener | 7-line architecture, coverage proposal | architecture sketch | — |
| Review | 4 full rounds + 2 targeted checks; stopped at the 3-cycle cap and asked; 9 `Checked:` lines | combined pass, 4 HIGH fixed, `Checked:` lines present | — |
| Stopped at Gate 1 with one question, no source files | yes (4 plan files, 1,024 lines) | yes (4 plan files, 510 lines) | — |
| Resume | — | — | `RESUME` + 3 `DRIFT` lines, `src/db.js` untouched, impl-02 untouched, no re-interview |

Deviations, none caused by the one-question change:
- Scenario 2 asked 1 testing question; simple mode asks for 2–3.
- Scenario 1 asked 3 requirement follow-ups against a cap of 2; all three were conflicts it treated as CRITICAL, which the rules allow.
- The resume fixture's `npm test` (`node --test test/`) fails on Node 22 before any test runs; the agent recorded `complete (unverified: …)` as the skill says.

Not covered: Codex, Cursor, Gemini CLI (not signed in on this machine), Antigravity and VS Code Copilot (no headless CLI), and Claude Code's `AskUserQuestion` rendering (subagents asked in chat).

## 0.3.0 — shortcuts (2026-10-23)

New behaviour: the mode is chosen and announced instead of asked; `/blueprint from <brief>`; `defaults for everything`; read-only `/blueprint status`; resume picks the folder or asks; `npx blueprint-skill init` writes a starter constitution.

Run in Claude Code through fresh subagents, one user message per turn, scripted answers from `answers.md`, reading the skill from this checkout (not the installed 0.2.0 copy), subagents not allowed (stance-switch reviews). Each scenario ran in its own scratch copy of the fixture, committed to git first so changes could be diffed. Baselines without the skill were not re-run for these scenarios.

| Check | Scenario 4 (brief, Stripe) | Scenario 5 (CSV export, defaults for everything) | Scenario 6 (status) |
|---|---|---|---|
| Mode | not asked; `Mode: advanced` line with reason (money, authorization) | not asked; `Mode: advanced` line with reason (export carries email) | — |
| Messages with more than one question | 0 of 24 | 0 of 3 | — |
| Brief read before the first question | yes; one line: "From the brief: 6 requirements, 2 design decisions, 0 test items and 4 non-goals" | — | — |
| Brief entries cited | `## Source brief`, `Grounds: brief, line N`, `Brief → R-01 … R-06; D-01, D-02; Non-goals ×4` in Clarifications | — | — |
| Questions the brief already answered | none asked | — | — |
| Interview questions | 8 requirements (incl. the interpretation confirmation), 8 design, 5 testing = 21; scenario 1 from scratch asked about 40 | 2 (interpretation, then the answer that said `defaults for everything`) | — |
| "Skip the planning" line in the brief | named once as input, not followed; recorded under Source brief | — | — |
| Wrong codebase claim (Postgres) | corrected from recon in the first message; storage asked as one question about intent | — | — |
| Planted contradiction | caught as CRITICAL, both brief lines quoted, resolved; the losing line retired with a reason | caught as CRITICAL after `defaults for everything`, both answers quoted, resolved | — |
| HIGH validation questions | 2 asked (advanced) | none open | — |
| Gate 1 | `Self-check: passed`, Rulings, `Defaults taken: 41 of 48 decisions are [inferred]`, one question | `Self-check: passed`, Rulings, `Defaults taken: 17 of 22 decisions are [inferred]`, one question | — |
| Files written | 4 plan files (704 lines), no source | 4 plan files (385 lines), no source | none; `git status` and every file checksum identical before and after |
| Status report | — | — | 6 lines: folder, `advanced · implementing`, W004 next, impl-02 waiting, open counts, `Next: say "continue"`, and that nothing was re-verified |

Findings and changes:
- **Gate dates were missing from status.** Scenario 6 reported "Gates: 1 and 2 passed (no approval dates in plan.md)": nothing in the skill recorded a gate approval, and `plan.md` status was only ever set to `validated`. Fix: on each affirmative, append `Gate N approved <date>: "<the user's words>"` to the Review log and set status to `approved` (Gate 1) / `implementing` (Gate 2); set `converged` after convergence; status says `date not recorded` for older plans. Re-run (6b, same fixture with gate lines added): `Gates: 1 approved 2026-10-20 · 2 approved 2026-10-20 (current branch)`, files unchanged. Not yet observed: an agent writing the gate line itself, since scenarios 4 and 5 stopped at Gate 1 with the old text loaded.
- **Two pass criteria were miscalibrated, not the skill.** Scenario 5 expected `Mode: simple`; the Phase 0 rule sends anything touching personal data to advanced, and the agent applied it with the reason stated. Scenario 4 expected "fewer questions than scenario 2", but scenario 2 ran in simple mode and this run was advanced. Both criteria were rewritten (mode line with a reason; no question the brief answers and fewer than an advanced run from scratch).
- Scenario 4 re-found that the fixture's `npm test` (`node --test test/`) fails on Node 22 and planned a fix as a Ruling rather than assuming tests pass.

Installer: `init` checked in both `bin/blueprint-skill.js` and `install.sh` — dry run writes nothing, `--mode` is written into the file, an invalid mode exits 2, an existing constitution is left untouched, and both installers produce the same file apart from the mode line.

Not covered: the same harnesses as the previous run (Codex, Cursor, Gemini CLI, Antigravity, VS Code Copilot); resume's folder picker with several unfinished folders; `defaults for everything` in simple mode.
