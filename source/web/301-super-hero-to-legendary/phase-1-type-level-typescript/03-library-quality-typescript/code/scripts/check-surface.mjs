import { readFileSync } from 'node:fs';
import * as lib from '../dist/index.js';

const expected = readFileSync(new URL('../api-surface.txt', import.meta.url), 'utf8')
  .trim()
  .split(/\r?\n/);
const actual = Object.keys(lib).sort();
const added = actual.filter((name) => !expected.includes(name));
const removed = expected.filter((name) => !actual.includes(name));

if (added.length > 0 || removed.length > 0) {
  console.error(`Public API changed. Added: [${added.join(', ')}] Removed: [${removed.join(', ')}]`);
  process.exit(1);
}
console.log(`Public API unchanged: ${actual.length} exports`);
