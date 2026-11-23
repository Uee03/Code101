export type Filter = "all" | "open" | "done";

export interface Task {
  readonly id: number;
  readonly title: string;
  readonly done: boolean;
}

export interface State {
  readonly tasks: readonly Task[];
  readonly nextId: number;
  readonly filter: Filter;
}

export type Action =
  | { type: "added"; title: string }
  | { type: "toggled"; id: number }
  | { type: "removed"; id: number }
  | { type: "filter-changed"; filter: Filter };

export const initialState: State = {
  tasks: [
    { id: 1, title: "Read the store lesson", done: true },
    { id: 2, title: "Write a reducer", done: false },
  ],
  nextId: 3,
  filter: "all",
};

export function reduce(state: State, action: Action): State {
  switch (action.type) {
    case "added": {
      const title = action.title.trim();
      if (title === "") {
        return state;
      }
      const task: Task = { id: state.nextId, title, done: false };
      return { ...state, tasks: [...state.tasks, task], nextId: state.nextId + 1 };
    }
    case "toggled": {
      const { id } = action;
      return {
        ...state,
        tasks: state.tasks.map((task) => (task.id === id ? { ...task, done: !task.done } : task)),
      };
    }
    case "removed": {
      const { id } = action;
      return { ...state, tasks: state.tasks.filter((task) => task.id !== id) };
    }
    case "filter-changed":
      return state.filter === action.filter ? state : { ...state, filter: action.filter };
  }
}

export function visibleTasks(state: State): readonly Task[] {
  switch (state.filter) {
    case "all":
      return state.tasks;
    case "open":
      return state.tasks.filter((task) => !task.done);
    case "done":
      return state.tasks.filter((task) => task.done);
  }
}

export function openCount(state: State): number {
  return state.tasks.filter((task) => !task.done).length;
}
