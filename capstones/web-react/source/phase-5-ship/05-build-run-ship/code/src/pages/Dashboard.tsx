import { Link } from 'react-router';
import { useQuery } from '@tanstack/react-query';
import { useMe } from '../hooks/me';
import { useTeams } from '../hooks/teams';
import { api } from '../api/client';
import { unwrap } from '../api/unwrap';
import { Page } from '../shared/Page';
import { Banner } from '../shared/Banner';
export function Component() {
  const me = useMe(); const teams = useTeams({});
  const health = useQuery({ queryKey: ['health'], queryFn: async () => unwrap(await api.GET('/health')) });
  return <Page title="Dashboard"><Banner error={me.error || teams.error || health.error} retry={async () => { await Promise.all([me.refetch(), teams.refetch(), health.refetch()]); }} />
    <p>Hello, {me.data?.displayName}</p><p>Roles: {me.data?.roles.join(', ')}</p><p>Scopes: {me.data?.scopes.join(', ')}</p>
    <p role="status">API: {health.data?.status ?? 'checking'}</p>
    <h2>My teams</h2><ul>{me.data?.teams.map(team => <li key={team.teamId}>
      <Link to={`/teams/${team.teamId}`}>{team.name}</Link> ({team.role})</li>)}</ul>
    <p>Visible teams on the first page: {teams.data?.pages[0]?.items.length ?? 0}</p>
  </Page>;
}
