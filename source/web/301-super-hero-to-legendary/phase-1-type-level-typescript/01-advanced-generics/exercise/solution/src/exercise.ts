import type { Equal, Expect } from './types.js';

export type PickByValue<T, V> = {
  [K in keyof T as T[K] extends V ? K : never]: T[K];
};

export type DeepPartial<T> = T extends (...args: never[]) => unknown
  ? T
  : T extends readonly unknown[]
    ? T
    : T extends object
      ? { [K in keyof T]?: DeepPartial<T[K]> }
      : T;

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
