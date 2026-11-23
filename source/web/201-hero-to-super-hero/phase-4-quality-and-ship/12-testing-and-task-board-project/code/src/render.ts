import {
  STATUSES,
  STATUS_LABELS,
  neighbour,
  tasksIn,
  type BoardState,
  type Direction,
  type Status,
  type Task,
} from "./board";

type Action = "move-forward" | "move-back" | "remove";

function actionButton(task: Task, action: Action, text: string): HTMLButtonElement {
  const button = document.createElement("button");
  button.type = "button";
  button.className = "button button--small";
  button.textContent = text;
  button.setAttribute("aria-label", `${text}: ${task.title}`);
  button.dataset.action = action;
  button.dataset.id = String(task.id);
  button.dataset.focusKey = `${action}-${task.id}`;
  return button;
}

function moveButton(task: Task, direction: Direction): HTMLButtonElement | null {
  const target = neighbour(task.status, direction);
  if (target === null) {
    return null;
  }
  const action = direction === "forward" ? "move-forward" : "move-back";
  return actionButton(task, action, `Move to ${STATUS_LABELS[target]}`);
}

function taskItem(task: Task): HTMLLIElement {
  const item = document.createElement("li");
  item.className = "task";
  item.dataset.taskId = String(task.id);

  const title = document.createElement("span");
  title.className = "task__title";
  title.textContent = task.title;

  const actions = document.createElement("div");
  actions.className = "task__actions";
  for (const button of [moveButton(task, "back"), moveButton(task, "forward"), actionButton(task, "remove", "Delete")]) {
    if (button !== null) {
      actions.append(button);
    }
  }

  item.append(title, actions);
  return item;
}

function column(state: BoardState, status: Status): HTMLElement {
  const section = document.createElement("section");
  section.className = "column";
  const headingId = `column-${status}`;
  section.setAttribute("aria-labelledby", headingId);

  const tasks = tasksIn(state, status);
  const heading = document.createElement("h2");
  heading.id = headingId;
  heading.textContent = `${STATUS_LABELS[status]} (${tasks.length})`;

  const list = document.createElement("ul");
  list.className = "task-list";
  if (tasks.length === 0) {
    const empty = document.createElement("li");
    empty.className = "empty";
    empty.textContent = "Nothing here yet.";
    list.append(empty);
  } else {
    list.append(...tasks.map(taskItem));
  }

  section.append(heading, list);
  return section;
}

export function renderBoard(root: HTMLElement, state: BoardState): void {
  const focused =
    document.activeElement instanceof HTMLElement && root.contains(document.activeElement)
      ? document.activeElement
      : null;
  const focusKey = focused?.dataset.focusKey;
  const taskId = focused?.closest<HTMLElement>("[data-task-id]")?.dataset.taskId;

  root.replaceChildren(...STATUSES.map((status) => column(state, status)));

  if (focusKey !== undefined) {
    const exact = root.querySelector<HTMLElement>(`[data-focus-key="${focusKey}"]`);
    if (exact !== null) {
      exact.focus();
      return;
    }
  }
  if (taskId !== undefined) {
    root.querySelector<HTMLElement>(`[data-task-id="${taskId}"] button`)?.focus();
  }
}
