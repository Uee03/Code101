import { readFileSync } from 'node:fs';

const manifest = JSON.parse(readFileSync('package.json', 'utf8'));
const problems = [];
let checked = 0;

for (const section of ['dependencies', 'devDependencies', 'optionalDependencies']) {
  for (const [name, range] of Object.entries(manifest[section] ?? {})) {
    checked += 1;
    if (!/^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?$/.test(range)) {
      problems.push(`${section}.${name} is "${range}": pin an exact version`);
    }
  }
}

// These scripts run code on every install, for every developer and every CI run.
for (const hook of ['preinstall', 'install', 'postinstall', 'prepare']) {
  if (manifest.scripts?.[hook] !== undefined) {
    problems.push(`scripts.${hook} runs code on every install`);
  }
}

if (problems.length > 0) {
  console.error(problems.join('\n'));
  process.exitCode = 1;
} else {
  console.log(`Package policy OK: ${checked} dependencies pinned`);
}
