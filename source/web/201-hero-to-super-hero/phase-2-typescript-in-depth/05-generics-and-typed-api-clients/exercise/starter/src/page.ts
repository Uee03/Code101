import { parseArray } from "./generics.js";

export interface Page<T> {
  items: T[];
  total: number;
}

// TODO 1: return a parser for { items: [...], total: number }.
// Reuse parseArray for the items and throw an Error when total is not a number.
export function parsePage<T>(parseItem: (item: unknown) => T): (data: unknown) => Page<T> {
  return () => {
    throw new Error("TODO 1");
  };
}
