import { serializeHostCookie } from './cookies.js';
import { lint, serialize, strictPolicy, type CspPolicy } from './csp.js';
import { securityHeaders } from './headers.js';

const strict = strictPolicy('TESTNONCE');
console.log(serialize(strict));
console.log(`strict policy findings: ${lint(strict).length}`);

const legacy: CspPolicy = {
  sources: {
    'default-src': ["'self'"],
    'script-src': ["'self'", "'unsafe-inline'", 'https://cdn.example.com'],
    'img-src': ['https:', 'data:'],
  },
};
const findings = lint(legacy);
console.log(`legacy policy findings: ${findings.length}`);
for (const finding of findings) {
  console.log(`- ${finding}`);
}

console.log(serializeHostCookie('session', 'abc123', { maxAgeSeconds: 900, sameSite: 'Lax' }));
console.log(Object.keys(securityHeaders('TESTNONCE', { reportOnly: false, https: true })).join(', '));
