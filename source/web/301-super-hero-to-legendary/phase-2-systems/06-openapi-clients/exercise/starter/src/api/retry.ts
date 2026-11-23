import type { TasksClient } from './client.js';
import type { Task, TaskUpdate } from './schemas.js';
import { updateTask, type ApiResult } from './tasks.js';

export interface RetryOutcome {
  result: ApiResult<Task>;
  retries: number;
}

// TODO 1: when the server answers 412 (the task changed since you read it), fetch the task again with
//         getTask, take its new ETag and try once more, at most maxRetries times.
// TODO 2: decide what to return when that refetch fails. Do not hide the failure.
// Today this does a single attempt and gives up.
export async function updateWithRetry(
  client: TasksClient,
  taskId: string,
  etag: string,
  changes: TaskUpdate,
  maxRetries = 1,
): Promise<RetryOutcome> {
  void maxRetries;
  return { result: await updateTask(client, taskId, etag, changes), retries: 0 };
}
