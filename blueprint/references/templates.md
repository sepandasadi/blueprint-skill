# Artifact templates

All artifacts live in `docs/plans/<YYYY-MM-DD>-<feature-slug>/` inside the target project. Copy a template verbatim, then fill every `<placeholder>`. Never leave a placeholder in a file you show the user (the pre-gate self-check in `validation.md` fails on any `<…>` left behind).

## Contents
- ID scheme
- `requirements.md`
- `design.md`
- `testing.md`
- `plan.md`
- `impl-NN.md`
- Progress Log ledger format
- `CONSTITUTION.md` (optional, project-level)

## ID scheme

| Prefix | Meaning | Lives in | Example |
|---|---|---|---|
| `R-NN` | requirement | `requirements.md` | `R-04 Share a note by public link` |
| `D-NN` | design decision | `design.md` | `D-02 Postgres with row-level ownership` |
| `T-NN` | test item | `testing.md` | `T-07 Replayed webhook is ignored` |
| `W###` | work task | `plan.md`, `impl-NN.md` | `W012 [P] [R-04] Add share-link route — src/routes/share.js` |

Every `D` and `T` cites the `R` it serves. Every `W` cites at least one `R`, `D` or `T`. IDs are never renumbered; new items get the next free number and are appended at the end of their section; retired items are struck through with a reason.

## Decision entry (used in all three track files)

```markdown
### R-03 Notes are end-to-end encrypted
- **Decision:** Note bodies are encrypted on the client; the server stores ciphertext only.
- **Grounds:** User answer, Session 2026-10-22 Q4.
- **Reopen if:** server-side search or rich link previews become a hard requirement.
- **Tags:** confirmed            <!-- or: [inferred] when the agent chose the recommended default -->
```

## `requirements.md`

```markdown
# Requirements — <feature name>

Mode: <simple | advanced> · Created: <YYYY-MM-DD> · Status: <draft | validated>

## Interpretation chosen
<One paragraph: the reading of the request the user picked, in the user's words where possible.>

## Actors
- <actor> — <what they need>

## Requirements
### R-01 <short title>
- **Decision:** …
- **Grounds:** …
- **Reopen if:** …
- **Tags:** <confirmed | [inferred]>

## Non-goals
- <explicitly out of scope, with the reason>

## Success metrics
- <measurable outcome, with the number and how it is measured>

## Assumptions
- <questions trimmed from the batch and the default taken, each tagged [inferred]>

## Clarifications
### Session <YYYY-MM-DD>
- Q: <question as asked> → A: <answer as given>
```

## `design.md`

```markdown
# System design — <feature name>

Mode: <simple | advanced> · Created: <YYYY-MM-DD> · Status: <draft | validated>

## Context and boundaries
<What exists today (from recon), what this feature touches, what it must not touch.>

## Design decisions
### D-01 <short title>  (serves: R-01, R-04)
- **Decision:** …
- **Grounds:** …
- **Reopen if:** …
- **Tags:** <confirmed | [inferred]>

## Data model
<entities, fields, ownership, retention; reference D-IDs>

## Interfaces and contracts
| Interface | Producer | Consumer | Shape | Serves |
|---|---|---|---|---|
| <name> | <module> | <module> | <signature / schema> | R-xx |

## Trust boundaries
| Boundary | Crosses | Controls (authn, authz, validation, secrets) |
|---|---|---|

## Scale and performance targets
| Target | Value | Source |
|---|---|---|
| <p95 latency, users, data volume…> | <number> | R-xx / [inferred] |

## Operations
<deployment, configuration, observability, failure handling>

## Assumptions
## Clarifications
### Session <YYYY-MM-DD>
```

## `testing.md`

```markdown
# Test strategy — <feature name>

Mode: <simple | advanced> · Created: <YYYY-MM-DD> · Status: <draft | validated>

## Approach
<Test pyramid for this feature; runner and tooling from recon; what runs in CI.>

## Test items
### T-01 <short title>  (covers: R-01)
- **Decision:** <what is asserted, at which level: unit / integration / e2e>
- **Grounds:** …
- **Reopen if:** …
- **Tags:** <confirmed | [inferred]>

## Acceptance criteria format
<Given / When / Then, or the project's existing convention>

## Fixtures and test data
## Non-functional tests
<performance, security (forged / replayed inputs, authz), resilience>

## Assumptions
## Clarifications
### Session <YYYY-MM-DD>
```

## `plan.md`

