import { STATUS_LABELS, type BoardAction, type BoardState } from "./board";
import { renderBoard } from "./render";
import type { Store } from "./store";

export interface BoardHooks {
  announce(message: string): void;
  afterRemove(): void;
}

type BoardStore = Store<BoardState, BoardAction>;

function handleAction(store: BoardStore, hooks: BoardHooks, action: string | undefined, id: number): void {
  const task = store.getState().tasks.find((item) => item.id === id);
  if (task === undefined) {
    return;
  }
  if (action === "move-forward" || action === "move-back") {
    store.dispatch({ type: "moved", id, direction: action === "move-forward" ? "forward" : "back" });
    const moved = store.getState().tasks.find((item) => item.id === id);
    if (moved !== undefined) {
      hooks.announce(`Moved "${moved.title}" to ${STATUS_LABELS[moved.status]}.`);
    }
  } else if (action === "remove") {
    store.dispatch({ type: "removed", id });
    hooks.announce(`Deleted "${task.title}".`);
    hooks.afterRemove();
  }
}

export function mountBoard(root: HTMLElement, store: BoardStore, hooks: BoardHooks): void {
  store.subscribe((state) => renderBoard(root, state));
  renderBoard(root, store.getState());

  root.addEventListener("click", (event) => {
    const target = event.target;
    if (!(target instanceof Element)) {
      return;
    }
    const button = target.closest<HTMLButtonElement>("button[data-action]");
    if (button === null) {
      return;
    }
    handleAction(store, hooks, button.dataset.action, Number(button.dataset.id));
  });
}
