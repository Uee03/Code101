export type Status = 'todo' | 'doing' | 'done';

export type Task = {
  id: number;
  title: string;
  status: Status;
};

export type Action =
  | { type: 'add'; title: string }
  | { type: 'move'; id: number; status: Status }
  | { type: 'remove'; id: number };

export const statuses: Status[] = ['todo', 'doing', 'done'];

export const initialTasks: Task[] = [
  { id: 1, title: 'Write the plan', status: 'done' },
  { id: 2, title: 'Build the board', status: 'doing' },
  { id: 3, title: 'Review the code', status: 'todo' },
  { id: 4, title: 'Ship it', status: 'todo' },
];

export function isStatus(value: string): value is Status {
  return (statuses as string[]).includes(value);
}

function assertNever(value: never): never {
  throw new Error(`Unhandled action: ${JSON.stringify(value)}`);
}

export function tasksReducer(state: Task[], action: Action): Task[] {
  switch (action.type) {
    case 'add': {
      const id = Math.max(0, ...state.map((task) => task.id)) + 1;
      return [...state, { id, title: action.title, status: 'todo' }];
    }
    case 'move':
      return state.map((task) => (task.id === action.id ? { ...task, status: action.status } : task));
    case 'remove':
      return state.filter((task) => task.id !== action.id);
    default:
      return assertNever(action);
  }
}

export function countByStatus(tasks: Task[]): Record<Status, number> {
  const counts: Record<Status, number> = { todo: 0, doing: 0, done: 0 };
  for (const task of tasks) {
    counts[task.status] += 1;
  }
  return counts;
}
