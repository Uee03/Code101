import { ParseError } from './errors.js';
import { err, ok, type Result } from './result.js';

export type Guard<T> = (value: unknown) => value is T;

export function parseJson<T>(text: string, guard: Guard<T>): Result<T, ParseError> {
  let data: unknown;
  try {
    data = JSON.parse(text);
  } catch (cause) {
    return err(new ParseError('Invalid JSON', text.slice(0, 40), { cause }));
  }
  return guard(data)
    ? ok(data)
    : err(new ParseError('JSON does not match the expected shape', text.slice(0, 40)));
}
