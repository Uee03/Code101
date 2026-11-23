export type Priority = 'low' | 'normal' | 'high';
export type Filter = 'all' | 'todo' | 'done';

export interface Task {
  id: number;
  title: string;
  done: boolean;
  priority: Priority;
  due?: string;
}

export type TaskDraft = Pick<Task, 'title' | 'priority' | 'due'>;
