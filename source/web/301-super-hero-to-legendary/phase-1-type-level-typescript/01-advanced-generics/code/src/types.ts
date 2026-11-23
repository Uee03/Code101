// Compile-time test helpers. They cost nothing at runtime.
export type Equal<A, B> =
  (<T>() => T extends A ? 1 : 2) extends (<T>() => T extends B ? 1 : 2) ? true : false;
export type Expect<T extends true> = T;
export type CanAssign<From, To> = [From] extends [To] ? true : false;

// Mapped type modifiers: remove readonly from every key.
export type Mutable<T> = { -readonly [K in keyof T]: T[K] };

// Flatten an intersection into one readable object type.
export type Prettify<T> = { [K in keyof T]: T[K] } & {};

// Key remapping with a filter: keep only the keys whose value is a function.
export type MethodsOf<T> = {
  [K in keyof T as T[K] extends (...args: never[]) => unknown ? K : never]: T[K];
};

// Recursive conditional type. Functions and arrays are handled before objects.
export type DeepReadonly<T> = T extends (...args: never[]) => unknown
  ? T
  : T extends readonly (infer U)[]
    ? readonly DeepReadonly<U>[]
    : T extends object
      ? { readonly [K in keyof T]: DeepReadonly<T[K]> }
      : T;

// Distributive: a union input is split, mapped member by member, and joined again.
export type ElementOf<T> = T extends readonly (infer U)[] ? U : never;

// Non-distributive: wrapping both sides in a tuple stops the split, so never is testable.
export type IsNever<T> = [T] extends [never] ? true : false;

// Distribute over K to build a union of "at least this key is present" shapes.
export type RequireAtLeastOne<T, K extends keyof T = keyof T> = K extends keyof T
  ? Prettify<Required<Pick<T, K>> & Partial<Omit<T, K>>>
  : never;

// A const type parameter keeps literal types without the caller writing "as const".
export function defineKeys<const T extends readonly string[]>(keys: T): T {
  return keys;
}

// NoInfer stops "value" from widening T: T is inferred from "options" only.
export function oneOf<T extends string>(options: readonly T[], value: NoInfer<T>): T {
  return value;
}

// Explicit variance annotations: out = produces T, in = consumes T.
export interface Producer<out T> {
  get: () => T;
}
export interface Consumer<in T> {
  accept: (value: T) => void;
}
