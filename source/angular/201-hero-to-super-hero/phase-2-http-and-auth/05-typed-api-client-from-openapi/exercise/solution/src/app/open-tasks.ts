import { Api } from './api/api';
import { listTasks } from './api/functions';
import { Task } from './api/models';

// Returns every task that is not done or cancelled, page after page.
export async function allOpenTasks(api: Api, projectId: string): Promise<Task[]> {
  const tasks: Task[] = [];
  let cursor: string | undefined;
  do {
    const page = await api.invoke(listTasks, { projectId, limit: 2, cursor, status: ['todo', 'in_progress', 'blocked'] });
    tasks.push(...page.items);
    cursor = page.page.nextCursor ?? undefined;
  } while (cursor);
  return tasks;
}
