import { Task } from '../api/models';

// Returns the tasks whose title contains `text`, ignoring case and surrounding spaces.
// An empty text keeps every task. The input list is not changed.
export function filterTasks(tasks: readonly Task[], text: string): Task[] {
  const needle = text.trim().toLowerCase();
  if (!needle) {
    return [...tasks];
  }
  return tasks.filter((task) => task.title.toLowerCase().includes(needle));
}
