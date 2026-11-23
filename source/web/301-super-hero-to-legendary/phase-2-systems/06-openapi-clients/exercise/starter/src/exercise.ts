import { createTasksClient } from './api/client.js';
import { updateWithRetry } from './api/retry.js';
import { PROBLEM_JSON, scriptedFetch, TASK, TASK_ID, type Scripted } from './fake-server.js';

const queue: Scripted[] = [
  { status: 412, contentType: PROBLEM_JSON, body: { type: 'urn:problem:conflict', title: 'Version conflict', status: 412 } },
  { status: 200, body: { ...TASK, version: 4 }, headers: { ETag: '"4"' } },
  { status: 200, body: { ...TASK, title: 'New title', version: 5 }, headers: { ETag: '"5"' } },
];
const calls: string[] = [];

const client = createTasksClient({
  baseUrl: 'http://localhost:8000',
  getToken: () => undefined,
  fetch: scriptedFetch(queue, calls),
});

const outcome = await updateWithRetry(client, TASK_ID, '"3"', { title: 'New title' });
console.log(`${outcome.result.kind} after ${outcome.retries} retry(ies)`);
console.log(calls.join('\n'));
