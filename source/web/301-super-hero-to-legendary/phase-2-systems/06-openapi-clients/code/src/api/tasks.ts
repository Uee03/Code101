import type { z } from 'zod';
import type { TasksClient } from './client.js';
import { ProblemSchema, TaskPageSchema, TaskSchema, type Problem, type Task, type TaskUpdate } from './schemas.js';

export type ApiResult<T> =
  | { kind: 'ok'; value: T; etag: string | undefined }
  | { kind: 'problem'; problem: Problem }
  | { kind: 'contract-violation'; paths: string[] }
  | { kind: 'unexpected'; status: number };

// The one place that decides what a response means. Types say what the contract promises;
// the schema checks what actually arrived.
function interpret<T>(response: Response, data: unknown, error: unknown, schema: z.ZodType<T>): ApiResult<T> {
  if (response.ok) {
    const parsed = schema.safeParse(data);
    if (parsed.success) {
      return { kind: 'ok', value: parsed.data, etag: response.headers.get('ETag') ?? undefined };
    }
    return { kind: 'contract-violation', paths: parsed.error.issues.map((issue) => issue.path.join('.')) };
  }
  const problem = ProblemSchema.safeParse(error);
  return problem.success ? { kind: 'problem', problem: problem.data } : { kind: 'unexpected', status: response.status };
}

export async function getTask(client: TasksClient, taskId: string): Promise<ApiResult<Task>> {
  const { data, error, response } = await client.GET('/v1/tasks/{taskId}', {
    params: { path: { taskId } },
  });
  return interpret(response, data, error, TaskSchema);
}

export async function updateTask(
  client: TasksClient,
  taskId: string,
  etag: string,
  changes: TaskUpdate,
): Promise<ApiResult<Task>> {
  const { data, error, response } = await client.PATCH('/v1/tasks/{taskId}', {
    params: { path: { taskId }, header: { 'If-Match': etag } },
    body: changes,
  });
  return interpret(response, data, error, TaskSchema);
}

export async function listTasks(
  client: TasksClient,
  projectId: string,
  query: { status?: Task['status']; limit?: number } = {},
): Promise<ApiResult<z.infer<typeof TaskPageSchema>>> {
  const { data, error, response } = await client.GET('/v1/projects/{projectId}/tasks', {
    params: { path: { projectId }, query },
  });
  return interpret(response, data, error, TaskPageSchema);
}
