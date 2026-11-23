import { Api } from './api/api';
import { listTasks } from './api/functions';
import { Task } from './api/models';

// Returns every task that is not done or cancelled, page after page.
export async function allOpenTasks(api: Api, projectId: string): Promise<Task[]> {
  // TODO 1: call listTasks with limit 2 and status ['todo', 'in_progress', 'blocked'].
  // TODO 2: add page.items to a result array, then repeat with cursor = page.page.nextCursor until it is null.
  // The compiler tells you the type of every parameter: hover over `listTasks` and read its params type.
  void api;
  void projectId;
  void listTasks;
  throw new Error('TODO: write allOpenTasks');
}
