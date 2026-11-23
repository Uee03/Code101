export interface Task {
  id: number;
  title: string;
  done: boolean;
  version: number;
}

export interface TaskDraft {
  title: string;
}

// The ETag of a task is its version in quotes, like the platform API sends it.
export function etagOf(task: Task): string {
  return `"${task.version}"`;
}
