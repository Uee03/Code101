// A tiny stand-in for the Tasks and Teams backend, for lessons 04 to 10 of the Angular 201 track.
// It speaks a small part of the platform contract on port 8000. It is NOT a real backend: no database,
// no token validation (it only checks that a bearer header exists when started with --require-auth).
// Stop it before you start a real backend: both want port 8000.
import { createServer } from 'node:http';
import { randomUUID } from 'node:crypto';

const PORT = 8000;
const ORIGIN = 'http://localhost:4200';
const REQUIRE_AUTH = process.argv.includes('--require-auth');

const USER_ID = '33333333-3333-4333-8333-333333333333';
const TEAM_ID = '11111111-1111-4111-8111-111111111111';
const PROJECT_ID = '22222222-2222-4222-8222-222222222222';
const taskId = (number) => `5d1b8d9e-0000-4000-8000-${String(number).padStart(12, '0')}`;
const STATUSES = ['todo', 'in_progress', 'blocked', 'done', 'cancelled'];
const PRIORITIES = ['low', 'medium', 'high', 'urgent'];

const ME = {
  id: USER_ID,
  username: 'alice',
  email: 'alice@example.test',
  displayName: 'Alice Admin',
  roles: ['admin'],
  scopes: ['tasks:read', 'tasks:write'],
  teams: [{ teamId: TEAM_ID, name: 'Platform Team', role: 'lead' }]
};

const timestamp = () => new Date().toISOString();
const makeTask = (number, title, status, priority) => ({
  id: taskId(number),
  projectId: PROJECT_ID,
  title,
  description: '',
  status,
  priority,
  assigneeId: null,
  dueDate: null,
  completedAt: status === 'done' ? timestamp() : null,
  createdBy: USER_ID,
  version: 1,
  createdAt: timestamp(),
  updatedAt: timestamp()
});

const tasks = [
  makeTask(1, 'Write the OpenAPI file', 'done', 'high'),
  makeTask(2, 'Add the health check', 'in_progress', 'medium'),
  makeTask(3, 'Seed the database', 'todo', 'medium'),
  makeTask(4, 'Explain signals', 'todo', 'low'),
  makeTask(5, 'Record a demo', 'blocked', 'high'),
  makeTask(6, 'Review the release notes', 'todo', 'urgent')
];
let nextNumber = 7;
const replays = new Map();
let limitedCalls = 0;

function send(res, status, body, headers = {}) {
  res.writeHead(status, {
    'Access-Control-Allow-Origin': ORIGIN,
    'Access-Control-Expose-Headers': 'ETag, Location, Retry-After, Idempotent-Replayed, RateLimit-Remaining',
    Vary: 'Origin',
    'RateLimit-Limit': '100',
    'RateLimit-Remaining': '99',
    'Content-Type': 'application/json',
    ...headers
  });
  res.end(body === undefined ? undefined : JSON.stringify(body));
}

function problem(req, res, status, title, detail, extra = {}, headers = {}) {
  const slug = title.toLowerCase().replaceAll(' ', '-');
  send(
    res,
    status,
    {
      type: `https://code101.example/problems/${slug}`,
      title,
      status,
      detail,
      instance: new URL(req.url, 'http://localhost').pathname,
      traceId: randomUUID().replaceAll('-', ''),
      ...extra
    },
    { 'Content-Type': 'application/problem+json', ...headers }
  );
}

async function readJson(req) {
  const chunks = [];
  for await (const chunk of req) {
    chunks.push(chunk);
  }
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8') || '{}');
  } catch {
    return null;
  }
}

const page = (items, limit, nextCursor) => ({ items, page: { limit, nextCursor } });

function validate(body, partial) {
  const errors = [];
  if (!partial || 'title' in body) {
    if (typeof body.title !== 'string' || body.title.length < 1 || body.title.length > 200) {
      errors.push({ pointer: '/title', detail: 'must be between 1 and 200 characters' });
    } else if (/[<>]/.test(body.title)) {
      errors.push({ pointer: '/title', detail: 'must not contain < or >' });
    }
  }
  if ('status' in body && !STATUSES.includes(body.status)) {
    errors.push({ pointer: '/status', detail: `must be one of ${STATUSES.join(', ')}` });
  }
  if ('priority' in body && !PRIORITIES.includes(body.priority)) {
    errors.push({ pointer: '/priority', detail: `must be one of ${PRIORITIES.join(', ')}` });
  }
  if ('dueDate' in body && body.dueDate !== null && !/^\d{4}-\d{2}-\d{2}$/.test(body.dueDate)) {
    errors.push({ pointer: '/dueDate', detail: 'must be a date like 2026-12-31' });
  }
  return errors;
}

