export interface ReleaseNote {
  readonly version: string;
  readonly date: string;
  readonly summary: string;
}

export const notes: readonly ReleaseNote[] = [
  { version: "1.2.0", date: "2026-11-02", summary: "Dark mode and a faster search." },
  { version: "1.1.0", date: "2026-09-14", summary: "Keyboard shortcuts for the task list." },
  { version: "1.0.0", date: "2026-06-30", summary: "First public release." },
];
