import { openCount, type Filter, type State, type Task } from "./tasks";

function taskRow(task: Task): HTMLLIElement {
  const item = document.createElement("li");
  item.className = "task";

  const label = document.createElement("label");
  const checkbox = document.createElement("input");
  checkbox.type = "checkbox";
  checkbox.checked = task.done;
  checkbox.dataset.action = "toggle";
  checkbox.dataset.id = String(task.id);
  checkbox.dataset.focusKey = `toggle-${task.id}`;
  label.append(checkbox, ` ${task.title}`);

  const remove = document.createElement("button");
  remove.type = "button";
  remove.className = "button button--ghost";
  remove.textContent = "Remove";
  remove.setAttribute("aria-label", `Remove ${task.title}`);
  remove.dataset.action = "remove";
  remove.dataset.id = String(task.id);
  remove.dataset.focusKey = `remove-${task.id}`;

  item.append(label, remove);
  return item;
}

export function renderTasks(list: HTMLElement, tasks: readonly Task[]): void {
  const active = document.activeElement;
  const focusKey = active instanceof HTMLElement && list.contains(active) ? active.dataset.focusKey : undefined;

  list.replaceChildren(...tasks.map(taskRow));

  if (focusKey !== undefined) {
    list.querySelector<HTMLElement>(`[data-focus-key="${focusKey}"]`)?.focus();
  }
}

export function renderSummary(element: HTMLElement, state: State): void {
  element.textContent = `${openCount(state)} open of ${state.tasks.length}`;
}

export function renderFilters(group: HTMLElement, filter: Filter): void {
  for (const button of group.querySelectorAll<HTMLButtonElement>("button[data-filter]")) {
    button.setAttribute("aria-pressed", String(button.dataset.filter === filter));
  }
}

export function appendActivity(log: HTMLElement, message: string): void {
  const item = document.createElement("li");
  item.textContent = message;
  log.prepend(item);
}
