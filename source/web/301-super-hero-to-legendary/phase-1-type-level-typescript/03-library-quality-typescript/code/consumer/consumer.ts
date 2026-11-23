import {
  andThen,
  err,
  map,
  match,
  ok,
  type ParseError,
  parseJson,
  type Result,
  unwrapOr,
} from '@code101/result-kit';

type Task = { id: string; title: string };

function isTask(value: unknown): value is Task {
  if (typeof value !== 'object' || value === null) {
    return false;
  }
  const record = value as Record<string, unknown>;
  return typeof record['id'] === 'string' && typeof record['title'] === 'string';
}

export const parsed: Result<Task, ParseError> = parseJson('{"id":"1","title":"x"}', isTask);
export const title: Result<string, ParseError> = map(parsed, (task) => task.title);
export const chained: Result<number, ParseError | string> = andThen(title, (text) =>
  text.length > 0 ? ok(text.length) : err('empty title'),
);
export const label: string = match(chained, {
  ok: (length) => `length ${length}`,
  err: (error) => `failed: ${String(error)}`,
});
export const fallback: string = unwrapOr(title, 'untitled');

// @ts-expect-error the fallback must have the value type: NoInfer stops T widening to string | number
export const wrong = unwrapOr(title, 42);

export function increment(result: Result<number, string>): string {
  if (result.ok) {
    return String(result.value + 1);
  }
  return result.error.toUpperCase();
}
