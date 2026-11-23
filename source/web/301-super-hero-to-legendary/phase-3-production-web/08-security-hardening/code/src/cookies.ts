export interface CookieOptions {
  maxAgeSeconds: number;
  sameSite: 'Strict' | 'Lax';
}

// The __Host- prefix makes the browser refuse the cookie unless it is Secure, has Path=/ and has no Domain.
// HttpOnly keeps it out of JavaScript, so an XSS bug cannot read it.
export function serializeHostCookie(name: string, value: string, options: CookieOptions): string {
  if (!/^[A-Za-z0-9_-]+$/.test(name)) {
    throw new Error(`Invalid cookie name: ${name}`);
  }
  if (!/^[A-Za-z0-9._~+/=-]*$/.test(value)) {
    throw new Error('Cookie value must be base64url-like: encode it first');
  }
  return [
    `__Host-${name}=${value}`,
    'Path=/',
    'Secure',
    'HttpOnly',
    `SameSite=${options.sameSite}`,
    `Max-Age=${options.maxAgeSeconds}`,
  ].join('; ');
}
