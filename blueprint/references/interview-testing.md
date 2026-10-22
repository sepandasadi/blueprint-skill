# Interview track 3 — Testing

Batch rules are in `interview-requirements.md` and apply here unchanged. Every question cites the R- and D-IDs it covers; the batch ends only when every R-ID has at least one planned T-ID.

## Contents
- Recon checklist
- Opening: coverage proposal
- Question bank by area
- Simple-mode selection

## Recon checklist — never ask these

- test runner, assertion library, mocking style, fixtures already present
- how tests run in CI, how long they take, what is flaky
- existing coverage tooling and thresholds
- e2e tooling (Playwright, Cypress, Detox) if any
- test data strategy (factories, seeds, snapshots)

## Opening: coverage proposal

Show a draft table `R-ID → proposed test level (unit / integration / e2e)` from the requirements, then ask the batch to confirm or move items. In advanced mode also show the gaps the user must accept explicitly.

## Question bank by area

### Levels and pyramid
- Which flows need end-to-end tests, and which are fine at integration level? → default: e2e for the primary journey and anything involving money or sharing; integration for every API route; unit for pure logic.
- Is TDD required for implementers (test first, watch it fail)? → default: yes; each task's first step is a failing test.
- Coverage threshold, if any? → default: no number; every R-ID has a T-ID instead.

### Acceptance criteria
- Format for acceptance criteria (Given/When/Then, checklist, example tables)? → default: Given/When/Then per R-ID.
- Who signs off: automated only, or a manual check by the user before release? → default: automated plus a 5-minute manual script the plan writes out.

### Test data and environments
- Fixtures: factories, seed files, or recorded responses for third parties? → default: factories + recorded/stubbed third-party responses; never live calls in CI.
- Separate test database or in-memory? → default: whatever the repo already does; otherwise ephemeral per run.
- Secrets in tests? → default: fake values only; test fails if a real-looking secret is detected.

### Non-functional tests
- Performance: which endpoint gets a load test and at what threshold? → default: the critical path at 2× expected RPS, p95 from design targets.
- Security tests: forged / replayed inputs, authz bypass attempts, injection probes? → default: one negative test per trust-boundary row in `design.md`.
- Resilience: dependency-down and timeout behaviour tested? → default: one test per "dependency down" decision.
- Migrations tested forward and back? → default: yes when a migration exists.

### Process
- Must tests pass before a plan can be reported done? → default: yes; the impl plan's Verification block is the gate.
- Flaky-test policy? → default: quarantine with an issue, never delete.
- Documentation tests (examples in README run)? → default: only if the project already does this.

## Simple-mode selection

Contribute 2–3 questions to the combined batch: which flows need e2e, whether TDD is required, and the one negative/security test that matters most. Everything else: recommended default, `[inferred]`.