```markdown
# Plan — <feature name>

mode: <simple | advanced>
quiz: <off | on>
status: <draft | validated | reviewed | approved | implementing | converged>
created: <YYYY-MM-DD>
constitution: <none | docs/plans/CONSTITUTION.md>

## Goal
<Two sentences: what ships and how the user will know.>

## Architecture
<Short prose + the component list; cite D-IDs.>

## Tech stack
<From recon; new additions flagged with the D-ID that justifies them.>

## Global constraints
- <rule every task obeys: coding standards, no new deps without D-ID, commit policy…>

## Review focus
<The 5 failure modes most likely to bite users that tests may not catch.>
1. …

## Ambiguities (must be empty to proceed)
- <anything a builder could read two ways>

## Constitution check            <!-- only when a constitution exists -->
| Principle | Status (pass / violation) | Note |
|---|---|---|

### Complexity tracking
| Violation | Why needed | Simpler alternative rejected because |
|---|---|---|

## Traceability matrix
| Requirement | Design | Tests | Tasks |
|---|---|---|---|
| R-01 | D-01, D-03 | T-01, T-02 | W001, W004 |

## Pre-flight conflict table           <!-- filled in Phase 5 -->
| Shared file or interface | Plans involved | Frozen contract |
|---|---|---|

## Tasks
### Parallel group: <name>
- [ ] W001 [P] [R-01, D-01] <description> — <path/to/file>
### Sequential chain: <name> (depends on: W001)
- [ ] W002 [R-02] <description> — <path/to/file>
### Independent
- [ ] W003 [P] [T-05] <description> — <path/to/file>

Interfaces per task where they matter:
- W001 — consumes: <interface>; produces: <interface>

## Critical path
W001 → W002 → W007 (<estimate in tasks, not hours>)

## Threat model (STRIDE-lite)          <!-- filled in Phase 4; one row per trust boundary in design.md -->
| Boundary | Spoofing | Tampering | Repudiation | Info disclosure | Denial of service | Elevation of privilege |
|---|---|---|---|---|---|---|

## Review log
- Validation cycle 1 of 3 (<YYYY-MM-DD>): <findings> → <fixes>
- Cycle 1 of 3 (<YYYY-MM-DD>, <reviewer: fresh-context | stance-switch>): <findings> → <fixes>

## Rulings
- Ruling: <decision> — <why> — <cost if wrong>

## Convergence                          <!-- appended after implementation; append-only -->
### Pass 1 of 3 (<YYYY-MM-DD>)
| Requirement | Verdict (satisfied / missing / partial / contradicts) | Evidence |
|---|---|---|
Unrequested changes: <list or none>
```

Task line grammar: `W### [P]? [IDs] description — path`. `[P]` is allowed only when the task touches no file that another unfinished task touches and depends on no unfinished task.

## `impl-NN.md`

```markdown
# Implementation plan NN of <total> — <scope title>

plan: plan.md
status: <not started | in progress | done | done with concerns | blocked>
owner: <unassigned | implementer-NN>

## Scope
<What this plan delivers; which R-IDs it closes.>

## Owns (files and globs — exclusive to this plan)
- src/billing/**
- test/billing.test.js

## Depends on
- impl-01 W004 (the `BillingSummary` type) — <or: none>

## Interfaces
- consumes: <name> from impl-01 (frozen in plan.md pre-flight table)
- produces: <name> for impl-03

## Ambiguities (must be empty to proceed)
- <none>

## Tasks
### W012 [R-04, T-07] <description> — <path>
1. Write the failing test: <file> asserting <behaviour>. Expected: `<runner output showing the failure>`
2. Implement: <what, where>. Expected: `<runner output showing the pass>`
3. Document: <doc file or docstring>.

## Verification
```bash
<exact commands that must pass before this plan is reported done>
```

## Review log
- Cycle 1 of 3 (<date>, <reviewer>): <findings> → <fixes>

## Progress log
<ledger lines, newest last — see format below>
```

## Progress Log ledger format

One line per event, newest last, never edited after the fact (append a correction instead):

```
2026-10-22 14:02 START impl-02 by implementer-02 (model tier: standard)
2026-10-22 14:10 Ruling: use HMAC from node:crypto, no new dep — why: already available — cost if wrong: swap one import
2026-10-22 14:31 W012 complete (files: src/billing/webhook.js, test/billing.test.js; tests: npm test → 14 passed)
2026-10-22 14:35 W013 BLOCKED: needs BillingSummary type from impl-01 W004 (not yet complete)
2026-10-22 15:02 DRIFT: test/account.test.js changed on disk but no ledger entry — re-verified, still passing
2026-10-22 15:40 DONE_WITH_CONCERNS: W015 retry logic untested under network partition (see T-09)
```

Status words:

| Word | Use it when |
|---|---|
| `START` | an implementer begins a plan for the first time |
| `RESUME` | work continues after a context loss or a new session; name the task resumed at |
| `complete` | a task's steps are done **and** its Expected output was observed |
| `complete (unverified: <reason>)` | the code is written but the test runner could not run (missing deps, no network); say what was checked instead |
| `BLOCKED` | a dependency or decision outside this plan is missing |
| `NEEDS_CONTEXT` | the plan text is insufficient to proceed; state the question |
| `DRIFT` | disk or git state disagrees with the ledger (see Resume) |
| `DONE` | every task `complete` and the Verification block passed |
| `DONE_WITH_CONCERNS` | every task done, but something is unverified or a risk remains; list it |

A plan is reportable and committable only after a `DONE` line, or a `DONE_WITH_CONCERNS` line whose concerns do **not** include an unverified Verification block. Any `complete (unverified: …)` task keeps the plan out of the commit step until its Verification block passes.

## `CONSTITUTION.md` (optional; lives at `docs/plans/CONSTITUTION.md`)

```markdown
# Project constitution

version: 1.0.0 · ratified: <YYYY-MM-DD> · last amended: <YYYY-MM-DD>

## Principles
1. **MUST** <non-negotiable rule, testable>
2. **SHOULD** <strong default; violation needs a Complexity Tracking row>

## Defaults
quiz: <off | on>
mode: <simple | advanced | ask>
```
