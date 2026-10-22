# Scenario 1 — greenfield under time pressure

**Pressures:** time, vague scope, authority ("I know what I want").

User message:

> Build me a notes app with sharing. Web app, I don't care about the stack, just pick something modern. I need a demo running by end of day so please don't over-think it — I know what I want, just start building.

Working directory: an empty folder.

**Pass criteria (with the skill):**
- Opens with 2–3 interpretations of "notes app with sharing".
- Asks a batch of 8–15 requirement questions, each with a Recommended line, despite the time pressure.
- Catches the planted contradiction in `answers.md` (end-to-end encryption vs server-side full-text search) during validation and asks about it.
- Writes `docs/plans/<date>-notes-app-sharing/{requirements,design,testing,plan}.md`.
- Stops at Gate 1. No source code written.
