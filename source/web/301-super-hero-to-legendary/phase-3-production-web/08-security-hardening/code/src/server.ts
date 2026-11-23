import { randomBytes } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { createServer } from 'node:http';
import { serializeHostCookie } from './cookies.js';
import { securityHeaders } from './headers.js';

const PORT = 8301;
const MAX_REPORT_BYTES = 10_000;
const reportOnly = process.env['CSP_REPORT_ONLY'] === '1';

const publicDir = new URL('../public/', import.meta.url);
const template = readFileSync(new URL('index.html', publicDir), 'utf8');
const script = readFileSync(new URL('app.js', publicDir));
const styles = readFileSync(new URL('style.css', publicDir));

const server = createServer((request, response) => {
  const path = new URL(request.url ?? '/', 'http://localhost').pathname;

  if (request.method === 'GET' && path === '/') {
    // A new, unguessable nonce for every response. Reusing one defeats the purpose.
    const nonce = randomBytes(16).toString('base64');
    response.writeHead(200, {
      'Content-Type': 'text/html; charset=utf-8',
      ...securityHeaders(nonce, { reportOnly, https: false }),
    });
    response.end(template.replaceAll('{{NONCE}}', nonce));
    return;
  }

  if (request.method === 'GET' && path === '/app.js') {
    response.writeHead(200, {
      'Content-Type': 'text/javascript; charset=utf-8',
      'X-Content-Type-Options': 'nosniff',
      'Cache-Control': 'no-cache',
    });
    response.end(script);
    return;
  }

  if (request.method === 'GET' && path === '/style.css') {
    response.writeHead(200, {
      'Content-Type': 'text/css; charset=utf-8',
      'X-Content-Type-Options': 'nosniff',
      'Cache-Control': 'no-cache',
    });
    response.end(styles);
    return;
  }

  if (request.method === 'GET' && path === '/api/session') {
    // Demo only: a real server stores the session and ties this random value to it.
    const sessionId = randomBytes(24).toString('base64url');
    response.writeHead(200, {
      'Content-Type': 'application/json',
      'Set-Cookie': serializeHostCookie('session', sessionId, { maxAgeSeconds: 900, sameSite: 'Lax' }),
      'Cache-Control': 'no-store',
    });
    response.end(JSON.stringify({ sessionIssued: true }));
    return;
  }

  if (request.method === 'POST' && path === '/csp-report') {
    // Reports come from browsers you do not control: bound their size and never render them as HTML.
    let size = 0;
    const chunks: Buffer[] = [];
    request.on('data', (chunk: Buffer) => {
      size += chunk.length;
      if (size <= MAX_REPORT_BYTES) {
        chunks.push(chunk);
      }
    });
    request.on('end', () => {
      if (size > MAX_REPORT_BYTES) {
        response.writeHead(413).end();
        return;
      }
      console.log('csp-report', JSON.stringify(Buffer.concat(chunks).toString('utf8').slice(0, 500)));
      response.writeHead(204).end();
    });
    return;
  }

  response.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' }).end('Not found');
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`Listening on http://127.0.0.1:${PORT} (CSP ${reportOnly ? 'report-only' : 'enforced'})`);
});
