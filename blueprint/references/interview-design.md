# Interview track 2 — System design

Interview rules (one question per message) are in `interview-requirements.md` and apply here unchanged. Every question cites the R-IDs it affects.

## Contents
- Recon checklist (answer these yourself first)
- Opening: proposed architecture
- Question bank by area
- Simple-mode selection

## Recon checklist — never ask these

Read and record in `design.md › Context and boundaries`:
- language, framework, package manager, runtime version (manifests, lockfiles, `.tool-versions`, Dockerfile)
- existing layering (routes / services / repos; modules; monorepo packages)
- storage in use and migration tooling
- auth mechanism and session model
- how configuration and secrets reach the app (env, vault, files)
- deployment target and CI from `.github/`, `Procfile`, `vercel.json`, `fly.toml`, k8s manifests
- logging / metrics / tracing libraries already present
- coding conventions: lint config, formatter, test layout

## Opening: proposed architecture

Lead the track with a 5–8 line proposal grounded in recon ("Add a `billing` module beside `account`; Stripe is the source of truth; we cache a billing summary row per user, written only by the webhook handler"). Then ask the first question as its own message; the questions test that proposal instead of starting from nothing.

## Question bank by area

### Boundaries and modules
- Which existing modules does this touch, and which must stay untouched? → default: new module; one import added to the composition root.
- Does this need to be independently deployable or just a module? → default: a module.
- Which parts could a second team own? (drives the split in Phase 5) → default: UI, API, integration, data.

### Data model and storage
- New entities, their keys, and ownership? → default: one table per entity with `owner_id`, `created_at`, `updated_at`.
- Source of truth when data also lives in an external system? → default: external system is truth; local copy is a cache rebuilt from events.
- Migrations: expand/contract or big-bang? → default: expand/contract, backward compatible for one release.
- Retention and PII location (which columns are personal data)? → default: PII columns listed explicitly; encrypted at rest by the platform.

### Interfaces and contracts
- Public API surface added or changed (routes, events, CLI)? → default: minimal; versioned under the existing prefix.
- Contract shape for each interface another plan will consume (types, schemas)? → default: written in `design.md › Interfaces` and frozen before implementation.
- Idempotency: which operations can be retried safely, and how is the key chosen? → default: all writes from external callers carry an idempotency key.
- Pagination, filtering, limits? → default: cursor pagination, page size 50, max 200.

### Security
- Trust boundaries: where does untrusted input enter? → default: every HTTP body, header, query, webhook, file upload.
- Authentication and authorization model per interface? → default: reuse existing session auth; authorize by ownership on every read and write.
- Secrets: which ones, where stored, how rotated? → default: env vars from the platform secret store; rotation documented, no secrets in repo.
- Threats to consider explicitly (spoofed webhooks, replay, injection, SSRF, privilege escalation, data exfiltration)? → default: all of the above get a row in the trust-boundary table.

### Scale and performance
- Expected RPS / concurrent users / data growth and the p95 target per endpoint? → default: carry over from R-IDs; else 50 RPS, p95 < 300 ms.
- Hot paths and where N+1 or large payloads could appear? → default: list each endpoint's queries; batch or join.
- Caching: what, where, TTL, invalidation trigger? → default: none unless a target cannot be met without it.
- Background work: queues, retries, dead letters? → default: platform queue with exponential backoff, 5 attempts, DLQ alert.

### Reliability and operations
- Failure behaviour when a dependency is down (per dependency)? → default: fail closed for writes, serve cached reads with a staleness flag.
- Observability: which log lines, metrics, traces, alerts? → default: structured logs with request id; one metric per critical operation; alert on error-rate spike.
- Feature flags and rollback plan? → default: flag per user-visible change; rollback = flag off + reversible migration.
- Configuration per environment? → default: 12-factor env vars with documented defaults.

### Third parties
- Which external services, which SDK versions, and what happens when their API changes? → default: pin SDK major; wrap in one adapter module.
- Cost or quota ceilings? → default: note the free tier and the first paid threshold.

## Simple-mode selection

Contribute 3–5 questions to the combined sequence: boundaries touched, source of truth for external data, auth/authz model, the single biggest performance target, the one dependency-down behaviour. Everything else: recommended default, `[inferred]`.
