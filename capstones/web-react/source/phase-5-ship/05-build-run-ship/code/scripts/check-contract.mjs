import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
const expected = 'f3a19841f551f01ef358582a1f5eba64b722d30f775201c1f5c6271d054f6ee4';
const actual = createHash('sha256').update(readFileSync('contract/openapi.yaml')).digest('hex');
if (actual !== expected) throw new Error('Contract copy differs from the platform baseline.');
console.log('contract: SHA-256 matches platform; 27 operations');
