import { createTasksClient } from './api/client.js';
import { getTask, listTasks, updateTask, type ApiResult } from './api/tasks.js';
import { PROBLEM_JSON, PROJECT_ID, scriptedFetch, TASK, TASK_ID, type Scripted } from './fake-server.js';

// Responses the fake server will give, in order.
const queue: Scripted[] = [
  { status: 200, body: TASK, headers: { ETag: '"3"', Deprecation: 'true', Sunset: 'Sun, 31 Oct 2027 00:00:00 GMT' } },
  { status: 200, body: { ...TASK, priority: 'critical' } },
  { status: 404, contentType: PROBLEM_JSON, body: { type: 'urn:problem:not-found', title: 'Task not found', status: 404 } },
  { status: 412, contentType: PROBLEM_JSON, body: { type: 'urn:problem:conflict', title: 'Version conflict', status: 412, code: 'version_conflict' } },
  { status: 200, body: { items: [TASK], nextCursor: null } },
  { status: 502, contentType: 'text/plain', body: 'Bad Gateway' },
];

const calls: string[] = [];

const client = createTasksClient({
  baseUrl: 'http://localhost:8000',
  getToken: () => 'demo-token',
  fetch: scriptedFetch(queue, calls),
  onDeprecation: (message) => console.log(`WARN ${message}`),
});

function describeResult(result: ApiResult<unknown>): string {
  switch (result.kind) {
    case 'ok': {
      const value = result.value as { title?: string; version?: number; items?: unknown[] };
      return value.items !== undefined
        ? `ok ${value.items.length} task(s)`
        : `ok ${value.title} (etag ${result.etag}, version ${value.version})`;
    }
    case 'problem':
      return `problem ${result.problem.status} ${result.problem.title}${result.problem.code ? ` (${result.problem.code})` : ''}`;
    case 'contract-violation':
      return `contract violation at ${result.paths.join(', ')}`;
    case 'unexpected':
      return `unexpected status ${result.status}`;
  }
}

console.log(describeResult(await getTask(client, TASK_ID)));
console.log(describeResult(await getTask(client, TASK_ID)));
console.log(describeResult(await getTask(client, TASK_ID)));
console.log(describeResult(await updateTask(client, TASK_ID, '"2"', { title: 'New title' })));
console.log(describeResult(await listTasks(client, PROJECT_ID, { limit: 10 })));
console.log(describeResult(await listTasks(client, PROJECT_ID)));
console.log('requests:');
for (const call of calls) {
  console.log(call);
}
