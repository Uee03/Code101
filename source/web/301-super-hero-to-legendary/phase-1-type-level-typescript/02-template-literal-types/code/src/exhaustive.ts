export type TaskStatus = 'todo' | 'in_progress' | 'blocked' | 'done' | 'cancelled';

// Passing anything other than never is a compile error, so a forgotten case is caught.
// If bad data still arrives at runtime, it fails loudly with the offending value.
export function assertNever(value: never, context: string): never {
  throw new Error(`Unhandled ${context}: ${JSON.stringify(value)}`);
}

// Exhaustive map: adding a status to the union without a label is a compile error.
export const statusLabels = {
  todo: 'To do',
  in_progress: 'In progress',
  blocked: 'Blocked',
  done: 'Done',
  cancelled: 'Cancelled',
} satisfies Record<TaskStatus, string>;

export type TaskEvent =
  | { type: 'created'; id: string; title: string }
  | { type: 'status_changed'; id: string; to: TaskStatus }
  | { type: 'deleted'; id: string };

// Strict: for events this program defines itself. A new variant stops this from compiling.
export function describe(event: TaskEvent): string {
  switch (event.type) {
    case 'created':
      return `Created ${event.title}`;
    case 'status_changed':
      return `${event.id} is now ${statusLabels[event.to]}`;
    case 'deleted':
      return `Deleted ${event.id}`;
    default:
      return assertNever(event, 'task event');
  }
}

export function isTaskStatus(value: string): value is TaskStatus {
  return Object.hasOwn(statusLabels, value);
}

// Tolerant: for data from a server that may be newer than this client.
export function labelFor(status: string): string {
  return isTaskStatus(status) ? statusLabels[status] : `Unknown (${status})`;
}
