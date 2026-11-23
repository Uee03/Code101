import { useRef, useState } from 'react';
import { ApiProblem } from '../api/problem';
import { ConflictDialog } from '../shared/ConflictDialog';
import { useToast } from '../core/toast';
import { Link, useNavigate, useParams } from 'react-router';
import { useTask, useUpdateTask, useCompleteTask, useReassignTask, useDeleteTask } from '../hooks/tasks';
import { useProject } from '../hooks/projects';
import { useCan, useMembers } from '../hooks/teams';
import { useComments, useCreateComment, useDeleteComment } from '../hooks/comments';
import { useMe } from '../hooks/me';
import type { Schemas } from '../api/types';
import { Page } from '../shared/Page';
import { Banner } from '../shared/Banner';
import { WriteForm, Field } from '../shared/WriteForm';
import { ConfirmDialog } from '../shared/ConfirmDialog';
import { LoadMore } from '../shared/LoadMore';
import { Icon } from '../shared/Icon';
const statuses: Schemas['TaskStatus'][] = ['todo', 'in_progress', 'blocked', 'done', 'cancelled'];
const priorities: Schemas['TaskPriority'][] = ['low', 'medium', 'high', 'urgent'];
export function Component() {
  const { taskId = '' } = useParams(); const navigate = useNavigate(); const task = useTask(taskId);
  const project = useProject(task.data?.value.projectId ?? ''); const teamId = project.data?.value.teamId ?? '';
  const { lead } = useCan(teamId); const people = useMembers(teamId); const me = useMe();
  const update = useUpdateTask(taskId); const complete = useCompleteTask(taskId); const reassign = useReassignTask(taskId); const remove = useDeleteTask(taskId);
  const comments = useComments(taskId); const add = useCreateComment(taskId); const deleteComment = useDeleteComment();
  const toast = useToast(); const baseline = useRef(task.data); const baselineId = useRef(taskId);
  const [formKey, setFormKey] = useState(0);
  const [conflict, setConflict] = useState<{ body: Schemas['TaskUpdate']; server: NonNullable<typeof task.data> }>();
  if (baselineId.current !== taskId) { baseline.current = undefined; baselineId.current = taskId; }
  if (!baseline.current && task.data) baseline.current = task.data;
  async function save(body: Schemas['TaskUpdate'], etag: string) {
    try {
      baseline.current = await update.mutateAsync({ body, etag });
      setConflict(undefined); setFormKey(key => key + 1); toast('Task saved.');
    } catch (error) {
      if (error instanceof ApiProblem && error.status === 412) {
        const current = await task.refetch();
        if (current.data) setConflict({ body, server: current.data });
      }
      throw error;
    }
  }

  return <Page title="Task detail"><Banner error={task.error || project.error || comments.error || people.error} retry={async () => { await Promise.all([task.refetch(), project.refetch(), comments.refetch(), people.refetch()]); }} />
    {task.data && <><h2>{task.data.value.title}</h2><p>{task.data.value.description}</p><p>Status: {task.data.value.status}</p>
      <p>Completed: {task.data.value.completedAt ? new Intl.DateTimeFormat(undefined, { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(task.data.value.completedAt)) : 'Not completed'}</p>
      <Link to={`/projects/${task.data.value.projectId}`}>Tasks</Link>
      <WriteForm key={formKey} label="Save task" submit={async values => {
        const draft: Schemas['TaskUpdate'] = { title: values.title!, description: values.description!,
          status: values.status as Schemas['TaskStatus'], priority: values.priority as Schemas['TaskPriority'],
          assigneeId: values.assigneeId || null, dueDate: values.dueDate || null };
        const body = Object.fromEntries(Object.entries(draft).filter(([key, value]) =>
          baseline.current!.value[key as keyof typeof draft] !== value)) as Schemas['TaskUpdate'];
        if (!Object.keys(body).length) { toast('No changes.'); return; }
        await save(body, baseline.current!.etag);
      }}>
        <Field name="title" label="Title" required value={baseline.current!.value.title} />
        <Field name="description" label="Description" value={baseline.current!.value.description} maxLength={10000} />
        <label>Move to<select name="status" defaultValue={baseline.current!.value.status}>{statuses.map(status => <option key={status}>{status}</option>)}</select></label>
        <label>Priority<select name="priority" defaultValue={baseline.current!.value.priority}>{priorities.map(priority => <option key={priority}>{priority}</option>)}</select></label>
        <label>Assignee<select name="assigneeId" defaultValue={baseline.current!.value.assigneeId ?? ''}><option value="">Unassigned</option>{people.data?.pages.flatMap(page => page.items).map(person => <option key={person.userId} value={person.userId}>{person.displayName}</option>)}</select></label>
        <Field name="dueDate" label="Due date" type="date" value={baseline.current!.value.dueDate ?? ''} />
      </WriteForm>
      <WriteForm label="Complete task" submit={() => complete.mutateAsync(task.data!.etag)}><Icon name="check-circle" /></WriteForm>
      {lead && <><WriteForm label="Reassign task" submit={values => reassign.mutateAsync({ assigneeId: values.assigneeId || null, etag: task.data!.etag })}>
        <label>New assignee<select name="assigneeId"><option value="">Unassigned</option>{people.data?.pages.flatMap(page => page.items).map(person => <option key={person.userId} value={person.userId}>{person.displayName}</option>)}</select></label>
      </WriteForm><ConfirmDialog label="Delete task" action={async () => { await remove.mutateAsync(task.data!.etag); await navigate(`/projects/${task.data!.value.projectId}`); }} /></>}
    </>}
    {conflict && <ConflictDialog key={conflict.server.etag} server={conflict.server.value} local={conflict.body}
      useServer={() => { baseline.current = conflict.server; setConflict(undefined); setFormKey(key => key + 1); }}
      apply={async () => {
        const current = await task.refetch();
        if (!current.data || current.error) throw current.error ?? new Error('Could not read current task.');
        await save(conflict.body, current.data.etag);
      }} />}
    <p>Assignee choices</p><LoadMore query={people} />
    <h2>Comments</h2><ul>{comments.data?.pages.flatMap(page => page.items).map(comment => <li key={comment.id}>
      <p>{comment.author.displayName}: {comment.body}</p>{(lead || comment.author.id === me.data?.id) && <ConfirmDialog label={`Delete comment by ${comment.author.displayName}`} action={() => deleteComment.mutateAsync(comment.id)} />}
    </li>)}</ul><LoadMore query={comments} />
    <WriteForm label="Add comment" submit={(values, key) => add.mutateAsync({ body: values.body!, key })}><Field name="body" label="Comment" required maxLength={2000} /></WriteForm>
  </Page>;
}
