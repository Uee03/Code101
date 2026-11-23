import type { Task, TaskStatus } from '../api/types';

export const statuses: TaskStatus[] = ['todo', 'in_progress', 'blocked', 'done', 'cancelled'];

export const statusLabels: Record<TaskStatus, string> = {
  todo: 'To do',
  in_progress: 'In progress',
  blocked: 'Blocked',
  done: 'Done',
  cancelled: 'Cancelled',
};

export function isTaskStatus(value: string): value is TaskStatus {
  return (statuses as string[]).includes(value);
}

export function groupByStatus(tasks: Task[]): Record<TaskStatus, Task[]> {
  const groups: Record<TaskStatus, Task[]> = { todo: [], in_progress: [], blocked: [], done: [], cancelled: [] };
  for (const task of tasks) {
    groups[task.status].push(task);
  }
  return groups;
}
