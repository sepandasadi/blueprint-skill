import { test } from 'node:test';
import assert from 'node:assert/strict';
import { app } from '../src/server.js';

test('GET /account requires auth', async () => {
  const server = app.listen(0);
  const { port } = server.address();
  const res = await fetch(`http://localhost:${port}/account`);
  assert.equal(res.status, 401);
  server.close();
});
