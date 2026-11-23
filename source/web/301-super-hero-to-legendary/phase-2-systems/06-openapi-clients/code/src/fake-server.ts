import type { FetchLike } from './api/client.js';

export const TASK_ID = '3f2b1c5e-8a41-4d3b-9c6e-1a2b3c4d5e6f';
export const PROJECT_ID = '0b6d7a52-4c1e-4f0a-8d33-5e9f2c7a1b40';
const USER_ID = '7c9e6679-7425-40de-944b-e07fc1f90ae7';

export const TASK = {
  id: TASK_ID,
  projectId: PROJECT_ID,
  title: 'Write the ADR',
  description: '',
  status: 'todo',
  priority: 'high',
  assigneeId: null,
  dueDate: '2026-12-01',
  completedAt: null,
  createdBy: USER_ID,
  version: 3,
  createdAt: '2026-11-20T09:30:00Z',
  updatedAt: '2026-11-21T10:00:00Z',
};

export const PROBLEM_JSON = 'application/problem+json';

export interface Scripted {
  status: number;
  body: unknown;
  contentType?: string;
  headers?: Record<string, string>;
}

// A fetch replacement that answers from a list, in order, and records each request. No network is used.
export function scriptedFetch(queue: Scripted[], calls: string[]): FetchLike {
  return async (input) => {
    const request = input instanceof Request ? input : new Request(input);
    calls.push(
      `${request.method} ${new URL(request.url).pathname} auth=${request.headers.get('Authorization') ?? 'none'}`,
    );
    const next = queue.shift();
    if (next === undefined) {
      throw new Error('No scripted response left');
    }
    const body = typeof next.body === 'string' ? next.body : JSON.stringify(next.body);
    return new Response(body, {
      status: next.status,
      headers: { 'Content-Type': next.contentType ?? 'application/json', ...next.headers },
    });
  };
}
