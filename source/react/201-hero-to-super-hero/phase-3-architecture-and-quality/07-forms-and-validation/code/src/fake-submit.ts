import { ApiProblem } from './api/problem';
import type { TaskValues } from './forms/validate';

export type CreatedTask = TaskValues & { id: number; replayed: boolean };

const stored = new Map<string, CreatedTask>();
let nextId = 1;

function wait(milliseconds = 300): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

// A stand-in for POST /v1/projects/{projectId}/tasks with an Idempotency-Key header.
export async function submitTask(values: TaskValues, key: string): Promise<CreatedTask> {
  await wait();
  const earlier = stored.get(key);
  if (earlier) {
    return { ...earlier, replayed: true };
  }
  const title = values.title.toLowerCase();
  if (title === 'duplicate') {
    throw new ApiProblem({
      type: 'https://code101.example/problems/validation-error',
      title: 'Validation failed',
      status: 422,
      detail: 'One or more fields are invalid.',
      errors: [{ pointer: '/title', detail: 'A task with this title already exists.' }],
    });
  }
  if (title === 'boom') {
    throw new ApiProblem({
      type: 'https://code101.example/problems/internal',
      title: 'Internal server error',
      status: 500,
      traceId: '4bf92f3577b34da6a3ce929d0e0e4736',
    });
  }
  const task: CreatedTask = { ...values, id: nextId, replayed: false };
  nextId += 1;
  stored.set(key, task);
  if (title === 'flaky') {
    // The server saved the task, but the answer never reached the browser.
    throw new TypeError('Failed to fetch');
  }
  return task;
}
