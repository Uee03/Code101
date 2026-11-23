import type { ReleaseNote } from "./notes";

export function latestVersion(items: readonly ReleaseNote[]): string {
  return items[0]?.version ?? "none";
}
