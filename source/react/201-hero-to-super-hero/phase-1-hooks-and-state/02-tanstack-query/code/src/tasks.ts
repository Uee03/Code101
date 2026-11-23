export type Status = 'todo' | 'doing' | 'done';

export type Task = {
  id: number;
  title: string;
  status: Status;
};

export const statuses: Status[] = ['todo', 'doing', 'done'];

export function isStatus(value: string): value is Status {
  return (statuses as string[]).includes(value);
}
