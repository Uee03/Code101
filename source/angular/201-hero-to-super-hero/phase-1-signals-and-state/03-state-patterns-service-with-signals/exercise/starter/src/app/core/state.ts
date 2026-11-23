import { signal } from '@angular/core';

export interface Versioned<T> {
  value: T;
  etag: string;
}

export interface Page<T> {
  items: T[];
  nextCursor: string | null;
}

export interface ListState<T> {
  items: T[];
  nextCursor: string | null;
  status: 'idle' | 'loading' | 'loadingMore' | 'error';
  error?: unknown;
}

type Loader<T> = (cursor?: string) => Promise<Page<T>>;

// A list that is read page by page with an opaque cursor.
export class CursorList<T> {
  readonly state = signal<ListState<T>>({ items: [], nextCursor: null, status: 'idle' });
  private loader?: Loader<T>;
  private generation = 0;

  async load(loader: Loader<T>): Promise<void> {
    this.loader = loader;
    this.generation++;
    this.state.set({ items: [], nextCursor: null, status: 'loading' });
    await this.fetch(false);
  }

  retry(): Promise<void> {
    return this.loader ? this.load(this.loader) : Promise.resolve();
  }

  async more(): Promise<void> {
    const current = this.state();
    if (current.nextCursor === null || current.status !== 'idle') {
      return;
    }
    this.state.update((s) => ({ ...s, status: 'loadingMore' }));
    await this.fetch(true);
  }

  snapshot(): ListState<T> {
    return this.state();
  }

  restore(snapshot: ListState<T>): void {
    this.state.set(snapshot);
  }

  replace(next: T, isSame: (item: T) => boolean): void {
    this.state.update((s) => ({ ...s, items: s.items.map((item) => (isSame(item) ? next : item)) }));
  }

  append(item: T): void {
    this.state.update((s) => ({ ...s, items: [...s.items, item] }));
  }

  // TODO 1: add a method remove(isSame: (item: T) => boolean): void that keeps only the items for which isSame is false.
  // Use this.state.update with a new object, like replace() does.

  private async fetch(append: boolean): Promise<void> {
    const generation = this.generation;
    const cursor = append ? (this.state().nextCursor ?? undefined) : undefined;
    try {
      const page = await this.loader!(cursor);
      if (generation !== this.generation) {
        return; // a newer load started: this answer is stale
      }
      this.state.update((s) => ({
        items: append ? [...s.items, ...page.items] : page.items,
        nextCursor: page.nextCursor,
        status: 'idle'
      }));
    } catch (error) {
      if (generation === this.generation) {
        this.state.update((s) => ({ ...s, status: 'error', error }));
      }
    }
  }
}

// One Idempotency-Key per user action: the same key (and body) is reused when the user retries after a failure.
export class Creation {
  private pending?: { json: string; key: string };

  async send<T, R>(body: T, submit: (key: string, body: T) => Promise<R>): Promise<R> {
    const json = JSON.stringify(body);
    if (!this.pending || this.pending.json !== json) {
      this.pending = { json, key: crypto.randomUUID() };
    }
    const result = await submit(this.pending.key, body);
    this.pending = undefined;
    return result;
  }
}
