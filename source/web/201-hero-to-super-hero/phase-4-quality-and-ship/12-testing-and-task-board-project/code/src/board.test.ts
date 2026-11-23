import { describe, expect, it } from "vitest";
import { emptyBoard, neighbour, reduceBoard, tasksIn, type BoardState } from "./board";

const sample: BoardState = {
  tasks: [
    { id: 1, title: "Write tests", status: "todo" },
    { id: 2, title: "Ship it", status: "doing" },
  ],
  nextId: 3,
};

describe("reduceBoard", () => {
  it("adds a trimmed task to To do and increments the id", () => {
    const next = reduceBoard(emptyBoard, { type: "added", title: "  Buy milk  " });
    expect(next.tasks).toEqual([{ id: 1, title: "Buy milk", status: "todo" }]);
    expect(next.nextId).toBe(2);
  });

  it("ignores a blank title and returns the same state object", () => {
    expect(reduceBoard(sample, { type: "added", title: "   " })).toBe(sample);
  });

  it("moves a task forward and back", () => {
    const forward = reduceBoard(sample, { type: "moved", id: 1, direction: "forward" });
    expect(tasksIn(forward, "doing").map((task) => task.id)).toEqual([1, 2]);
    const back = reduceBoard(forward, { type: "moved", id: 1, direction: "back" });
    expect(back).toEqual(sample);
  });

  it("does not move a task past the first or last column", () => {
    expect(reduceBoard(sample, { type: "moved", id: 1, direction: "back" })).toBe(sample);
    const done = reduceBoard(sample, { type: "moved", id: 2, direction: "forward" });
    expect(reduceBoard(done, { type: "moved", id: 2, direction: "forward" })).toBe(done);
  });

  it("removes a task and ignores an unknown id", () => {
    const removed = reduceBoard(sample, { type: "removed", id: 1 });
    expect(removed.tasks.map((task) => task.id)).toEqual([2]);
    expect(reduceBoard(sample, { type: "removed", id: 99 })).toBe(sample);
  });
});

describe("neighbour", () => {
  it("returns the adjacent column, or null at the ends", () => {
    expect(neighbour("todo", "forward")).toBe("doing");
    expect(neighbour("todo", "back")).toBeNull();
    expect(neighbour("done", "forward")).toBeNull();
  });
});
