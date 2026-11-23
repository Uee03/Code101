import { readFileSync } from 'node:fs';
import { evaluate, summarize } from './readiness.js';
import { parseReport } from './report.js';

const file = process.argv[2];
if (file === undefined) {
  console.error('Usage: node dist/check-release.js <report.json>');
  process.exit(2);
}

const report = parseReport(readFileSync(file, 'utf8'));
const summary = summarize(evaluate(report), report.version);
console.log(summary.lines.join('\n'));
process.exitCode = summary.ready ? 0 : 1;
