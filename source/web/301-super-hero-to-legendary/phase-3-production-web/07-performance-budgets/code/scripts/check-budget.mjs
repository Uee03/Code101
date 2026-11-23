import { readdirSync, readFileSync } from 'node:fs';
import { extname, join } from 'node:path';
import { gzipSync } from 'node:zlib';

const limits = JSON.parse(readFileSync(new URL('../budgets.json', import.meta.url), 'utf8')).gzipBytes;
const assets = 'dist/assets';
const totals = { js: 0, css: 0 };

for (const name of readdirSync(assets)) {
  const kind = { '.js': 'js', '.css': 'css' }[extname(name)];
  if (kind === undefined) {
    continue; // source maps and other files are not downloaded by visitors
  }
  const size = gzipSync(readFileSync(join(assets, name)), { level: 9 }).length;
  totals[kind] += size;
  console.log(`${name}: ${size} bytes gzip`);
}

const exceeded = Object.keys(totals).filter((kind) => totals[kind] > limits[kind]);
for (const kind of Object.keys(totals)) {
  console.log(`${kind}: ${totals[kind]} / ${limits[kind]} bytes`);
}

if (exceeded.length > 0) {
  console.error(`Budget exceeded: ${exceeded.join(', ')}`);
  process.exitCode = 1;
} else {
  console.log('Budget OK');
}
