import type { Book } from './books';

export class HttpError extends Error {
  status: number;

  constructor(status: number, message: string) {
    super(message);
    this.name = 'HttpError';
    this.status = status;
  }
}

async function getJson<T>(url: string, signal?: AbortSignal): Promise<T> {
  const response = await fetch(url, { signal, headers: { Accept: 'application/json' } });
  if (!response.ok) {
    throw new HttpError(response.status, `Request failed (${response.status})`);
  }
  if (!response.headers.get('Content-Type')?.includes('application/json')) {
    throw new HttpError(response.status, 'The server did not send JSON');
  }
  return (await response.json()) as T;
}

export function fetchBooks(signal?: AbortSignal): Promise<Book[]> {
  return getJson<Book[]>('/api/books.json', signal);
}
