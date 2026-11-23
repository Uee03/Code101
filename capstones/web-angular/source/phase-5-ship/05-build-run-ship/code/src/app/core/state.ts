import { signal } from '@angular/core';
export interface Versioned<T> { value: T; etag: string; }
export interface ListState<T> {
  items: T[];
  nextCursor: string | null;
  status: 'idle' | 'loading' | 'loadingMore' | 'error';
  error?: unknown;
}
export class CursorList<T> {
  readonly state = signal<ListState<T>>({ items: [], nextCursor: null, status: 'idle' });
  private loader?: (cursor?: string) => Promise<{ items: T[]; page: { nextCursor: string | null } }>;
  private generation = 0;
  async load(loader: NonNullable<CursorList<T>['loader']>): Promise<void> {
    this.loader = loader;
    this.generation++;
    this.state.set({ items: [], nextCursor: null, status: 'loading' });
    await this.fetch(false);
  }
  async more(): Promise<void> {
    if (!this.state().nextCursor || this.state().status === 'loadingMore') return;
    this.state.update(s => ({ ...s, status: 'loadingMore' }));
    await this.fetch(true);
  }
  private async fetch(append: boolean): Promise<void> {
    const generation = this.generation;
    try {
      const page = await this.loader!(append ? this.state().nextCursor! : undefined);
      if (generation !== this.generation) return;
      this.state.update(s => ({ items: append ? [...s.items, ...page.items] : page.items,
        nextCursor: page.page.nextCursor, status: 'idle' }));
    } catch (error) {
      if (append && (error as { status?: number }).status === 400) { await this.load(this.loader!); return; }
      if (generation === this.generation) this.state.update(s => ({ ...s, status: 'error', error }));
      throw error;
    }
  }
}
export class Creation {
  private pending?: { json: string; key: string };
  async send<T, R>(body: T, submit: (key: string, body: T) => Promise<R>): Promise<R> {
    const json = JSON.stringify(body);
    if (!this.pending || this.pending.json !== json) this.pending = { json, key: crypto.randomUUID() };
    const result = await submit(this.pending.key, body);
    this.pending = undefined;
    return result;
  }
}
export function etag<T>(response: { body: T; headers: { get(name: string): string | null } }): Versioned<T> {
  const value = response.headers.get('ETag');
  if (!value) throw new Error('Missing ETag. Check backend CORS Expose-Headers.');
  return { value: response.body, etag: value };
}
