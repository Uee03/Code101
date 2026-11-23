// Counts rows that ran their effect after a commit. A row skipped by memo does not run it.
let committedRows = 0;

export function noteRowCommit(): void {
  committedRows += 1;
}

export function takeRowCommits(): number {
  const value = committedRows;
  committedRows = 0;
  return value;
}
