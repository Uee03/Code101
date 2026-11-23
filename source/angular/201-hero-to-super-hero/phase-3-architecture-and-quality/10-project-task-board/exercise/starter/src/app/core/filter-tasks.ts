import { Task } from '../api/models';

// Returns the tasks whose title contains `text`, ignoring case and surrounding spaces.
// An empty text keeps every task. The input list is not changed.
export function filterTasks(tasks: readonly Task[], text: string): Task[] {
  // TODO 1: trim and lower-case `text`; when it is empty return a copy of `tasks`.
  // TODO 2: otherwise keep the tasks whose lower-cased title includes it.
  void tasks;
  void text;
  throw new Error('TODO: write filterTasks');
}
