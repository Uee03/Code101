import { describe, expect, it } from "vitest";
import { emptyBoard, type BoardState } from "./board";
import { loadBoard, parseBoard, saveBoard, type KeyValueStore } from "./storage";

function fakeStorage(): KeyValueStore {
  const data = new Map<string, string>();
  return {
    getItem: (key) => data.get(key) ?? null,
    setItem: (key, value) => {
      data.set(key, value);
    },
  };
}

const board: BoardState = {
  tasks: [{ id: 1, title: "Saved", status: "doing" }],
  nextId: 2,
};

describe("parseBoard", () => {
  it("returns an empty board when nothing is stored", () => {
    expect(parseBoard(null)).toBe(emptyBoard);
  });

  it("returns an empty board for text that is not JSON", () => {
    expect(parseBoard("{not json")).toBe(emptyBoard);
  });

  it("returns an empty board for the wrong shape", () => {
    expect(parseBoard(JSON.stringify({ tasks: [{ id: "1" }], nextId: 2 }))).toBe(emptyBoard);
    expect(parseBoard(JSON.stringify({ tasks: [], nextId: "2" }))).toBe(emptyBoard);
  });

  it("returns an empty board when a task id is not below nextId", () => {
    const stale = { tasks: [{ id: 5, title: "x", status: "todo" }], nextId: 5 };
    expect(parseBoard(JSON.stringify(stale))).toBe(emptyBoard);
  });

  it("accepts a valid board", () => {
    expect(parseBoard(JSON.stringify(board))).toEqual(board);
  });
});

describe("saveBoard and loadBoard", () => {
  it("round-trips through storage", () => {
    const storage = fakeStorage();
    saveBoard(board, storage);
    expect(loadBoard(storage)).toEqual(board);
  });

  it("survives a storage that throws", () => {
    const broken: KeyValueStore = {
      getItem: () => {
        throw new Error("blocked");
      },
      setItem: () => {
        throw new Error("quota");
      },
    };
    expect(() => saveBoard(board, broken)).not.toThrow();
    expect(loadBoard(broken)).toBe(emptyBoard);
  });
});
