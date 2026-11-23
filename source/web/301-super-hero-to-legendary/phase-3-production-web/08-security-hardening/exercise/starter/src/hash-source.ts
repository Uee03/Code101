import type { HashSource } from './csp.js';

// TODO: return the CSP source for an inline script: 'sha256-<base64 of the SHA-256 digest of the exact script text>'.
// The text must be hashed byte for byte (as UTF-8): one extra space gives a different hash.
export function hashSource(scriptText: string): HashSource {
  void scriptText;
  throw new Error('TODO: implement hashSource');
}
