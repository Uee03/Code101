export type TaskStatus = "todo" | "doing" | "done";

export interface Task {
  readonly id: number;
  title: string;
  status: TaskStatus;
  note?: string;
}

export type TaskEvent =
  | { kind: "created"; task: Task }
  | { kind: "moved"; id: number; to: TaskStatus }
  | { kind: "deleted"; id: number };

export type TaskPatch = Partial<Omit<Task, "id">>;
export type TaskSummary = Pick<Task, "id" | "title">;
export type TasksByStatus = Record<TaskStatus, Task[]>;

const STATUSES: readonly TaskStatus[] = ["todo", "doing", "done"];

export const STATUS_LABELS = {
  todo: "To do",
  doing: "In progress",
  done: "Done",
} satisfies Record<TaskStatus, string>;

export function isTaskStatus(value: unknown): value is TaskStatus {
  return STATUSES.some((status) => status === value);
}

export function parseStatus(input: unknown): TaskStatus {
  if (!isTaskStatus(input)) {
    throw new Error(`Not a task status: ${String(input)}`);
  }
  return input;
}

export function assertNever(value: never): never {
  throw new Error("Unhandled case: " + JSON.stringify(value));
}

export function describeEvent(event: TaskEvent): string {
  switch (event.kind) {
    case "created":
      return `Created "${event.task.title}" (#${event.task.id})`;
    case "moved":
      return `Moved #${event.id} to ${event.to}`;
    case "deleted":
      return `Deleted #${event.id}`;
    default:
      return assertNever(event);
  }
}

export function applyEvent(tasks: readonly Task[], event: TaskEvent): Task[] {
  switch (event.kind) {
    case "created":
      return [...tasks, event.task];
    case "moved": {
      const { id, to } = event;
      return tasks.map((task) => (task.id === id ? { ...task, status: to } : task));
    }
    case "deleted": {
      const { id } = event;
      return tasks.filter((task) => task.id !== id);
    }
    default:
      return assertNever(event);
  }
}

export function updateTask(task: Task, patch: TaskPatch): Task {
  return { ...task, ...patch };
}

export function toSummary(task: Task): TaskSummary {
  return { id: task.id, title: task.title };
}

export function statusLabel(item: Task | TaskSummary): string {
  return "status" in item ? STATUS_LABELS[item.status] : "Unknown";
}

export function groupByStatus(tasks: readonly Task[]): TasksByStatus {
  const groups: TasksByStatus = { todo: [], doing: [], done: [] };
  for (const task of tasks) {
    groups[task.status].push(task);
  }
  return groups;
}

export function formatNote(note: string | string[] | undefined): string {
  if (note === undefined) {
    return "no note";
  }
  if (Array.isArray(note)) {
    return note.join("; ");
  }
  return note;
}
