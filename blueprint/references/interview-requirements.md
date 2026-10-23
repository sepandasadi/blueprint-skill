# Interview track 1 — Requirements

## Contents
- Interview rules (apply to all three tracks)
- Opening: interpretations
- Question bank by area
- Follow-up triggers
- Simple-mode selection

## Interview rules

1. **Recon before asking.** Anything the repository, manifests, docs, git log or environment can answer is never asked. State what you found instead ("I see Express + node:test; I'll keep both").
2. **One question at a time, never a list.** Each message contains exactly one question and ends there; wait for the reply. Do not number the questions in advance, do not preview what comes next, do not ask "anything else?" in the same message. Advanced: 8–15 questions per track. Simple: this track contributes 5–7 questions to the single combined sequence (see Simple-mode selection). Show progress as a few words ("Requirements, 3 of ~12").
3. **Every question message has three lines** (plus the progress tag):
   ```
   Requirements, 4 of ~12
   Q4. Who can see a note shared by public link?
       Why it matters: decides whether link previews can include content and whether links need expiry.
       Recommended: anyone with the link, read-only, no preview content, link revocable by owner.
   ```
4. **Answer forms accepted:** free text, `ok` / `default` / `your call` (take Recommended for this question), or `defaults for the rest of this track` (take Recommended for every remaining question in the track and stop asking). Any value the user did not state in their own words takes the Recommended value and is tagged `[inferred]`. If a reply answers a later question too, record both and skip the later one. When the user gives a number different from your Recommended one, theirs wins; if you still need headroom, record it as a Ruling, not as their requirement.
5. **Order and cap.** Ask in priority order scope > security/privacy > UX > technical, choosing each next question by what the previous answer changed, until the cap or until every area is covered. Questions never asked become `## Assumptions` entries with their Recommended value, tagged `[inferred]`.
6. **Record immediately.** After each reply, write the entries to the track file and append the `Q → A` line to `## Clarifications / ### Session <date>` before asking the next question.
7. **Follow-ups** are extra single questions asked after the track's main questions (max 2 per track in advanced, 1 in simple) and only for answers that are vague, contradictory, untestable, or that opened a new area. Unanswered follow-ups take the Recommended value and are listed at Gate 1 — except CRITICAL ones (see `validation.md › Severity and routing`), which are never defaulted.
8. **Non-goals are not requirements.** Things the user puts out of scope go under `## Non-goals` without an R-ID; only positive, testable statements get R-IDs.

## Opening: interpretations

Before the first requirement question, offer 2–3 readings of the request, one line each, and let the user pick or correct. Example for "notes app with sharing":

```
I read this three ways — which is closest?
A. Personal notes, share individual notes by link or invite.
B. Team workspace where everyone sees shared folders.
C. Public publishing: notes are pages anyone can read.
```

Record the pick under `## Interpretation chosen`.

## Question bank by area

Pick from every area; skip questions the recon answered. Each item lists the question stem and the default to recommend when no better default is visible in the codebase.

### Scope and actors
- Who are the actors (roles, not personas)? Which one is the primary? → default: one primary role, one admin.
- What is the single journey that must work for the demo / first release? → default: the shortest path from sign-in to the core action.
- What is explicitly out of scope for this iteration? → default: billing, admin UI, mobile, i18n unless named.
- If only one of these could ship, which: <the two biggest sub-features from the request>? → default: the one the request named first.

### Data and lifecycle
- What are the core entities and who owns each record? → default: owner = creating user; admin can read.
- What must be kept forever, and what is deleted when the owner deletes it or their account? → default: hard-delete on account deletion within 30 days; soft-delete for user actions with 30-day restore.
- Any data that must never leave a region, device, or the server? → default: none; flag if health, payment, children or biometric data appears.
- Expected volume per user and in total at 12 months? → default: small (≤10k records per user, ≤1M total).

### Permissions and sharing
- Who can see / edit / delete each entity? → default: owner full; shared users per grant; nobody else.
- Can access be revoked, and what happens to copies already made? → default: revocable; existing copies out of scope.
- Public access: is anything reachable without sign-in? → default: nothing.

### Failure modes and edge cases
- What happens when <external service> is down? → default: degrade read-only with a visible banner; queue writes.
- Conflicting edits from two users or devices? → default: last write wins with a conflict notice; no merge.
- What must never happen, even if everything else fails? (anti-goals) → default: data loss; leaking a private record.
- Limits: max size of <entity>, rate limits, quotas? → default: 1 MB per record, 100 req/min per user.

### Non-functional
- Target response time for the core action? → default: p95 < 500 ms server-side.
- Availability expectation and maintenance windows? → default: best effort, no SLA for the first release.
- Accessibility and browser / device support? → default: current evergreen browsers, WCAG AA for core flows.
- Compliance or audit requirements (GDPR, SOC 2, HIPAA, PCI)? → default: GDPR basics (export + delete); nothing else.

### Success and release
- How will you know it worked a month after launch (one metric)? → default: weekly active users of the core action.
- Rollout: everyone at once, or behind a flag? → default: behind a feature flag, default off.
- Must it be demoable at a specific date? What is the minimum for that demo? → default: the single journey above, seeded data.

## Follow-up triggers

Ask a follow-up when an answer:
- uses an unmeasurable word (fast, secure, simple, scalable) → ask for the number or the threat;
- names a capability that collides with another answer (see `validation.md`, pass 6) → show both answers and ask which wins;
- cannot be tested as written → ask what observable outcome counts as done;
- opens an area no question covered → ask the 2–3 bank questions for that area.

## Simple-mode selection

In simple mode the three tracks are merged into one sequence of 10–15 questions, asked one at a time after the interpretation pick (which is always its own question). From this track take, in order until the per-track share (5–7) is filled: primary journey, out of scope, permissions, the one anti-goal, failure behaviour, data retention, success metric. Everything else is an `[inferred]` assumption.
