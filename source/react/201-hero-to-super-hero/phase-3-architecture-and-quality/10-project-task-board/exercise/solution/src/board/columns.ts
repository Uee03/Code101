import type { Task, TaskPriority, TaskStatus } from '../api/types';

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

const priorityRank: Record<TaskPriority, number> = { urgent: 0, high: 1, medium: 2, low: 3 };

export function groupByStatus(tasks: Task[]): Record<TaskStatus, Task[]> {
  const groups: Record<TaskStatus, Task[]> = { todo: [], in_progress: [], blocked: [], done: [], cancelled: [] };
  for (const task of tasks) {
    groups[task.status].push(task);
  }
  for (const status of statuses) {
    groups[status].sort((a, b) => priorityRank[a.priority] - priorityRank[b.priority]);
  }
  return groups;
}
