import type { Versioned } from './types';
export function unwrap<T>(result: { data?: T; error?: unknown; response: Response }): T {
  if (!result.response.ok) throw new Error(`API ${result.response.status}`);
  return result.data as T;
}
export function versioned<T>(result: { data?: T; error?: unknown; response: Response }): Versioned<T> {
  const value = unwrap(result);
  const etag = result.response.headers.get('ETag');
  if (!etag) throw new Error('The API did not expose ETag.');
  return { value, etag };
}
