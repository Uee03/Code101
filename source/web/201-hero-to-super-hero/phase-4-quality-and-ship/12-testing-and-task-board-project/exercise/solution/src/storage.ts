import { STATUSES, emptyBoard, type BoardState, type Status, type Task } from "./board";

const KEY = "task-board-v1";

export interface KeyValueStore {
  getItem(key: string): string | null;
  setItem(key: string, value: string): void;
}

function isStatus(value: unknown): value is Status {
  return STATUSES.some((status) => status === value);
}

function isTask(value: unknown): value is Task {
  if (typeof value !== "object" || value === null) {
    return false;
  }
  const { id, title, status } = value as Record<string, unknown>;
  return typeof id === "number" && typeof title === "string" && isStatus(status);
}

function isBoardState(value: unknown): value is BoardState {
  if (typeof value !== "object" || value === null) {
    return false;
  }
  const { tasks, nextId } = value as Record<string, unknown>;
  if (typeof nextId !== "number" || !Array.isArray(tasks) || !tasks.every(isTask)) {
    return false;
  }
  if (new Set(tasks.map((task) => task.id)).size !== tasks.length) {
    return false;
  }
  return tasks.every((task) => task.id < nextId);
}

export function parseBoard(raw: string | null): BoardState {
  if (raw === null) {
    return emptyBoard;
  }
  try {
    const data: unknown = JSON.parse(raw);
    return isBoardState(data) ? data : emptyBoard;
  } catch {
    return emptyBoard;
  }
}

export function loadBoard(storage?: KeyValueStore): BoardState {
  try {
    return parseBoard((storage ?? localStorage).getItem(KEY));
  } catch {
    return emptyBoard;
  }
}

export function saveBoard(state: BoardState, storage?: KeyValueStore): void {
  try {
    (storage ?? localStorage).setItem(KEY, JSON.stringify(state));
  } catch {
    // Storage can be full or blocked. The board keeps working; it just will not be remembered.
  }
}
