import { Link, useParams } from 'react-router';
import { useCan, useTeam, useMembers, useUpdateTeam, usePutMember, useRemoveMember } from '../hooks/teams';
import type { Schemas } from '../api/types';
import { Page } from '../shared/Page';
import { Banner } from '../shared/Banner';
import { WriteForm, Field } from '../shared/WriteForm';
import { ConfirmDialog } from '../shared/ConfirmDialog';
import { LoadMore } from '../shared/LoadMore';
export function Component() {
  const { teamId = '' } = useParams(); const team = useTeam(teamId); const members = useMembers(teamId);
  const { lead } = useCan(teamId); const update = useUpdateTeam(teamId); const put = usePutMember(teamId); const remove = useRemoveMember(teamId);
  return <Page title="Team detail"><Banner error={team.error || members.error} retry={async () => { await Promise.all([team.refetch(), members.refetch()]); }} />
    {team.data && <><h2>{team.data.value.name}</h2><p>{team.data.value.description}</p><Link to={`/teams/${teamId}/projects`}>Projects</Link>
      {lead && <WriteForm label="Save team" submit={values => update.mutateAsync({ body: { name: values.name!, description: values.description! }, etag: team.data!.etag })}>
        <Field name="name" label="Name" value={team.data.value.name} required maxLength={80} />
        <Field name="description" label="Description" value={team.data.value.description} maxLength={500} />
      </WriteForm>}</>}
    <details open><summary>Members tab</summary><ul>{members.data?.pages.flatMap(page => page.items).map(member => <li key={member.userId}>
      {member.displayName} ({member.role}){lead && <>
        <WriteForm label={`Change role for ${member.displayName}`} submit={values => put.mutateAsync({ userId: member.userId, role: values.role as Schemas['TeamRole'] })}>
          <label>Role<select name="role" defaultValue={member.role}><option>member</option><option>lead</option></select></label></WriteForm>
        <ConfirmDialog label={`Remove ${member.displayName}`} action={() => remove.mutateAsync(member.userId)} />
      </>}</li>)}</ul><LoadMore query={members} />
      {lead && <WriteForm label="Add member" submit={values => put.mutateAsync({ userId: values.userId!, role: values.role as Schemas['TeamRole'] })}>
        <Field name="userId" label="Keycloak user UUID" required pattern="[0-9a-fA-F-]{36}" maxLength={36} />
        <label>Role<select name="role"><option>member</option><option>lead</option></select></label>
      </WriteForm>}
    </details>
  </Page>;
}
