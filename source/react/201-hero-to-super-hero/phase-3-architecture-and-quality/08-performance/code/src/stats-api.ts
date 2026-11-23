export type Stats = {
  reviewers: number;
  averageDays: number;
};

let cached: Promise<Stats> | undefined;

// The promise is created once, outside rendering, so every render receives the same promise.
export function loadStats(): Promise<Stats> {
  cached ??= new Promise<Stats>((resolve) => {
    setTimeout(() => resolve({ reviewers: 4, averageDays: 2.5 }), 1200);
  });
  return cached;
}
