import { useInfiniteQuery, useQuery } from '@tanstack/react-query';
import type { operations } from '../api/schema';
import { api } from '../api/client';
import { unwrap, versioned } from '../api/unwrap';
import type { Schemas } from '../api/types';
import { keys } from './keys';
import { useAction } from './action';
export type TaskFilter = NonNullable<operations['listTasks']['parameters']['query']>;
export function useTasks(projectId: string, filters: TaskFilter) {
  return useInfiniteQuery({ queryKey: keys.list('tasks', projectId, filters), initialPageParam: undefined as string | undefined,
    queryFn: async ({ pageParam, signal }) => unwrap(await api.GET('/v1/projects/{projectId}/tasks', { signal,
      params: { path: { projectId }, query: { ...filters, limit: 25, cursor: pageParam } } })),
    getNextPageParam: last => last.page.nextCursor ?? undefined,
  });
}
export function useTask(taskId: string) {
  return useQuery({ queryKey: keys.entity('task', taskId), enabled: !!taskId,
    queryFn: async ({ signal }) => versioned(await api.GET('/v1/tasks/{taskId}', { signal, params: { path: { taskId } } })),
  });
}
export function useCreateTask(projectId: string) {
  return useAction(async ({ body, key }: { body: Schemas['TaskCreate']; key: string }) =>
    unwrap(await api.POST('/v1/projects/{projectId}/tasks', { body, params: { path: { projectId }, header: { 'Idempotency-Key': key } } })));
}
export function useUpdateTask(taskId: string) {
  return useAction(async ({ body, etag }: { body: Schemas['TaskUpdate']; etag: string }) =>
    versioned(await api.PATCH('/v1/tasks/{taskId}', { body, params: { path: { taskId }, header: { 'If-Match': etag } } })));
}
export function useCompleteTask(taskId: string) {
  return useAction(async (etag: string) => versioned(await api.POST('/v1/tasks/{taskId}/complete', {
    params: { path: { taskId }, header: { 'If-Match': etag } },
  })));
}
export function useReassignTask(taskId: string) {
  return useAction(async ({ assigneeId, etag }: { assigneeId: string | null; etag: string }) =>
    versioned(await api.POST('/v1/tasks/{taskId}/reassign', { body: { assigneeId }, params: { path: { taskId }, header: { 'If-Match': etag } } })));
}
export function useDeleteTask(taskId: string) {
  return useAction(async (etag: string) => unwrap(await api.DELETE('/v1/tasks/{taskId}', {
    params: { path: { taskId }, header: { 'If-Match': etag } },
  })));
}

export function useMoveTask() {
  return useAction(async ({ taskId, status }: { taskId: string; status: Schemas['TaskStatus'] }) => {
    const current = versioned(await api.GET('/v1/tasks/{taskId}', { params: { path: { taskId } } }));
    return versioned(await api.PATCH('/v1/tasks/{taskId}', { body: { status }, params: { path: { taskId }, header: { 'If-Match': current.etag } } }));
  });
}
