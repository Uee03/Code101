import { Link, useSearchParams } from 'react-router';
import { useCan, useTeams, useCreateTeam, useDeleteTeam } from '../hooks/teams';
import { Page } from '../shared/Page';
import { Banner } from '../shared/Banner';
import { Field, WriteForm } from '../shared/WriteForm';
import { ConfirmDialog } from '../shared/ConfirmDialog';
import { LoadMore } from '../shared/LoadMore';
import { Icon } from '../shared/Icon';
export function Component() {
  const [params, setParams] = useSearchParams(); const { admin } = useCan('');
  const teams = useTeams({ q: params.get('q')?.trim() || undefined, sort: params.get('sort') === 'createdAt' ? 'createdAt' : '-createdAt' });
  const create = useCreateTeam(); const remove = useDeleteTeam();
  return <Page title="Teams"><form key={params.toString()} onSubmit={event => {
    event.preventDefault(); const data = new FormData(event.currentTarget); setParams({ q: String(data.get('q')).trim(), sort: String(data.get('sort')) });
  }}><label><Icon name="search" />Search<input name="q" defaultValue={params.get('q') ?? ''} maxLength={100} /></label>
    <label>Sort<select name="sort" defaultValue={params.get('sort') ?? '-createdAt'}><option value="-createdAt">Newest</option><option value="createdAt">Oldest</option></select></label>
    <button>Search</button></form><Banner error={teams.error} retry={() => teams.refetch()} />
    <ul>{teams.data?.pages.flatMap(page => page.items).map(team => <li key={team.id}>
      <Link to={`/teams/${team.id}`}>{team.name}</Link> ({team.memberCount} members)
      {admin && <ConfirmDialog label={`Delete ${team.name}`} action={() => remove.mutateAsync(team.id)} />}</li>)}</ul>
    <LoadMore query={teams} />{admin && <WriteForm label="Create team" submit={(values, key) => create.mutateAsync({ body: { name: values.name!, description: values.description! }, key })}>
      <Field name="name" label="Team name" required maxLength={80} /><Field name="description" label="Description" maxLength={500} />
    </WriteForm>}
  </Page>;
}
