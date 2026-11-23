import { parseArray } from "./generics.js";

export interface Page<T> {
  items: T[];
  total: number;
}

export function parsePage<T>(parseItem: (item: unknown) => T): (data: unknown) => Page<T> {
  const parseItems = parseArray(parseItem);
  return (data) => {
    if (typeof data !== "object" || data === null) {
      throw new Error("Page must be an object");
    }
    const { items, total } = data as Record<string, unknown>;
    if (typeof total !== "number") {
      throw new Error("Page.total must be a number");
    }
    return { items: parseItems(items), total };
  };
}
