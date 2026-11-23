import { useQuery } from '@tanstack/react-query';
import { api } from '../api/client';
import { unwrap } from '../api/unwrap';

export const projectKeys = {
  all: ['projects'] as const,
  byTeam: (teamId: string) => [...projectKeys.all, 'team', teamId] as const,
  detail: (projectId: string) => [...projectKeys.all, 'detail', projectId] as const,
};

export function useTeamProjects(teamId: string) {
  return useQuery({
    queryKey: projectKeys.byTeam(teamId),
    queryFn: async ({ signal }) =>
      unwrap(await api.GET('/v1/teams/{teamId}/projects', { params: { path: { teamId }, query: { limit: 25 } }, signal })),
  });
}

export function useProject(projectId: string) {
  return useQuery({
    queryKey: projectKeys.detail(projectId),
    queryFn: async ({ signal }) =>
      unwrap(await api.GET('/v1/projects/{projectId}', { params: { path: { projectId } }, signal })),
  });
}
