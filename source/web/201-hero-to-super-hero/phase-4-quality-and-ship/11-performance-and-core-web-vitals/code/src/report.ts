export function buildReport(count: number): string {
  const rows = Array.from({ length: count }, (_, index) => `Picture ${index + 1}: loaded lazily`);
  return rows.join("\n");
}
