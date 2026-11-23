import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';

const groups = ['packages', 'apps'];
const workspaces = [];

for (const group of groups) {
  if (!existsSync(group)) {
    continue;
  }
  for (const entry of readdirSync(group, { withFileTypes: true })) {
    const manifestPath = join(group, entry.name, 'package.json');
    if (entry.isDirectory() && existsSync(manifestPath)) {
      const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));
      workspaces.push({
        name: manifest.name,
        dir: `${group}/${entry.name}`,
        dependencies: Object.keys({ ...manifest.dependencies, ...manifest.devDependencies }),
      });
    }
  }
}

const changed = process.argv.slice(2).map((file) => file.replaceAll('\\', '/'));
const affected = new Set();

// A change outside every workspace (root config, lockfile) is treated as "everything".
const touchesRoot = changed.some((file) => !groups.some((group) => file.startsWith(`${group}/`)));
for (const workspace of workspaces) {
  if (touchesRoot || changed.some((file) => file.startsWith(`${workspace.dir}/`))) {
    affected.add(workspace.name);
  }
}

// Add every workspace that depends on an affected one, repeatedly, until nothing new appears.
let grew = true;
while (grew) {
  grew = false;
  for (const workspace of workspaces) {
    if (!affected.has(workspace.name) && workspace.dependencies.some((name) => affected.has(name))) {
      affected.add(workspace.name);
      grew = true;
    }
  }
}

console.log(affected.size === 0 ? 'No workspaces affected' : [...affected].sort().join('\n'));
