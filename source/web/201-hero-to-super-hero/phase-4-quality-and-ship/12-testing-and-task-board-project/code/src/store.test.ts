import { describe, expect, it, vi } from "vitest";
import { createStore } from "./store";

function counter(state: number, action: "inc" | "noop"): number {
  return action === "inc" ? state + 1 : state;
}

describe("createStore", () => {
  it("starts with the initial state and applies actions", () => {
    const store = createStore(counter, 0);
    expect(store.getState()).toBe(0);
    store.dispatch("inc");
    expect(store.getState()).toBe(1);
  });

  it("notifies subscribers only when the state changes", () => {
    const store = createStore(counter, 0);
    const listener = vi.fn();
    store.subscribe(listener);
    store.dispatch("noop");
    expect(listener).not.toHaveBeenCalled();
    store.dispatch("inc");
    expect(listener).toHaveBeenCalledTimes(1);
    expect(listener).toHaveBeenCalledWith(1);
  });

  it("stops notifying after unsubscribe", () => {
    const store = createStore(counter, 0);
    const listener = vi.fn();
    const unsubscribe = store.subscribe(listener);
    unsubscribe();
    store.dispatch("inc");
    expect(listener).not.toHaveBeenCalled();
  });
});