const server = createServer(async (req, res) => {
  const url = new URL(req.url, 'http://localhost');
  const path = url.pathname;
  const method = req.method;

  if (method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': ORIGIN,
      'Access-Control-Allow-Methods': 'GET, POST, PATCH, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Authorization, Content-Type, If-Match, If-None-Match, Idempotency-Key',
      'Access-Control-Max-Age': '600',
      Vary: 'Origin'
    });
    res.end();
    return;
  }

  if (method === 'GET' && path === '/health') {
    send(res, 200, { status: 'ok', version: 'mock', database: 'up' });
    return;
  }

  if (path.startsWith('/v1/') && REQUIRE_AUTH && !(req.headers.authorization ?? '').startsWith('Bearer ')) {
    problem(req, res, 401, 'Unauthorized', 'A bearer access token is required.', {}, { 'WWW-Authenticate': 'Bearer realm="tasksteams"' });
    return;
  }

  let match = path.match(/^\/v1\/demo\/error\/(\d{3})$/);
  if (method === 'GET' && match) {
    const status = Number(match[1]);
    const extra = status === 422 ? { errors: [{ pointer: '/title', detail: 'must be between 1 and 200 characters' }] } : {};
    const headers = status === 429 ? { 'Retry-After': '2' } : {};
    problem(req, res, status, `Demo error ${status}`, `This is a demo answer with status ${status}.`, extra, headers);
    return;
  }
  if (method === 'GET' && path === '/v1/demo/limited') {
    limitedCalls++;
    if (limitedCalls % 2 === 1) {
      problem(req, res, 429, 'Too many requests', 'Slow down.', {}, { 'Retry-After': '1' });
    } else {
      send(res, 200, { ok: true, message: 'The retry worked.' });
    }
    return;
  }
  if (method === 'GET' && path === '/v1/demo/drop') {
    req.socket.destroy();
    return;
  }

  if (method === 'GET' && path === '/v1/me') {
    send(res, 200, ME);
    return;
  }
  if (method === 'GET' && path === '/v1/teams') {
    const team = { id: TEAM_ID, name: 'Platform Team', description: 'Builds the platform', memberCount: 1, createdBy: USER_ID, version: 1, createdAt: timestamp(), updatedAt: timestamp() };
    send(res, 200, page([team], 25, null));
    return;
  }
  match = path.match(/^\/v1\/teams\/([^/]+)\/projects$/);
  if (method === 'GET' && match) {
    const project = { id: PROJECT_ID, teamId: match[1], key: 'PLAT', name: 'Platform', description: 'The platform project', archived: false, version: 1, createdAt: timestamp(), updatedAt: timestamp() };
    send(res, 200, page([project], 25, null));
    return;
  }

  match = path.match(/^\/v1\/projects\/([^/]+)\/tasks$/);
  if (match && method === 'GET') {
    const limit = Math.min(100, Math.max(1, Number(url.searchParams.get('limit') ?? 25) || 25));
    const start = Number(url.searchParams.get('cursor') ?? 0);
    if (!Number.isInteger(start) || start < 0) {
      problem(req, res, 400, 'Bad request', 'The cursor is not valid.');
      return;
    }
    const wanted = url.searchParams.getAll('status');
    const text = (url.searchParams.get('q') ?? '').toLowerCase();
    const rows = tasks.filter((task) => (wanted.length === 0 || wanted.includes(task.status)) && task.title.toLowerCase().includes(text));
    const end = start + limit;
    send(res, 200, page(rows.slice(start, end), limit, end < rows.length ? String(end) : null));
    return;
  }
  if (match && method === 'POST') {
    const body = await readJson(req);
    if (body === null) {
      problem(req, res, 400, 'Bad request', 'The body is not valid JSON.');
      return;
    }
    const errors = validate(body, false);
    if (errors.length > 0) {
      problem(req, res, 422, 'Validation failed', 'One or more fields are invalid.', { errors });
      return;
    }
    const key = req.headers['idempotency-key'];
    const fingerprint = JSON.stringify(body);
    if (typeof key === 'string' && replays.has(key)) {
      const first = replays.get(key);
      if (first.fingerprint !== fingerprint) {
        problem(req, res, 422, 'Validation failed', 'The Idempotency-Key was used with another body.');
        return;
      }
      send(res, 201, first.task, { Location: `http://localhost:${PORT}/v1/tasks/${first.task.id}`, ETag: '"1"', 'Idempotent-Replayed': 'true' });
      return;
    }
    const task = makeTask(nextNumber++, body.title, 'todo', body.priority ?? 'medium');
    task.description = body.description ?? '';
    task.dueDate = body.dueDate ?? null;
    tasks.push(task);
    if (typeof key === 'string') {
      replays.set(key, { fingerprint, task });
    }
    send(res, 201, task, { Location: `http://localhost:${PORT}/v1/tasks/${task.id}`, ETag: '"1"' });
    return;
  }

  match = path.match(/^\/v1\/tasks\/([^/]+)$/);
  if (match) {
    const task = tasks.find((row) => row.id === match[1]);
    if (!task) {
      problem(req, res, 404, 'Not found', 'The task does not exist, or you may not know that it exists.');
      return;
    }
    const etag = `"${task.version}"`;
    if (method === 'GET') {
      if (req.headers['if-none-match'] === etag) {
        send(res, 304, undefined, { ETag: etag });
        return;
      }
      send(res, 200, task, { ETag: etag });
      return;
    }
    if (method === 'PATCH') {
      if (!req.headers['if-match']) {
        problem(req, res, 428, 'Precondition required', 'Send the If-Match header with the ETag you read.');
        return;
      }
      if (req.headers['if-match'] !== etag) {
        problem(req, res, 412, 'Precondition failed', `The task changed since you read it (current version ${task.version}).`);
        return;
      }
      const body = await readJson(req);
      if (body === null) {
        problem(req, res, 400, 'Bad request', 'The body is not valid JSON.');
        return;
      }
      const errors = validate(body, true);
      if (errors.length > 0) {
        problem(req, res, 422, 'Validation failed', 'One or more fields are invalid.', { errors });
        return;
      }
      Object.assign(task, body, { version: task.version + 1, updatedAt: timestamp() });
      task.completedAt = task.status === 'done' ? timestamp() : null;
      send(res, 200, task, { ETag: `"${task.version}"` });
      return;
    }
  }

  problem(req, res, 404, 'Not found', 'This mock server does not know that address.');
});

server.listen(PORT, 'localhost', () => {
  console.log(`Mock API on http://localhost:${PORT}${REQUIRE_AUTH ? ' (bearer header required)' : ''}`);
});
