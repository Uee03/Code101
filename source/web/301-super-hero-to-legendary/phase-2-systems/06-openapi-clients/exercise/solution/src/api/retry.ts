import type { TasksClient } from './client.js';
import type { Task, TaskUpdate } from './schemas.js';
import { getTask, updateTask, type ApiResult } from './tasks.js';

export interface RetryOutcome {
  result: ApiResult<Task>;
  retries: number;
}

// Optimistic concurrency: a 412 means someone else changed the task after we read it.
// Re-reading and re-applying is only safe when "changes" does not depend on what the other writer did.
export async function updateWithRetry(
  client: TasksClient,
  taskId: string,
  etag: string,
  changes: TaskUpdate,
  maxRetries = 1,
): Promise<RetryOutcome> {
  let currentEtag = etag;
  for (let retries = 0; ; retries += 1) {
    const result = await updateTask(client, taskId, currentEtag, changes);
    const conflict = result.kind === 'problem' && result.problem.status === 412;
    if (!conflict || retries >= maxRetries) {
      return { result, retries };
    }
    const fresh = await getTask(client, taskId);
    if (fresh.kind !== 'ok' || fresh.etag === undefined) {
      return { result: fresh, retries };
    }
    currentEtag = fresh.etag;
  }
}
