import { useInfiniteQuery, useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api } from '../api/client';
import { unwrap, versioned } from '../api/unwrap';
import type { Project, Versioned, Schemas } from '../api/types';
import { keys } from './keys';
import { useAction } from './action';
export function useProjects(teamId: string, archived: boolean | undefined) {
  return useInfiniteQuery({ queryKey: keys.list('projects', teamId, { archived }), initialPageParam: undefined as string | undefined,
    queryFn: async ({ pageParam, signal }) => unwrap(await api.GET('/v1/teams/{teamId}/projects', { signal,
      params: { path: { teamId }, query: { limit: 25, cursor: pageParam, archived } } })),
    getNextPageParam: last => last.page.nextCursor ?? undefined,
  });
}
export function useProject(projectId: string) {
  return useQuery({ queryKey: keys.entity('project', projectId), enabled: !!projectId,
    queryFn: async ({ signal }) => versioned(await api.GET('/v1/projects/{projectId}', { signal, params: { path: { projectId } } })),
  });
}
export function useCreateProject(teamId: string) {
  return useAction(async ({ body, key }: { body: Schemas['ProjectCreate']; key: string }) =>
    unwrap(await api.POST('/v1/teams/{teamId}/projects', { body, params: { path: { teamId }, header: { 'Idempotency-Key': key } } })));
}
export function useUpdateProject() {
  const cache = useQueryClient();
  return useMutation({
    mutationFn: async ({ projectId, body }: { projectId: string; body: Schemas['ProjectUpdate'] }) => {
      const current = versioned(await api.GET('/v1/projects/{projectId}', { params: { path: { projectId } } }));
      return versioned(await api.PATCH('/v1/projects/{projectId}', { body,
        params: { path: { projectId }, header: { 'If-Match': current.etag } } }));
    },
    onMutate: async ({ projectId, body }) => {
      await cache.cancelQueries({ queryKey: ['projects'] });
      const snapshots = cache.getQueriesData<{ pages: Schemas['ProjectPage'][]; pageParams: unknown[] }>({ queryKey: ['projects'] });
      for (const [key, data] of snapshots) if (data) cache.setQueryData(key, {
        ...data, pages: data.pages.map(page => ({ ...page, items: page.items.map(project => project.id === projectId ? { ...project, ...body } : project) })),
      });
      return snapshots;
    },
    onError: (_error, _variables, snapshots) => { snapshots?.forEach(([key, data]) => cache.setQueryData(key, data)); },
    onSuccess: (result: Versioned<Project>) => { cache.setQueryData(keys.entity('project', result.value.id), result); },
    onSettled: () => cache.invalidateQueries({ queryKey: ['projects'] }), retry: false,
  });
}
export function useDeleteProject() {
  return useAction(async (projectId: string) => unwrap(await api.DELETE('/v1/projects/{projectId}', { params: { path: { projectId } } })));
}
