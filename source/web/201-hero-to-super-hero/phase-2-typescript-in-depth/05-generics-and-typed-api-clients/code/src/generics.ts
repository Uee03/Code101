export function firstOr<T>(items: readonly T[], fallback: T): T {
  return items.length > 0 ? items[0] : fallback;
}

export function getProp<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}

export function parseArray<T>(parseItem: (item: unknown) => T): (data: unknown) => T[] {
  return (data) => {
    if (!Array.isArray(data)) {
      throw new Error("Expected an array");
    }
    return data.map((item) => parseItem(item));
  };
}
