import type { Equal, Expect } from './testing.js';

// TODO 1: turn camelCase into snake_case at the type level: 'dueDate' -> 'due_date'.
// This placeholder is wrong on purpose.
export type CamelToSnake<S extends string> = S;

// TODO 2: rename every string key of T with CamelToSnake. This placeholder is wrong on purpose.
export type SnakeKeys<T> = T;

export function snake<S extends string>(value: S): CamelToSnake<S> {
  // TODO 3: implement the runtime half so it agrees with the type for the examples below.
  return value as unknown as CamelToSnake<S>;
}

export type ExerciseTests = [
  Expect<Equal<CamelToSnake<'dueDate'>, 'due_date'>>,
  Expect<Equal<CamelToSnake<'assignedToId'>, 'assigned_to_id'>>,
  Expect<Equal<CamelToSnake<'id'>, 'id'>>,
  Expect<Equal<SnakeKeys<{ dueDate: string; id: number }>, { due_date: string; id: number }>>,
];

console.log(snake('dueDate'), snake('assignedToId'));
