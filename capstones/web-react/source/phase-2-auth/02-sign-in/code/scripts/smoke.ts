import { authTransport, isApiUrl } from '../src/auth/auth-middleware';
import { bindTokenGate } from '../src/auth/token-gate';
import { makeClient } from '../src/api/client';
import { unwrap } from '../src/api/unwrap';
const base = process.env.API_BASE_URL ?? 'http://localhost:8000';
const issuer = process.env.KEYCLOAK_URL ?? 'http://localhost:8180';
const tokenResponse = await fetch(`${issuer}/realms/tasksteams/protocol/openid-connect/token`, {
  method: 'POST', body: new URLSearchParams({ grant_type: 'password', client_id: 'tasks-smoke',
    username: 'alice', password: process.env.SMOKE_ALICE_PASSWORD ?? 'alice-local-fake',
    scope: 'openid tasks:read tasks:write tasks:admin' }),
});
if (!tokenResponse.ok) throw new Error(`Token endpoint ${tokenResponse.status}`);
const token = (await tokenResponse.json()).access_token as string;
bindTokenGate({ read: async () => ({ access_token: token }), refresh: async () => null, failed: async () => {} });
const transport = authTransport(base);
const boundary = authTransport(base, async input => {
  const request = new Request(input);
  if (request.headers.has('Authorization')) throw new Error('Token escaped API boundary');
  return new Response('not sent to a real host');
});
await boundary(new Request('https://not-an-api.invalid/', { headers: { Authorization: 'discard-me' } }));
if (isApiUrl('https://not-an-api.invalid/', base)) throw new Error('Foreign URL accepted');
console.log('foreign host: no bearer header (local transport stand-in)');
const api = makeClient(base, transport);
const health = unwrap(await api.GET('/health'));
const me = unwrap(await api.GET('/v1/me'));
if (health.status !== 'ok' || me.username !== 'alice' || !me.roles.includes('admin')) throw new Error('Unexpected seed');
console.log(`health: ${health.status}`);
console.log(`me: ${me.username} (${me.roles.join(', ')})`);
const missing = await makeClient(base).GET('/v1/me');
console.log(`without token: ${missing.response.status}`);
if (missing.response.status !== 401) throw new Error('Expected 401');

await import('./smoke-auth');
