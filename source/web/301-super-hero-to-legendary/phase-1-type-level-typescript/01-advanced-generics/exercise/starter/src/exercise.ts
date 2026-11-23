import type { Equal, Expect } from './types.js';

// TODO 1: keep only the keys of T whose value type is assignable to V.
// This placeholder is wrong on purpose so the type tests below fail until you replace it.
export type PickByValue<T, V> = T extends V ? T : never;

// TODO 2: make every property optional at every depth. Functions and arrays stay as they are.
// This placeholder is shallow and wrong on purpose.
export type DeepPartial<T> = Partial<T>;

type Settings = {
  theme: 'light' | 'dark';
  pageSize: number;
  filters: { status: string[]; owner: string };
};

export type ExerciseTests = [
  Expect<Equal<PickByValue<{ a: string; b: number; c: string }, string>, { a: string; c: string }>>,
  Expect<
    Equal<
      DeepPartial<Settings>,
      { theme?: 'light' | 'dark'; pageSize?: number; filters?: { status?: string[]; owner?: string } }
    >
  >,
];
