// @vitest-environment jsdom
import { afterEach, describe, expect, it, vi } from "vitest";
import { reduceBoard, type BoardState } from "./board";
import { mountBoard } from "./mount";
import { createStore } from "./store";

const initial: BoardState = {
  tasks: [
    { id: 1, title: "Write tests", status: "todo" },
    { id: 2, title: "Ship it", status: "doing" },
  ],
  nextId: 3,
};

function setup() {
  const root = document.createElement("div");
  document.body.append(root);
  const store = createStore(reduceBoard, initial);
  const announce = vi.fn();
  const afterRemove = vi.fn();
  mountBoard(root, store, { announce, afterRemove });
  return { root, store, announce, afterRemove };
}

function button(root: HTMLElement, action: string, id: number): HTMLButtonElement {
  const found = root.querySelector<HTMLButtonElement>(`button[data-action="${action}"][data-id="${id}"]`);
  if (found === null) {
    throw new Error(`No ${action} button for task ${id}`);
  }
  return found;
}

afterEach(() => {
  document.body.replaceChildren();
});

describe("mountBoard", () => {
  it("renders a column for each status with its task count", () => {
    const { root } = setup();
    const headings = [...root.querySelectorAll("h2")].map((heading) => heading.textContent);
    expect(headings).toEqual(["To do (1)", "In progress (1)", "Done (0)"]);
  });

  it("gives each action button an accessible name that includes the task title", () => {
    const { root } = setup();
    const names = [...root.querySelectorAll("button")].map((item) => item.getAttribute("aria-label"));
    expect(names).toContain("Move to In progress: Write tests");
    expect(names).toContain("Delete: Ship it");
  });

  it("moves a task when its button is clicked and announces it", () => {
    const { root, store, announce } = setup();
    button(root, "move-forward", 1).click();
    expect(store.getState().tasks[0]?.status).toBe("doing");
    expect(announce).toHaveBeenCalledWith('Moved "Write tests" to In progress.');
  });

  it("deletes a task, announces it and calls afterRemove", () => {
    const { root, store, announce, afterRemove } = setup();
    button(root, "remove", 2).click();
    expect(store.getState().tasks).toHaveLength(1);
    expect(announce).toHaveBeenCalledWith('Deleted "Ship it".');
    expect(afterRemove).toHaveBeenCalledTimes(1);
  });

  it("keeps keyboard focus inside the row of the task that moved", () => {
    const { root } = setup();
    const back = button(root, "move-back", 2);
    back.focus();
    back.click();
    expect(document.activeElement?.getAttribute("data-id")).toBe("2");
  });
});
