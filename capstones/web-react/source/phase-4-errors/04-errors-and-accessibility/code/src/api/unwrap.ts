import type { Versioned } from './types';
import { parseProblem } from './problem';
export function unwrap<T>(result: { data?: T; error?: unknown; response: Response }, cached?: T): T {
  if (result.response.status === 304 && cached !== undefined) return cached;
  if (!result.response.ok) throw parseProblem(result.response, result.error);
  return result.data as T;
}
export function versioned<T>(result: { data?: T; error?: unknown; response: Response }, cached?: Versioned<T>): Versioned<T> {
  if (result.response.status === 304 && cached) return cached;
  const value = unwrap(result); const etag = result.response.headers.get('ETag');
  if (!etag) throw new Error('The API did not expose ETag.');
  return { value, etag };
}
