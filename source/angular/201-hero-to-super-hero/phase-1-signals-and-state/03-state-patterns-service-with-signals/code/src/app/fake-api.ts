import { Injectable, signal } from '@angular/core';
import { Page, Versioned } from './core/state';
import { etagOf, Task, TaskDraft } from './task';

export class ApiError extends Error {
  constructor(
    readonly status: number,
    message: string
  ) {
    super(message);
  }
}

const wait = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));

// A stand-in for a server that lives in memory: slow, paged, versioned, idempotent and sometimes broken.
@Injectable({ providedIn: 'root' })
export class FakeApi {
  readonly failSaves = signal(false);

  private readonly rows: Task[] = Array.from({ length: 7 }, (_, index) => ({
    id: index + 1,
    title: `Task number ${index + 1}`,
    done: false,
    version: 1
  }));
  private readonly replays = new Map<string, Task>();
  private nextId = 8;

  async list(cursor?: string, limit = 3): Promise<Page<Task>> {
    await wait(250);
    const start = cursor === undefined ? 0 : Number(cursor);
    if (!Number.isInteger(start) || start < 0) {
      throw new ApiError(400, 'The cursor is not valid.');
    }
    const end = start + limit;
    return { items: this.rows.slice(start, end).map((row) => ({ ...row })), nextCursor: end < this.rows.length ? String(end) : null };
  }

  async get(id: number): Promise<Versioned<Task>> {
    await wait(150);
    const row = this.find(id);
    return { value: { ...row }, etag: etagOf(row) };
  }

  async patch(id: number, changes: Partial<Pick<Task, 'title' | 'done'>>, ifMatch: string): Promise<Versioned<Task>> {
    await wait(300);
    if (this.failSaves()) {
      throw new ApiError(500, 'The server could not save the change.');
    }
    const row = this.find(id);
    if (etagOf(row) !== ifMatch) {
      throw new ApiError(412, 'The task changed since you read it.');
    }
    Object.assign(row, changes, { version: row.version + 1 });
    return { value: { ...row }, etag: etagOf(row) };
  }

  async create(key: string, draft: TaskDraft): Promise<Task> {
    await wait(300);
    const replay = this.replays.get(key);
    if (replay) {
      return { ...replay };
    }
    const row: Task = { id: this.nextId++, title: draft.title, done: false, version: 1 };
    this.rows.push(row);
    this.replays.set(key, row);
    if (this.failSaves()) {
      throw new ApiError(504, 'The answer was lost on the way back.'); // the task WAS created
    }
    return { ...row };
  }

  // Pretend another user edited this task.
  changeElsewhere(id: number): void {
    const row = this.find(id);
    row.title += ' (edited elsewhere)';
    row.version++;
  }

  private find(id: number): Task {
    const row = this.rows.find((item) => item.id === id);
    if (!row) {
      throw new ApiError(404, 'The task does not exist.');
    }
    return row;
  }
}
