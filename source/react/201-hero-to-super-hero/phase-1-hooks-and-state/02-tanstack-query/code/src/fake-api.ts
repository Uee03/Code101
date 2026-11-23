import type { Status, Task } from './tasks';

let tasks: Task[] = [
  { id: 1, title: 'Write the plan', status: 'done' },
  { id: 2, title: 'Build the board', status: 'doing' },
  { id: 3, title: 'Review the code', status: 'todo' },
];
let nextId = 4;

function wait(milliseconds = 500): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

export async function listTasks(): Promise<Task[]> {
  await wait();
  return tasks.map((task) => ({ ...task }));
}

export async function createTask(title: string): Promise<Task> {
  await wait();
  const task: Task = { id: nextId, title, status: 'todo' };
  nextId += 1;
  tasks = [...tasks, task];
  return { ...task };
}

export async function moveTask(id: number, status: Status): Promise<Task> {
  await wait();
  const current = tasks.find((task) => task.id === id);
  if (!current) {
    throw new Error('Task not found');
  }
  if (current.title.toLowerCase().includes('fail')) {
    throw new Error('The server refused this change');
  }
  const updated: Task = { ...current, status };
  tasks = tasks.map((task) => (task.id === id ? updated : task));
  return { ...updated };
}

export async function removeTask(id: number): Promise<void> {
  await wait();
  tasks = tasks.filter((task) => task.id !== id);
}
