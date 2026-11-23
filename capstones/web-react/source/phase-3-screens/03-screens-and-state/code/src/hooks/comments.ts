import { useInfiniteQuery } from '@tanstack/react-query';
import { api } from '../api/client';
import { unwrap } from '../api/unwrap';
import { keys } from './keys';
import { useAction } from './action';
export function useComments(taskId: string) {
  return useInfiniteQuery({ queryKey: keys.list('comments', taskId, {}), initialPageParam: undefined as string | undefined,
    queryFn: async ({ pageParam, signal }) => unwrap(await api.GET('/v1/tasks/{taskId}/comments', { signal,
      params: { path: { taskId }, query: { limit: 25, cursor: pageParam } } })),
    getNextPageParam: last => last.page.nextCursor ?? undefined,
  });
}
export function useCreateComment(taskId: string) {
  return useAction(async ({ body, key }: { body: string; key: string }) => unwrap(await api.POST('/v1/tasks/{taskId}/comments', {
    body: { body }, params: { path: { taskId }, header: { 'Idempotency-Key': key } },
  })));
}
export function useDeleteComment() {
  return useAction(async (commentId: string) => unwrap(await api.DELETE('/v1/comments/{commentId}', { params: { path: { commentId } } })));
}
