# acme-accounts

Small Express API for user accounts.

- `POST /login` — magic-link login (token in `Authorization: Bearer <token>`)
- `GET /account` — current user's account page data
- Storage: in-memory map in `src/db.js` (swap for Postgres later)
- Tests: `npm test` (node:test)
