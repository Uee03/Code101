import { authTransport, isApiUrl } from '../src/auth/auth-middleware';
import { bindTokenGate } from '../src/auth/token-gate';
import { ApiProblem, parseProblem } from '../src/api/problem';
import { versioned } from '../src/api/unwrap';
import { makeClient } from '../src/api/client';
import type { Schemas } from '../src/api/types';
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

let cursor: string | undefined;
let count = 0;
do {
  const page: Schemas['TeamPage'] = unwrap(await api.GET('/v1/teams', { params: { query: { limit: 1, cursor } } }));
  count += page.items.length; cursor = page.page.nextCursor ?? undefined;
} while (cursor);
if (count !== 2) throw new Error('Unexpected team count');
console.log(`teams: ${count}`);
const team = unwrap(await api.GET('/v1/teams', { params: { query: { q: 'Platform' } } })).items[0]!;
const project = unwrap(await api.GET('/v1/teams/{teamId}/projects', { params: { path: { teamId: team.id } } })).items.find(p => p.key === 'PLAT')!;
count = 0; cursor = undefined;
do {
  const page: Schemas['TaskPage'] = unwrap(await api.GET('/v1/projects/{projectId}/tasks', { params: { path: { projectId: project.id }, query: { limit: 2, cursor } } }));
  count += page.items.length; cursor = page.page.nextCursor ?? undefined;
} while (cursor);
if (count < 3) throw new Error('Expected paginated tasks');
console.log(`tasks: ${count}; nextCursor: null`);

const key = crypto.randomUUID();
const options = { body: { title: 'React smoke task', description: '' }, params: { path: { projectId: project.id }, header: { 'Idempotency-Key': key } } };
const created = versioned(await api.POST('/v1/projects/{projectId}/tasks', options));
const replay = await api.POST('/v1/projects/{projectId}/tasks', options);
if (replay.response.headers.get('Idempotent-Replayed') !== 'true' || unwrap(replay).id !== created.value.id) throw new Error('Replay failed');
console.log('Idempotent-Replayed: true');
const taskId = created.value.id;
const changed = versioned(await api.PATCH('/v1/tasks/{taskId}', { body: { title: 'React smoke saved' }, params: { path: { taskId }, header: { 'If-Match': created.etag } } }));
const stale = await api.PATCH('/v1/tasks/{taskId}', { body: { title: 'Stale edit' }, params: { path: { taskId }, header: { 'If-Match': created.etag } } });
try { unwrap(stale); throw new Error('Expected 412'); }
catch (error) { if (!(error instanceof ApiProblem) || error.status !== 412) throw error; console.log(`412 ${error.type.split('/').pop()}`); console.log(error.message); }
const absent = await api.GET('/v1/tasks/{taskId}', { params: { path: { taskId: '00000000-0000-4000-8000-000000000000' } } });
const notFound = parseProblem(absent.response, absent.error);
if (notFound.status !== 404 || !notFound.traceId) throw new Error('Expected problem 404');
console.log(`404 ${notFound.type.split('/').pop()}`); console.log(notFound.message);
const invalid = await api.POST('/v1/projects/{projectId}/tasks', { body: { title: '', description: '' }, params: { path: { projectId: project.id } } });
const validation = parseProblem(invalid.response, invalid.error);
if (validation.status !== 422 || !validation.errors?.some(field => field.pointer === '/title')) throw new Error('Expected pointer /title');
console.log(`422 ${validation.type.split('/').pop()}; pointer: /title`); console.log(validation.message);
const canned = parseProblem(Response.json({ title: 'Too many requests', status: 429 }, { status: 429,
  headers: { 'Content-Type': 'application/problem+json', 'Retry-After': '1' } }), { title: 'Too many requests' });
if (canned.retryAfter !== 1) throw new Error('Retry-After parser failed');
console.log('canned 429 Retry-After: 1');
const cached = await api.GET('/v1/tasks/{taskId}', { params: { path: { taskId }, header: { 'If-None-Match': changed.etag } } });
if (cached.response.status !== 304 || versioned(cached, changed).etag !== changed.etag) throw new Error('Expected 304');
console.log('304 kept cached task');
const done = unwrap(await api.POST('/v1/tasks/{taskId}/complete', { params: { path: { taskId }, header: { 'If-Match': changed.etag } } }));
if (done.status !== 'done' || !done.completedAt) throw new Error('Complete failed');
console.log('complete: done; completedAt: present');
unwrap(await api.DELETE('/v1/tasks/{taskId}', { params: { path: { taskId } } }));

await import('./smoke-auth');
