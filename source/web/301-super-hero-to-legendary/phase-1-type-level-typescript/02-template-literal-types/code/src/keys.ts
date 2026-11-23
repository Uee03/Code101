import type { CamelizeKeys, SnakeToCamel } from './route-types.js';

export function camelize<S extends string>(value: S): SnakeToCamel<S> {
  const result = value.replace(/_([a-z0-9])/g, (_match, char: string) => char.toUpperCase());
  // Boundary cast: the type and this regex must agree. type-tests.ts and index.ts check that.
  return result as unknown as SnakeToCamel<S>;
}

export function camelizeKeys<T extends Record<string, unknown>>(input: T): CamelizeKeys<T> {
  const output: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(input)) {
    output[camelize(key)] = value;
  }
  return output as unknown as CamelizeKeys<T>;
}
