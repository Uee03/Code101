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
  return <Page title="Task detail"><Banner error={task.error || project.error || comments.error || people.error} retry={async () => { await Promise.all([task.refetch(), project.refetch(), comments.refetch(), people.refetch()]); }} />
    {task.data && <><h2>{task.data.value.title}</h2><p>{task.data.value.description}</p><p>Status: {task.data.value.status}</p>
      <p>Completed: {task.data.value.completedAt ? new Intl.DateTimeFormat(undefined, { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(task.data.value.completedAt)) : 'Not completed'}</p>
      <Link to={`/projects/${task.data.value.projectId}`}>Tasks</Link>
      <WriteForm label="Save task" submit={values => update.mutateAsync({ body: {
        title: values.title!, description: values.description!, status: values.status as Schemas['TaskStatus'],
        priority: values.priority as Schemas['TaskPriority'], assigneeId: values.assigneeId || null, dueDate: values.dueDate || null,
      }, etag: task.data!.etag })}>
        <Field name="title" label="Title" required value={task.data.value.title} />
        <Field name="description" label="Description" value={task.data.value.description} maxLength={10000} />
        <label>Move to<select name="status" defaultValue={task.data.value.status}>{statuses.map(status => <option key={status}>{status}</option>)}</select></label>
        <label>Priority<select name="priority" defaultValue={task.data.value.priority}>{priorities.map(priority => <option key={priority}>{priority}</option>)}</select></label>
        <label>Assignee<select name="assigneeId" defaultValue={task.data.value.assigneeId ?? ''}><option value="">Unassigned</option>{people.data?.pages.flatMap(page => page.items).map(person => <option key={person.userId} value={person.userId}>{person.displayName}</option>)}</select></label>
        <Field name="dueDate" label="Due date" type="date" value={task.data.value.dueDate ?? ''} />
      </WriteForm>
      <WriteForm label="Complete task" submit={() => complete.mutateAsync(task.data!.etag)}><Icon name="check-circle" /></WriteForm>
      {lead && <><WriteForm label="Reassign task" submit={values => reassign.mutateAsync({ assigneeId: values.assigneeId || null, etag: task.data!.etag })}>
        <label>New assignee<select name="assigneeId"><option value="">Unassigned</option>{people.data?.pages.flatMap(page => page.items).map(person => <option key={person.userId} value={person.userId}>{person.displayName}</option>)}</select></label>
      </WriteForm><ConfirmDialog label="Delete task" action={async () => { await remove.mutateAsync(task.data!.etag); await navigate(`/projects/${task.data!.value.projectId}`); }} /></>}
    </>}
    <p>Assignee choices</p><LoadMore query={people} />
    <h2>Comments</h2><ul>{comments.data?.pages.flatMap(page => page.items).map(comment => <li key={comment.id}>
      <p>{comment.author.displayName}: {comment.body}</p>{(lead || comment.author.id === me.data?.id) && <ConfirmDialog label={`Delete comment by ${comment.author.displayName}`} action={() => deleteComment.mutateAsync(comment.id)} />}
    </li>)}</ul><LoadMore query={comments} />
    <WriteForm label="Add comment" submit={(values, key) => add.mutateAsync({ body: values.body!, key })}><Field name="body" label="Comment" required maxLength={2000} /></WriteForm>
  </Page>;
}
