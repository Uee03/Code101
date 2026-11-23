import { useInfiniteQuery, useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import type { operations } from '../api/schema';
import { api } from '../api/client';
import { unwrap, versioned } from '../api/unwrap';
import type { Task, Versioned, Schemas } from '../api/types';
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
  const cache = useQueryClient(); const key = keys.entity('task', taskId);
  return useQuery({ queryKey: key, enabled: !!taskId, refetchOnWindowFocus: true,
    queryFn: async ({ signal }) => {
      const current = cache.getQueryData<Versioned<Task>>(key);
      return versioned(await api.GET('/v1/tasks/{taskId}', { signal, params: { path: { taskId },
        header: { 'If-None-Match': current?.etag } } }), current);
    },
  });
}
export function useCreateTask(projectId: string) {
  return useAction(async ({ body, key }: { body: Schemas['TaskCreate']; key: string }) =>
    unwrap(await api.POST('/v1/projects/{projectId}/tasks', { body, params: { path: { projectId }, header: { 'Idempotency-Key': key } } })));
}
export function useUpdateTask(taskId: string) {
  const cache = useQueryClient(); const key = keys.entity('task', taskId);
  return useMutation({
    mutationFn: async ({ body, etag }: { body: Schemas['TaskUpdate']; etag: string }) =>
      versioned(await api.PATCH('/v1/tasks/{taskId}', { body, params: { path: { taskId }, header: { 'If-Match': etag } } })),
    onMutate: async ({ body }) => {
      await cache.cancelQueries({ queryKey: key });
      const snapshot = cache.getQueryData<Versioned<Task>>(key);
      if (snapshot) cache.setQueryData(key, { ...snapshot, value: { ...snapshot.value, ...body } });
      return snapshot;
    },
    onError: (_error, _variables, snapshot) => { if (snapshot) cache.setQueryData(key, snapshot); },
    onSuccess: result => { cache.setQueryData(key, result); },
    onSettled: () => cache.invalidateQueries({ queryKey: ['tasks'] }),
    retry: false,
  });
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
