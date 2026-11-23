import { Api } from '../src/app/api/api';
import { createTeam, createProject, createTask, updateTask, getTask, deleteTeam } from '../src/app/api/functions';
import { parseProblem } from '../src/app/http/problem';
import { HttpErrorResponse } from '@angular/common/http';
export async function errorsSmoke(api: Api): Promise<void> {
  const team = await api.invoke(createTeam, { 'Idempotency-Key': crypto.randomUUID(), body: { name: `Angular smoke ${crypto.randomUUID()}` } });
  try {
    const project = await api.invoke(createProject, { teamId: team.id, 'Idempotency-Key': crypto.randomUUID(), body: { key: 'ANG', name: 'Smoke' } });
    const request = { projectId: project.id, 'Idempotency-Key': crypto.randomUUID(), body: { title: 'Compare ETags' } };
    const first = await api.invoke$Response(createTask, request);
    const replay = await api.invoke$Response(createTask, request);
    if (replay.body.id !== first.body.id || replay.headers.get('Idempotent-Replayed') !== 'true') throw new Error('Replay mismatch');
    console.log('Idempotent-Replayed: true');
    const taskId = first.body.id;
    const tag = first.headers.get('ETag')!;
    await api.invoke(updateTask, { taskId, 'If-Match': tag, body: { title: 'Saved by another tab' } });
    for (const [label, expected, call] of [
      ['412', 412, () => api.invoke(updateTask, { taskId, 'If-Match': tag, body: { title: 'Stale draft' } })],
      ['404', 404, () => api.invoke(getTask, { taskId: crypto.randomUUID() })],
      ['422', 422, () => api.invoke(createTask, { projectId: project.id, 'Idempotency-Key': crypto.randomUUID(), body: { title: '' } })],
    ] as const) {
      try { await call(); throw new Error(`Expected ${expected}`); }
      catch (error) {
        if (!(error instanceof HttpErrorResponse) || error.status !== expected) throw error;
        const problem = parseProblem(error.status, error.error, error.headers);
        console.log(`${label} ${problem.type.split('/').pop()}`);
        console.log(`detail: ${problem.detail}`);
        if (expected === 422) console.log(`field: ${problem.errors?.[0]?.pointer}`);
      }
    }
    // One canned response demonstrates parsing; it does not pretend Keycloak lacks a scope.
    const problem = parseProblem(429, { title: 'Too many requests' }, new Headers({ 'Retry-After': '2' }));
    console.log(`429 canned Retry-After: ${problem.retryAfter}`);
  } finally { await api.invoke(deleteTeam, { teamId: team.id }); }
}
