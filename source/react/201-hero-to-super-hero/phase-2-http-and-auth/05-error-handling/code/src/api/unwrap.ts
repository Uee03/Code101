import { parseProblem } from './problem';

type Result<T> = { data?: T; error?: unknown; response: Response };

export function unwrap<T>(result: Result<T>): T {
  if (!result.response.ok) {
    throw parseProblem(result.response, result.error);
  }
  return result.data as T;
}
