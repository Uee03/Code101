import { useAuth } from 'react-oidc-context';
import { config } from '../config';
import { useInfiniteQuery, useQuery } from '@tanstack/react-query';
import { api } from '../api/client';
import { unwrap, versioned } from '../api/unwrap';
import type { Schemas } from '../api/types';
import { keys } from './keys';
import { useAction } from './action';
import { useMe } from './me';
export function useCan(teamId: string) {
  const me = useMe();
  return { admin: !!me.data?.roles.includes('admin'), lead: !!me.data?.roles.includes('admin')
    || me.data?.teams.some(team => team.teamId === teamId && team.role === 'lead') === true };
}
export function useTeams(filters: { q?: string; sort?: '-createdAt' | 'createdAt' }) {
  return useInfiniteQuery({ queryKey: keys.list('teams', '', filters), initialPageParam: undefined as string | undefined,
    queryFn: async ({ pageParam, signal }) => unwrap(await api.GET('/v1/teams', { signal,
      params: { query: { ...filters, limit: 25, cursor: pageParam } } })),
    getNextPageParam: last => last.page.nextCursor ?? undefined,
  });
}
export function useTeam(teamId: string) {
  return useQuery({ queryKey: keys.entity('team', teamId), enabled: !!teamId,
    queryFn: async ({ signal }) => versioned(await api.GET('/v1/teams/{teamId}', { signal, params: { path: { teamId } } })),
  });
}
export function useMembers(teamId: string) {
  return useInfiniteQuery({ queryKey: keys.list('members', teamId, {}), enabled: !!teamId, initialPageParam: undefined as string | undefined,
    queryFn: async ({ pageParam, signal }) => unwrap(await api.GET('/v1/teams/{teamId}/members', { signal,
      params: { path: { teamId }, query: { limit: 25, cursor: pageParam } } })),
    getNextPageParam: last => last.page.nextCursor ?? undefined,
  });
}
export function useCreateTeam() {
  return useAction(async ({ body, key }: { body: Schemas['TeamCreate']; key: string }) =>
    unwrap(await api.POST('/v1/teams', { body, params: { header: { 'Idempotency-Key': key } } })));
}
export function useUpdateTeam(teamId: string) {
  return useAction(async ({ body, etag }: { body: Schemas['TeamUpdate']; etag: string }) =>
    versioned(await api.PATCH('/v1/teams/{teamId}', { body, params: { path: { teamId }, header: { 'If-Match': etag } } })));
}
export function useDeleteTeam() {
  const me = useMe(); const auth = useAuth();
  return useAction(async (teamId: string) => {
    if (!me.data?.scopes.includes('tasks:admin')) {
      await auth.signinRedirect({ scope: `${config.scopes} tasks:admin`, prompt: 'none',
        state: { returnTo: location.pathname + location.search } });
      return;
    }
    return unwrap(await api.DELETE('/v1/teams/{teamId}', { params: { path: { teamId } } }));
  });
}
export function usePutMember(teamId: string) {
  return useAction(async ({ userId, role }: { userId: string; role: Schemas['TeamRole'] }) =>
    unwrap(await api.PUT('/v1/teams/{teamId}/members/{userId}', { body: { role }, params: { path: { teamId, userId } } })));
}
export function useRemoveMember(teamId: string) {
  return useAction(async (userId: string) => unwrap(await api.DELETE('/v1/teams/{teamId}/members/{userId}', { params: { path: { teamId, userId } } })));
}
