import { Link, useParams, useSearchParams } from 'react-router';
import { useTasks, useCreateTask, useMoveTask, type TaskFilter } from '../hooks/tasks';
import { useProject } from '../hooks/projects';
import { useMembers } from '../hooks/teams';
import type { Schemas } from '../api/types';
import { Page } from '../shared/Page';
import { Banner } from '../shared/Banner';
import { Field, WriteForm } from '../shared/WriteForm';
import { LoadMore } from '../shared/LoadMore';
import { Icon } from '../shared/Icon';
const statuses: Schemas['TaskStatus'][] = ['todo', 'in_progress', 'blocked', 'done', 'cancelled'];
const priorities: Schemas['TaskPriority'][] = ['low', 'medium', 'high', 'urgent'];
export function Component() {
  const { projectId = '' } = useParams(); const [params, setParams] = useSearchParams(); const project = useProject(projectId);
  const members = useMembers(project.data?.value.teamId ?? '');
  const filters: TaskFilter = { status: params.getAll('status').filter((v): v is Schemas['TaskStatus'] => statuses.includes(v as Schemas['TaskStatus'])),
    priority: params.getAll('priority').filter((v): v is Schemas['TaskPriority'] => priorities.includes(v as Schemas['TaskPriority'])),
    assigneeId: params.get('assigneeId') || undefined, dueAfter: params.get('dueAfter') || undefined, dueBefore: params.get('dueBefore') || undefined,
    q: params.get('q')?.trim() || undefined, sort: params.get('sort') === 'dueDate' ? 'dueDate' : params.get('sort') === 'createdAt' ? 'createdAt' : '-createdAt' };
  const tasks = useTasks(projectId, filters); const create = useCreateTask(projectId); const move = useMoveTask(); const board = params.get('view') === 'board';
  const people = members.data?.pages.flatMap(page => page.items) ?? [];
  return <Page title="Tasks"><Banner error={project.error || tasks.error || members.error} retry={async () => { await Promise.all([project.refetch(), tasks.refetch(), members.refetch()]); }} />
    <h2>{project.data?.value.name}</h2><details><summary><Icon name="filter" />Filters</summary>
      <form key={params.toString()} onSubmit={event => {
        event.preventDefault(); const next = new URLSearchParams();
        new FormData(event.currentTarget).forEach((value, key) => { if (String(value).trim()) next.append(key, String(value).trim()); });
        next.set('view', board ? 'board' : 'list'); setParams(next);
      }}><Field name="q" label="Title contains" value={params.get('q') ?? ''} maxLength={100} />
        <fieldset><legend>Status</legend>{statuses.map(status => <label key={status}><input type="checkbox" name="status" value={status} defaultChecked={params.getAll('status').includes(status)} />{status}</label>)}</fieldset>
        <fieldset><legend>Priority</legend>{priorities.map(priority => <label key={priority}><input type="checkbox" name="priority" value={priority} defaultChecked={params.getAll('priority').includes(priority)} />{priority}</label>)}</fieldset>
        <label>Assignee<select name="assigneeId" defaultValue={params.get('assigneeId') ?? ''}><option value="">Anyone</option>{people.map(person => <option key={person.userId} value={person.userId}>{person.displayName}</option>)}</select></label>
        <Field name="dueAfter" label="Due from" type="date" value={params.get('dueAfter') ?? ''} />
        <Field name="dueBefore" label="Due through" type="date" value={params.get('dueBefore') ?? ''} />
        <label>Sort<select name="sort" defaultValue={filters.sort}><option value="-createdAt">Newest</option><option value="createdAt">Oldest</option><option value="dueDate">Due date</option></select></label><button>Apply filters</button>
      </form>
    </details><button onClick={() => { const next = new URLSearchParams(params); next.set('view', board ? 'list' : 'board'); setParams(next); }}>
      <Icon name={board ? 'list' : 'columns'} />{board ? 'List view' : 'Board view'}</button>
    <div className={board ? 'board' : 'task-list'}>{(board ? statuses : ['All']).map(status => <section key={status}>
      {board && <h2>{status}</h2>}<ul>{tasks.data?.pages.flatMap(page => page.items).filter(task => !board || task.status === status).map(task => <li key={task.id}>
        <Link to={`/tasks/${task.id}`}>{task.title}</Link> ({task.status}, {task.priority})
        {board && <WriteForm label={`Move ${task.title}`} submit={values => move.mutateAsync({ taskId: task.id, status: values.status as Schemas['TaskStatus'] })}>
          <label>Move to<select name="status" defaultValue={task.status}>{statuses.map(value => <option key={value}>{value}</option>)}</select></label>
        </WriteForm>}
        {task.dueDate && <span><Icon name="calendar-days" />{task.dueDate}</span>}
      </li>)}</ul></section>)}</div><LoadMore query={tasks} />
    <p>Assignee choices</p><LoadMore query={members} />
    {!project.data?.value.archived && <WriteForm label="Create task" submit={(values, key) => create.mutateAsync({ body: {
      title: values.title!, description: values.description!, priority: values.priority as Schemas['TaskPriority'],
      dueDate: values.dueDate || null, assigneeId: values.assigneeId || null,
    }, key })}><Field name="title" label="Title" required /><Field name="description" label="Description" maxLength={10000} />
      <label>Priority<select name="priority" defaultValue="medium">{priorities.map(priority => <option key={priority}>{priority}</option>)}</select></label>
      <label>Assignee<select name="assigneeId"><option value="">Unassigned</option>{people.map(person => <option key={person.userId} value={person.userId}>{person.displayName}</option>)}</select></label>
      <Field name="dueDate" label="Due date" type="date" />
    </WriteForm>}
  </Page>;
}
