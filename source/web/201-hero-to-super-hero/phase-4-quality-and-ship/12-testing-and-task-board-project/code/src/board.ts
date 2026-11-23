export const MAX_TITLE = 80;

export type Status = "todo" | "doing" | "done";
export type Direction = "forward" | "back";

export const STATUSES: readonly Status[] = ["todo", "doing", "done"];

export const STATUS_LABELS = {
  todo: "To do",
  doing: "In progress",
  done: "Done",
} satisfies Record<Status, string>;

export interface Task {
  readonly id: number;
  readonly title: string;
  readonly status: Status;
}

export interface BoardState {
  readonly tasks: readonly Task[];
  readonly nextId: number;
}

export type BoardAction =
  | { type: "added"; title: string }
  | { type: "moved"; id: number; direction: Direction }
  | { type: "removed"; id: number };

export const emptyBoard: BoardState = { tasks: [], nextId: 1 };

export function neighbour(status: Status, direction: Direction): Status | null {
  const index = STATUSES.indexOf(status) + (direction === "forward" ? 1 : -1);
  return STATUSES[index] ?? null;
}

export function tasksIn(state: BoardState, status: Status): readonly Task[] {
  return state.tasks.filter((task) => task.status === status);
}

export function reduceBoard(state: BoardState, action: BoardAction): BoardState {
  switch (action.type) {
    case "added": {
      const title = action.title.trim();
      if (title === "" || title.length > MAX_TITLE) {
        return state;
      }
      const task: Task = { id: state.nextId, title, status: "todo" };
      return { tasks: [...state.tasks, task], nextId: state.nextId + 1 };
    }
    case "moved": {
      const { id, direction } = action;
      const task = state.tasks.find((item) => item.id === id);
      if (task === undefined) {
        return state;
      }
      const target = neighbour(task.status, direction);
      if (target === null) {
        return state;
      }
      return {
        ...state,
        tasks: state.tasks.map((item) => (item.id === id ? { ...item, status: target } : item)),
      };
    }
    case "removed": {
      const { id } = action;
      if (!state.tasks.some((item) => item.id === id)) {
        return state;
      }
      return { ...state, tasks: state.tasks.filter((item) => item.id !== id) };
    }
  }
}
