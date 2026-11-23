import { serialize, strictPolicy } from './csp.js';

export interface HeaderOptions {
  reportOnly: boolean;
  https: boolean;
}

export function securityHeaders(nonce: string, options: HeaderOptions): Record<string, string> {
  const headers: Record<string, string> = {
    [options.reportOnly ? 'Content-Security-Policy-Report-Only' : 'Content-Security-Policy']: serialize(strictPolicy(nonce)),
    'Reporting-Endpoints': 'csp="/csp-report"',
    'X-Content-Type-Options': 'nosniff',
    'Referrer-Policy': 'strict-origin-when-cross-origin',
    'Permissions-Policy': 'camera=(), microphone=(), geolocation=()',
    'Cross-Origin-Opener-Policy': 'same-origin',
    // The page contains a one-time nonce, so no cache may store or reuse it.
    'Cache-Control': 'no-store',
  };
  if (options.https) {
    // Only meaningful over HTTPS; browsers ignore it on plain HTTP. No "preload" until you are certain.
    headers['Strict-Transport-Security'] = 'max-age=63072000; includeSubDomains';
  }
  return headers;
}
