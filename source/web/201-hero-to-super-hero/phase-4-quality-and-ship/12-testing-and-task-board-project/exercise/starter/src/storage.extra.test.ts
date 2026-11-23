import { describe, expect, it } from "vitest";
import { emptyBoard } from "./board";
import { parseBoard } from "./storage";

describe("parseBoard edge cases", () => {
  it("rejects a task with an unknown status", () => {
    // TODO 1: build JSON for one task whose status is "archived" and expect emptyBoard.
  });

  it("rejects a task whose title is not a string", () => {
    // TODO 2: build JSON for one task whose title is the number 5 and expect emptyBoard.
    // Delete the next two lines once you write the real assertion (they only keep the imports in use).
    expect(emptyBoard).toBe(emptyBoard);
    expect(parseBoard).toBeTypeOf("function");
  });

  // TODO 3 (change): write this test FIRST, run it and watch it fail, then fix parseBoard in storage.ts.
  it.todo("rejects two tasks with the same id");
});
