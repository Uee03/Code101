import { ConfirmDialog } from '../shared/ConfirmDialog';
import { Link, useParams, useSearchParams } from 'react-router';
import { useProjects, useCreateProject, useUpdateProject, useDeleteProject } from '../hooks/projects';
import { useCan } from '../hooks/teams';
import { Page } from '../shared/Page';
import { Banner } from '../shared/Banner';
import { Field, WriteForm } from '../shared/WriteForm';
import { LoadMore } from '../shared/LoadMore';
export function Component() {
  const { teamId = '' } = useParams(); const [params, setParams] = useSearchParams(); const { lead } = useCan(teamId);
  const projects = useProjects(teamId, params.get('archived') === 'all' ? undefined : false);
  const create = useCreateProject(teamId); const update = useUpdateProject(); const remove = useDeleteProject();
  return <Page title="Projects"><label><input type="checkbox" checked={params.get('archived') === 'all'}
    onChange={event => setParams({ archived: event.target.checked ? 'all' : 'active' })} />Show archived</label>
    <Banner error={projects.error} retry={() => projects.refetch()} />
    <ul>{projects.data?.pages.flatMap(page => page.items).map(project => <li key={project.id}>
      <Link to={`/projects/${project.id}`}>{project.key}: {project.name}</Link> {project.archived && '(archived)'}
      {lead && <WriteForm label={project.archived ? 'Restore and save' : 'Archive and save'} submit={values => update.mutateAsync({ projectId: project.id, body: { archived: !project.archived, name: values.name! } })}>
        <Field name="name" label="Project name" value={project.name} required maxLength={120} />
      </WriteForm>}
      {lead && <ConfirmDialog label={`Delete ${project.key}`} action={() => remove.mutateAsync(project.id)} />}
    </li>)}</ul><LoadMore query={projects} />
    {lead && <WriteForm label="Create project" submit={(values, key) => create.mutateAsync({ body: { key: values.key!, name: values.name!, description: values.description! }, key })}>
      <Field name="key" label="Key (2-10 uppercase letters or digits, starts with a letter)" required pattern="[A-Z][A-Z0-9]{1,9}" maxLength={10} />
      <Field name="name" label="Name" required maxLength={120} /><Field name="description" label="Description" maxLength={2000} />
    </WriteForm>}
  </Page>;
}
