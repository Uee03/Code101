import { createHash } from 'node:crypto';
import type { HashSource } from './csp.js';

// Hash sources suit pages that are static: the hash is the same on every response, so the HTML can be cached.
export function hashSource(scriptText: string): HashSource {
  const digest = createHash('sha256').update(scriptText, 'utf8').digest('base64');
  return `'sha256-${digest}'`;
}
