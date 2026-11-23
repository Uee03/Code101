export type TaskStatus = "todo" | "doing" | "done";

export interface Task {
  readonly id: number;
  title: string;
  status: TaskStatus;
}

export function isTaskStatus(value: unknown): value is TaskStatus {
  return value === "todo" || value === "doing" || value === "done";
}

export function parseTask(data: unknown): Task {
  if (typeof data !== "object" || data === null) {
    throw new Error("Task must be an object");
  }
  const { id, title, status } = data as Record<string, unknown>;
  if (typeof id !== "number") {
    throw new Error("Task.id must be a number");
  }
  if (typeof title !== "string") {
    throw new Error("Task.title must be a string");
  }
  if (!isTaskStatus(status)) {
    throw new Error("Task.status is not valid");
  }
  return { id, title, status };
}
