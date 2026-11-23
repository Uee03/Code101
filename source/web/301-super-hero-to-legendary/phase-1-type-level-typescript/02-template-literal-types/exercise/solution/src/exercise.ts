import type { Equal, Expect } from './testing.js';

// Lowercase the head; put an underscore before any character whose tail starts with a capital.
export type CamelToSnake<S extends string> = S extends `${infer Head}${infer Tail}`
  ? Tail extends Uncapitalize<Tail>
    ? `${Lowercase<Head>}${CamelToSnake<Tail>}`
    : `${Lowercase<Head>}_${CamelToSnake<Tail>}`
  : S;

export type SnakeKeys<T> = {
  [K in keyof T as K extends string ? CamelToSnake<K> : K]: T[K];
};

export function snake<S extends string>(value: S): CamelToSnake<S> {
  const result = value.replace(/[A-Z]/g, (char) => `_${char.toLowerCase()}`);
  return result as unknown as CamelToSnake<S>;
}

export type ExerciseTests = [
  Expect<Equal<CamelToSnake<'dueDate'>, 'due_date'>>,
  Expect<Equal<CamelToSnake<'assignedToId'>, 'assigned_to_id'>>,
  Expect<Equal<CamelToSnake<'id'>, 'id'>>,
  Expect<Equal<SnakeKeys<{ dueDate: string; id: number }>, { due_date: string; id: number }>>,
];

console.log(snake('dueDate'), snake('assignedToId'));
