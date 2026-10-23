# Review checklists

Used in Phase 4 (plan review), Phase 6 (implementation-plan review) and the convergence pass. The reviewer reads the artifacts as a sceptic who will be blamed for every bug.

## Contents
- Reviewer setup (fresh context vs stance switch)
- Bugs pass
- Performance pass
- Security pass (STRIDE-lite)
- Builder check (advanced, Phase 4)
- Phase 6 additions: DRY, docs, no-refactor, coverage verdicts
- Finding format and the fix loop
- Convergence pass

## Reviewer setup

- **Fresh context (preferred, advanced mode):** dispatch a reviewer subagent (see `harness-map.md`) with: the artifact paths, this file's path, the pass names to run, and "report findings only; do not edit". It must not see the conversation that produced the plan.
- **Stance switch (fallback, and simple mode):** announce "Switching stance to reviewer." Re-read every artifact from disk (any file-reading tool or shell command; never from memory), run the passes, and end the review with a `What was checked:` line listing files and passes. Write the same line as the `Checked:` field of the Review log entry (template in `templates.md`). A review without it is not a review.
- Advanced mode runs the three passes separately (one findings list each). Simple mode runs one combined pass using all three checklists.

## Bugs pass

For each task and design decision ask:
- Boundary values: empty, zero, one, max, unicode, very long, negative, null.
- State: what if the operation runs twice? out of order? after a partial failure? concurrently from two devices?
- Error paths: every external call has a defined failure behaviour and the user sees something truthful.
- Time: timezones, DST, clock skew between services, expiry checks.
- Identity: can a stale id, deleted owner, or renamed resource reach this code?
- Types and contracts: does every interface in the pre-flight table have one definition, and does every consumer match it?
- Plan logic: does any task depend on a task scheduled after it? does any `[P]` task share a file with another unfinished task?

## Performance pass

- Hot path identified for every endpoint or job; its query count and payload size estimated.
- N+1: any loop that calls storage or a network service.
- Unbounded work: lists without pagination, fan-out without limits, retries without backoff, caches without eviction.
- Targets from `design.md › Scale and performance targets` are each met by a specific decision, or the plan says which test proves it.
- Startup and build cost: new dependencies, bundle size, cold-start impact where relevant.
- Background jobs: idempotent, bounded, observable.

## Security pass (STRIDE-lite)

For every row in `design.md › Trust boundaries`, fill this table in `plan.md › Threat model (STRIDE-lite)`:

| Boundary | Spoofing | Tampering | Repudiation | Info disclosure | Denial of service | Elevation of privilege |
|---|---|---|---|---|---|---|

Each cell: the control (authn, signature check, validation, logging, rate limit, authz check) or "n/a — because …". Also check:
- Webhooks and callbacks: signature verified with the provider's library, replay window enforced, idempotency key stored.
- Authorization on every read and write, by ownership, not by "is logged in".
- Input validation at the boundary with an allow-list schema; output encoding where content is rendered.
- Secrets: never in code, logs, URLs, or test fixtures; rotation path named.
- Dependencies: new packages justified by a D-ID; lockfile committed; known-vulnerable versions avoided.
- Data: PII columns listed; deletion path exists; nothing sensitive in error messages.
- Injection: SQL/NoSQL/command/template/path; SSRF on any user-supplied URL.

## Builder check (advanced mode, Phase 4)

A second fresh-context subagent (or a second stance switch) reads only `plan.md` and the track files as a builder who cannot ask questions and lists every question whose answer would change what gets built. Sort them:
- **Answered already** by the artifacts → add the pointer to the plan.
- **Minor** → decide it, record as `Ruling:` in `plan.md`.
- **The user's** → asked one at a time before Gate 1.

## Phase 6 additions (implementation plans)

- **DRY across plans:** the same helper, type, migration or test fixture planned in two plans → move it to the plan that runs first; the other consumes it through the pre-flight table.
- **Docs:** every new public surface (route, CLI flag, env var, event, exported function) has a task that documents it where the project documents such things.
- **No refactor needed:** would the finished result need restructuring immediately (god module, duplicated state, leaky abstraction)? If yes, fix the plan now.
- **Coverage verdicts:** for every R-ID, mark `Satisfied / Partial / Gap / Conflict` across the union of impl plans. `Partial` counts as `Gap`. Any Gap or Conflict blocks Gate 2.
- **Ownership:** every path that any task names (source, tests, docs, config) appears in exactly one plan's `Owns`; shared interfaces are frozen; dependency edges form no cycle. A path named by a task but owned by no plan is a HIGH finding.

## Finding format and the fix loop

```
[HIGH] bugs W012: webhook handler stores event before verifying signature → forged events persist.
   Fix: verify first; add T-11 forged-event test.
```

Fix every CRITICAL/HIGH in the artifact, re-run only the pass that produced it, and log that re-run as its own `Review cycle N of 3` entry, even when it finds nothing. MEDIUM/LOW are fixed when cheap, otherwise recorded as a `Ruling:` with the cost if wrong. After 3 cycles with CRITICAL/HIGH remaining, stop and ask the user.

## Convergence pass (after implementation)

Checkbox state and ledger lines are claims, not evidence. For each R-ID, open the code and tests and record `satisfied / missing / partial / contradicts` with the file evidence. List every change not traceable to a W-task as `unrequested`. Append the table to `plan.md › Convergence`; never edit earlier passes. Loop fixes through the owning plan's implementer (or yourself) at most 3 times, then report what remains.
