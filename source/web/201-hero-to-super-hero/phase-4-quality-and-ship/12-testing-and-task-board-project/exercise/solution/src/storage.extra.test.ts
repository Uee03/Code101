import { describe, expect, it } from "vitest";
import { emptyBoard } from "./board";
import { parseBoard } from "./storage";

function boardJson(tasks: unknown[], nextId = 10): string {
  return JSON.stringify({ tasks, nextId });
}

describe("parseBoard edge cases", () => {
  it("rejects a task with an unknown status", () => {
    const json = boardJson([{ id: 1, title: "Old", status: "archived" }]);
    expect(parseBoard(json)).toBe(emptyBoard);
  });

  it("rejects a task whose title is not a string", () => {
    const json = boardJson([{ id: 1, title: 5, status: "todo" }]);
    expect(parseBoard(json)).toBe(emptyBoard);
  });

  it("rejects two tasks with the same id", () => {
    const json = boardJson([
      { id: 1, title: "One", status: "todo" },
      { id: 1, title: "Two", status: "done" },
    ]);
    expect(parseBoard(json)).toBe(emptyBoard);
  });

  it("accepts tasks with different ids", () => {
    const json = boardJson([
      { id: 1, title: "One", status: "todo" },
      { id: 2, title: "Two", status: "done" },
    ]);
    expect(parseBoard(json).tasks).toHaveLength(2);
  });
});
