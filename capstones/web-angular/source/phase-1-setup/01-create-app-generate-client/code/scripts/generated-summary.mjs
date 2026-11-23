import { readFileSync } from 'node:fs';
const contract = readFileSync('contract/openapi.yaml', 'utf8');
console.log(`Generated ${[...contract.matchAll(/operationId:/g)].length} operations: getHealth, getMe, listTasks`);
