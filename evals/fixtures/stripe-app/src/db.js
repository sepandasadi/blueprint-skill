// In-memory store. Replace with Postgres before production.
export const users = new Map([
  ['u_1', { id: 'u_1', email: 'ana@example.com', createdAt: '2026-01-10' }],
  ['u_2', { id: 'u_2', email: 'ben@example.com', createdAt: '2026-02-02' }],
]);
export const sessions = new Map([['tok_ana', 'u_1'], ['tok_ben', 'u_2']]);
