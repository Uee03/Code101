import type { Result } from './result.js';

// TODO 1: return the first error, otherwise ok(every value in order).
export function all<T, E>(_results: readonly Result<T, E>[]): Result<T[], E> {
  throw new Error('TODO: implement all');
}

// TODO 2: transform only the error side; leave an ok result untouched.
export function mapErr<T, E, F>(_result: Result<T, E>, _fn: (error: E) => F): Result<T, F> {
  throw new Error('TODO: implement mapErr');
}

// TODO 3: export both from src/index.ts, run "npm run build", then run "npm run check:surface".
// It must fail. Read the message, then update api-surface.txt on purpose.
