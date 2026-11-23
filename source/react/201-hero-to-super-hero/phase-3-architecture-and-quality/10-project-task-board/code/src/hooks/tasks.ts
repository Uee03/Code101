import { useInfiniteQuery, useMutation, useQueryClient, type InfiniteData, type QueryClient, type QueryKey } from '@tanstack/react-query';
import { api } from '../api/client';
import { etagFor } from '../api/etag';
import { ApiProblem } from '../api/problem';
import type { Task, TaskCreate, TaskPage, TaskStatus } from '../api/types';
import { unwrap } from '../api/unwrap';

export const taskKeys = {
  all: ['tasks'] as const,
  list: (projectId: string) => [...taskKeys.all, 'list', projectId] as const,
};

type TaskPages = InfiniteData<TaskPage, string | undefined>;
type MoveVariables = { task: Task; status: TaskStatus };
type CreateVariables = { body: TaskCreate; key: string };

export function useTasks(projectId: string) {
  return useInfiniteQuery({
    queryKey: taskKeys.list(projectId),
    initialPageParam: undefined as string | undefined,
    queryFn: async ({ pageParam, signal }) =>
      unwrap(
        await api.GET('/v1/projects/{projectId}/tasks', {
          params: { path: { projectId }, query: { limit: 25, cursor: pageParam } },
          signal,
        }),
      ),
    getNextPageParam: (lastPage) => lastPage.page.nextCursor ?? undefined,
  });
}

function replaceTask(client: QueryClient, key: QueryKey, saved: Task) {
  client.setQueryData<TaskPages>(key, (old) =>
    old
      ? {
          ...old,
          pages: old.pages.map((page) => ({
            ...page,
            items: page.items.map((item) => (item.id === saved.id ? saved : item)),
          })),
        }
      : old,
  );
}

export function useCreateTask(projectId: string) {
  const client = useQueryClient();
  return useMutation({
    mutationFn: async ({ body, key }: CreateVariables) =>
      unwrap(
        await api.POST('/v1/projects/{projectId}/tasks', {
          params: { path: { projectId }, header: { 'Idempotency-Key': key } },
          body,
        }),
      ),
    onSuccess: () => client.invalidateQueries({ queryKey: taskKeys.list(projectId) }),
  });
}

export function useMoveTask(projectId: string) {
  const client = useQueryClient();
  const key = taskKeys.list(projectId);
  return useMutation({
    mutationFn: async ({ task, status }: MoveVariables) =>
      unwrap(
        await api.PATCH('/v1/tasks/{taskId}', {
          params: { path: { taskId: task.id }, header: { 'If-Match': etagFor(task.version) } },
          body: { status },
        }),
      ),
    onMutate: async ({ task, status }) => {
      await client.cancelQueries({ queryKey: key });
      const previous = client.getQueryData<TaskPages>(key);
      replaceTask(client, key, { ...task, status });
      return { previous };
    },
    onSuccess: (saved) => replaceTask(client, key, saved),
    onError: (error, _variables, context) => {
      if (context?.previous) {
        client.setQueryData(key, context.previous);
      }
      if (error instanceof ApiProblem && error.status === 412) {
        void client.invalidateQueries({ queryKey: key });
      }
    },
  });
}
