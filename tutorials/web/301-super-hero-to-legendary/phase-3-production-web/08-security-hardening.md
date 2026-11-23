---
track: web
level: 301
phase: 3
phase_name: production-web
lesson: 08
title: "Security hardening"
time: 150 min
prerequisites: [web-201.10, web-301.05, web-301.06]
versions: { node: "26.13.1", npm: "11.20.0", typescript: "7.0.2", "@types/node": "26.6.6", "actions/checkout": "v7.0.1", "actions/setup-node": "v7.1.0", "actions/dependency-review-action": "v5.0.1" }
verified: not yet run
source: source/web/301-super-hero-to-legendary/phase-3-production-web/08-security-hardening/
assets: []
---

# 08. Security hardening

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- build and lint a strict Content-Security-Policy (nonce plus `strict-dynamic`) and roll it out safely in report-only mode first
- explain what Trusted Types prevent, write a policy and say what breaks when you turn them on
- decide where an access token lives (memory, cookie through a backend, storage) and defend the choice
- harden the supply chain: exact versions, no install scripts, signature and provenance checks, dependency review, pinned CI actions

## Recap
1. In lesson 04 the generated documentation page used no inline styles. Why does that matter for this lesson?
   <details><summary>Answer</summary>A strict CSP blocks inline styles and scripts; pages built without them need no exceptions.</details>
2. In lesson 05 the CI step passed `github.base_ref` through `env`. What attack does that prevent?
   <details><summary>Answer</summary>Script injection: expression values are pasted into the script text, so an attacker-controlled value (a branch name) could add commands. An environment variable is data.</details>
3. In lesson 06 the client read the token through a callback. What question did we postpone?
   <details><summary>Answer</summary>Where the token is stored. This lesson answers it.</details>

## Why it matters
A web application runs your code on a stranger's machine, next to code you did not write (extensions, ads, dependencies), handling their credentials. Three failures cause most real incidents: an attacker's script runs in your page (cross-site scripting, XSS), an attacker's code arrives in your build (supply chain), or a token leaves the browser. Defence is layered: no single control is enough, and each layer fails differently. Security is a trade-off with convenience; at level 301 you name both sides.

## What you will build
A small Node server and page (the "security lab") plus the configuration around it:
1. A typed CSP builder, a policy linter and the security headers, all printed deterministically so you can read and test them.
2. A page that tries four dangerous things (inline event handler, `innerHTML`, `eval`) under an enforced policy, and a Trusted Types policy that makes one of them safe.
3. A `__Host-` session cookie serializer.
4. A package-policy check, `.npmrc`, a security workflow with pinned actions, and a Dependabot configuration.

## Before you start
- Lessons 01 to 07 finished (Node 26.13.1, npm 11.20.0, TypeScript 7.0.2). Chrome, Edge or Firefox (Trusted Types are available in all current major engines since early 2026; check MDN for your support matrix).
- Builds on Web 201 lesson [10 Web security basics](../../201-hero-to-super-hero/phase-4-quality-and-ship/10-web-security-basics.md) (XSS and safe DOM APIs, a first CSP header, CORS). This lesson goes deeper on CSP, adds Trusted Types, token storage and the supply chain.
- Time: 120 to 150 minutes. Break after step 7.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/web/301-super-hero-to-legendary/phase-3-production-web/08-security-hardening/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- No `package-lock.json` is shipped; `npm install` creates it. The `.npmrc` in this project sets `ignore-scripts=true`: the two dependencies need no install scripts.
- Security note about this lesson itself: the page deliberately contains dangerous code (an `innerHTML` sink, `eval`). It listens on `127.0.0.1` only and handles no real data. Do not copy `app.js` into a real application, and do not expose the server beyond your machine.

## Steps

### Step 1. Create the project
```text
mkdir security-lab
cd security-lab
mkdir src
mkdir public
mkdir scripts
```

### Step 2. Write package.json, .npmrc and tsconfig.json
**File: `package.json`**
```json
{
  "name": "web301-08-security-hardening",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "build": "tsc",
    "policy": "tsc && node dist/print-policy.js",
    "serve": "tsc && node dist/server.js",
    "check:packages": "node scripts/check-package-policy.mjs"
  },
  "engines": {
    "node": ">=26.13.1",
    "npm": ">=11.20.0"
  },
  "devDependencies": {
    "@types/node": "26.6.6",
    "typescript": "7.0.2"
  }
}
```
**File: `.npmrc`**
```text
ignore-scripts=true
save-exact=true
engine-strict=true
audit-level=high
fund=false
```
Each line is a supply-chain control:
- `ignore-scripts=true`: npm does not run `preinstall`, `install` or `postinstall` scripts of **any** dependency (including transitive ones). Install scripts are the most common way a malicious package executes code on your machine. The cost: packages that need a build step at install (some that download native binaries) will not work until you run their step on purpose. Allow those one by one.
- `save-exact=true`: `npm install x` records `1.2.3`, not `^1.2.3`. A new release can never enter without a reviewed change.
- `engine-strict=true`: a wrong Node version is an error, not a warning.
- `audit-level=high`: `npm audit` fails only for high or critical findings, so it does not become noise.
- `fund=false`: silences the funding message in logs.

**File: `tsconfig.json`** (identical to lesson 01, step 3)
```json
{
  "compilerOptions": {
    "target": "ES2023",
    "lib": ["ES2023"],
    "module": "nodenext",
    "moduleResolution": "nodenext",
    "rootDir": "src",
    "outDir": "dist",
    "types": ["node"],
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitOverride": true,
    "noFallthroughCasesInSwitch": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "verbatimModuleSyntax": true,
    "isolatedModules": true,
    "noEmitOnError": true,
    "skipLibCheck": true
  },
  "include": ["src/**/*.ts"]
}
```
Install:
```text
npm install --no-audit --no-fund
```

### Step 3. Write the CSP builder and linter
**File: `src/csp.ts`**
```ts
export type Keyword =
  | "'self'"
  | "'none'"
  | "'strict-dynamic'"
  | "'unsafe-inline'"
  | "'unsafe-eval'"
  | "'wasm-unsafe-eval'"
  | "'report-sample'";
export type NonceSource = `'nonce-${string}'`;
export type HashSource = `'sha256-${string}'` | `'sha384-${string}'` | `'sha512-${string}'`;
export type SchemeSource = 'https:' | 'http:' | 'data:' | 'blob:';
export type HostSource = `https://${string}`;
export type Source = Keyword | NonceSource | HashSource | SchemeSource | HostSource;

export type SourceDirective =
  | 'default-src'
  | 'script-src'
  | 'script-src-elem'
  | 'script-src-attr'
  | 'style-src'
  | 'img-src'
  | 'font-src'
  | 'connect-src'
  | 'media-src'
  | 'frame-src'
  | 'worker-src'
  | 'manifest-src'
  | 'object-src'
  | 'base-uri'
  | 'form-action'
  | 'frame-ancestors';

// A fixed order makes the header identical on every run, which makes diffs and tests meaningful.
const DIRECTIVE_ORDER: readonly SourceDirective[] = [
  'default-src',
  'script-src',
  'script-src-elem',
  'script-src-attr',
  'style-src',
  'img-src',
  'font-src',
  'connect-src',
  'media-src',
  'frame-src',
  'worker-src',
  'manifest-src',
  'object-src',
  'base-uri',
  'form-action',
  'frame-ancestors',
];

export interface CspPolicy {
  sources: Partial<Record<SourceDirective, readonly Source[]>>;
  requireTrustedTypesForScript?: boolean;
  trustedTypes?: readonly string[];
  reportTo?: string;
}

export function nonceSource(nonce: string): NonceSource {
  return `'nonce-${nonce}'`;
}

export function serialize(policy: CspPolicy): string {
  const parts: string[] = [];
  for (const directive of DIRECTIVE_ORDER) {
    const values = policy.sources[directive];
    if (values !== undefined) {
      parts.push([directive, ...values].join(' '));
    }
  }
  if (policy.requireTrustedTypesForScript === true) {
    parts.push("require-trusted-types-for 'script'");
  }
  if (policy.trustedTypes !== undefined) {
    parts.push(['trusted-types', ...(policy.trustedTypes.length > 0 ? policy.trustedTypes : ["'none'"])].join(' '));
  }
  if (policy.reportTo !== undefined) {
    parts.push(`report-to ${policy.reportTo}`);
  }
  return parts.join('; ');
}

// The strict policy from web.dev: a per-response nonce plus 'strict-dynamic', everything else closed.
export function strictPolicy(nonce: string): CspPolicy {
  return {
    sources: {
      'default-src': ["'none'"],
      'script-src': [nonceSource(nonce), "'strict-dynamic'"],
      'style-src': ["'self'"],
      'img-src': ["'self'", 'data:'],
      'font-src': ["'self'"],
      'connect-src': ["'self'"],
      'object-src': ["'none'"],
      'base-uri': ["'none'"],
      'form-action': ["'self'"],
      'frame-ancestors': ["'none'"],
    },
    requireTrustedTypesForScript: true,
    trustedTypes: ['app'],
    reportTo: 'csp',
  };
}

// A reviewer in code form: it names the weaknesses of a policy in plain language.
export function lint(policy: CspPolicy): string[] {
  const findings: string[] = [];
  const scriptSources = policy.sources['script-src'] ?? policy.sources['default-src'] ?? [];
  const hasNonceOrHash = scriptSources.some((source) => source.startsWith("'nonce-") || source.startsWith("'sha"));

  if (scriptSources.length === 0) {
    findings.push('script-src and default-src are both missing: scripts are unrestricted');
  }
  if (scriptSources.includes("'unsafe-inline'") && !hasNonceOrHash) {
    findings.push("script-src allows 'unsafe-inline': an injected inline script would run");
  }
  if (scriptSources.includes("'unsafe-eval'")) {
    findings.push("script-src allows 'unsafe-eval': strings can be turned into code");
  }
  for (const source of scriptSources) {
    if (source.includes('*') || /^(https?|data|blob):$/.test(source)) {
      findings.push(`script-src allows ${source}: any script from that scheme or host pattern is trusted`);
    }
  }
  const objectSources = policy.sources['object-src'] ?? policy.sources['default-src'];
  if (objectSources === undefined || !objectSources.includes("'none'")) {
    findings.push("object-src is not restricted (use 'none')");
  }
  if (policy.sources['base-uri'] === undefined) {
    findings.push("base-uri is not restricted (use 'none' or 'self')");
  }
  if (policy.sources['frame-ancestors'] === undefined) {
    findings.push('frame-ancestors is missing (clickjacking protection)');
  }
  return findings;
}
```
Concepts, in the order the compiler and the browser meet them:
- **Typed sources.** `Source` is a union of keywords and template literal types (lesson 02). `"'sef'"` is a compile error; so is `'http://x'` where only `https://${string}` is allowed. A CSP typo normally fails *silently*: the browser ignores an unknown source, and your policy is weaker than you believe.
- **`default-src 'none'`** denies everything not listed: you must name each thing the page needs. This is the safest starting point, because forgetting a directive blocks something visible (a bug you notice) instead of allowing something invisible.
- **`script-src 'nonce-…' 'strict-dynamic'`.** A **nonce** is a random value, new for every response, repeated in the policy and on each `<script nonce="…">` tag; only scripts carrying it run, so an injected script (which cannot know the nonce) does not. `'strict-dynamic'` says "trust scripts that a trusted script loads", so a bundler's dynamic imports work without listing hosts. With `strict-dynamic`, browsers ignore host allow-lists and `'self'`, which is intended: allow-lists are famous for being bypassable (a trusted host that serves a JSONP endpoint or an old library becomes the attacker's script).
- **`object-src 'none'` and `base-uri 'none'`.** Without them an injected `<object>` or `<base href>` can bypass an otherwise strict policy (a `<base>` changes where relative script URLs load from).
- **`frame-ancestors 'none'`** forbids other sites framing yours (clickjacking). It replaces the older `X-Frame-Options`, and it cannot be set in a `<meta>` tag, only as a header.
- **`require-trusted-types-for 'script'` and `trusted-types app`**: see step 6.
- **`report-to csp`** names a reporting endpoint defined by the `Reporting-Endpoints` header (next step).
- `lint` is not a security tool you ship; it is a way to make a review checklist executable. Its output on a weak policy is in the expected output below.

### Step 4. Write the headers and the cookie serializer
**File: `src/headers.ts`**
```ts
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
```
What each header does and what it costs:

| Header | Purpose | Cost or trap |
|---|---|---|
| `Content-Security-Policy` | Limits what the page may load and run | Breaks anything inline or third-party; roll out in report-only first |
| `Content-Security-Policy-Report-Only` | Same policy, reports violations but blocks nothing | Not protection: it shows you what *would* break |
| `Reporting-Endpoints` | Names where `report-to csp` sends reports | The endpoint receives untrusted data (see server) |
| `X-Content-Type-Options: nosniff` | The browser must trust the declared content type | A wrong `Content-Type` now breaks scripts and styles instead of being guessed |
| `Referrer-Policy` | Controls what URL leaks to other sites | A stricter value can break analytics that rely on the full referrer |
| `Permissions-Policy` | Turns off browser features you never use | Embedded content needing a feature stops working |
| `Cross-Origin-Opener-Policy: same-origin` | Isolates your window from cross-origin popups | Breaks some OAuth popup flows that need `window.opener` |
| `Cache-Control: no-store` | No cache stores the page | Costs speed; required because the nonce must not be reused |
| `Strict-Transport-Security` | Browser uses HTTPS for the site from now on | A mistake (an HTTPS-less subdomain, or a `preload` too early) is hard to undo. The two-year value in the code is the **end state**; begin a real rollout with a short `max-age` (minutes, then days) and raise it in steps |

**File: `src/cookies.ts`**
```ts
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
```
The function refuses names and values that contain characters which could add attributes (a `;` or a newline in a value is cookie injection). `SameSite=Lax` means the browser does not send the cookie on cross-site sub-requests (images, frames, fetches) and on cross-site `POST` navigations, which blocks most cross-site request forgery (CSRF); `Strict` also withholds it on top-level links from other sites, which can log users out when they click a link in an email.

### Step 5. Print the policy and read it
**File: `src/print-policy.ts`**
```ts
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
```
Run it:
```text
npm run policy --silent
```
Expected output (not yet run; the first line is one long line):
```text
default-src 'none'; script-src 'nonce-TESTNONCE' 'strict-dynamic'; style-src 'self'; img-src 'self' data:; font-src 'self'; connect-src 'self'; object-src 'none'; base-uri 'none'; form-action 'self'; frame-ancestors 'none'; require-trusted-types-for 'script'; trusted-types app; report-to csp
strict policy findings: 0
legacy policy findings: 4
- script-src allows 'unsafe-inline': an injected inline script would run
- object-src is not restricted (use 'none')
- base-uri is not restricted (use 'none' or 'self')
- frame-ancestors is missing (clickjacking protection)
__Host-session=abc123; Path=/; Secure; HttpOnly; SameSite=Lax; Max-Age=900
Content-Security-Policy, Reporting-Endpoints, X-Content-Type-Options, Referrer-Policy, Permissions-Policy, Cross-Origin-Opener-Policy, Cache-Control, Strict-Transport-Security
```
Read the first line one directive at a time and say what each one forbids. The "legacy" policy is typical of what many sites ship: `'self'` plus `unsafe-inline` plus a CDN host. It looks restrictive and is not: an injected inline script runs, and any script on `cdn.example.com` (including ones the attacker can get hosted there) is trusted.

### Step 6. Write the server and the page
**File: `src/server.ts`**
```ts
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
```
Points that are easy to miss:
- The server listens on **`127.0.0.1`**, not `0.0.0.0`, so only your machine can reach it. The default for a development server should be the narrowest.
- The nonce changes per request, so the HTML must never be cached: that is why `securityHeaders` sets `Cache-Control: no-store`. A cached page with a fixed nonce gives every visitor the same nonce, which an attacker can read and reuse.
- Reports are **untrusted input from strangers**. The handler limits the size (10,000 bytes), and prints the text as an escaped JSON string (so a report cannot forge extra log lines with newlines). In production you would also rate-limit the endpoint and aggregate by violated directive instead of storing everything.
- `/api/session` sets the `__Host-` cookie. It is a demo: it stores nothing.

**File: `public/index.html`**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Security lab</title>
  <link rel="stylesheet" href="/style.css">
</head>
<body>
  <main>
    <h1>Security lab</h1>
    <p>Each button tries something a strict policy should stop or tame. Open the browser console to see the reports.</p>
    <ul>
      <li><button id="inline-handler" type="button">Add an inline event handler</button></li>
      <li><button id="raw-html" type="button">Write untrusted text with innerHTML</button></li>
      <li><button id="safe-html" type="button">Write untrusted text through the policy</button></li>
      <li><button id="run-eval" type="button">Call eval</button></li>
    </ul>
    <output id="result" role="status">Nothing tried yet.</output>
  </main>
  <script nonce="{{NONCE}}" src="/app.js"></script>
</body>
</html>
```
`{{NONCE}}` is replaced by the server with the per-response nonce. The page has no inline script, no inline style and no `on…` attributes: it can run under a policy with no `unsafe-inline` at all.

**File: `public/style.css`**
```css
body {
  font-family: system-ui, sans-serif;
  margin: 2rem;
}

main {
  max-width: 40rem;
}

li {
  margin-block: 0.5rem;
}

button {
  padding: 0.5rem 1rem;
}

output {
  display: block;
  margin-top: 1rem;
  padding: 0.5rem;
  border: 1px solid;
}
```
**File: `public/app.js`**
```js
const result = document.querySelector('#result');
const untrusted = '<img src=x onerror="alert(1)">hello';

function escapeHtml(text) {
  return text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}

// The only policy the CSP allows ("trusted-types app"). A real one would sanitise with a library
// instead of escaping everything, so that some safe markup survives.
const policy = window.trustedTypes?.createPolicy('app', {
  createHTML: (input) => escapeHtml(input),
});

function show(message) {
  result.textContent = message;
}

document.querySelector('#inline-handler').addEventListener('click', () => {
  try {
    const probe = document.createElement('button');
    probe.setAttribute('onclick', 'document.title = "pwned"');
    document.body.append(probe);
    probe.click();
    probe.remove();
    show(document.title === 'pwned' ? 'Inline handler ran: the policy is NOT protecting you' : 'Inline handler did not run');
  } catch (error) {
    show(`Inline handler refused: ${error.name}`);
  }
});

document.querySelector('#raw-html').addEventListener('click', () => {
  try {
    result.innerHTML = untrusted;
  } catch (error) {
    show(`innerHTML refused: ${error.name}`);
  }
});

document.querySelector('#safe-html').addEventListener('click', () => {
  try {
    result.innerHTML = policy ? policy.createHTML(untrusted) : escapeHtml(untrusted);
  } catch (error) {
    show(`Policy refused: ${error.name}`);
  }
});

document.querySelector('#run-eval').addEventListener('click', () => {
  try {
    show(`eval returned ${eval('1 + 1')}`);
  } catch (error) {
    show(`eval refused: ${error.name}`);
  }
});

document.addEventListener('securitypolicyviolation', (event) => {
  console.log(`[csp] ${event.disposition} ${event.violatedDirective} blocked ${event.blockedURI || 'inline'}`);
});
```
Trusted Types in four sentences. **Injection sinks** are DOM APIs that turn a string into code or markup (`innerHTML`, `setAttribute('onclick', …)`, `eval`, `script.src`). With `require-trusted-types-for 'script'` the browser refuses a plain string at those sinks: you must pass a *typed object* (`TrustedHTML`, `TrustedScript`, `TrustedScriptURL`) that only a **policy** can create. `trusted-types app` allows exactly one policy named `app`, so only code that can call `createPolicy('app', …)` (once) can produce trusted values: the dangerous places shrink from "every `innerHTML` in the code base and in every dependency" to "this one function". Here the policy escapes everything, so the untrusted string is displayed as text. A real policy sanitises with a maintained library such as DOMPurify (which supports Trusted Types) so that harmless markup survives.

### Step 7. Run the lab
```text
npm run serve
```
Expected output: the TypeScript build prints nothing, then:
```text
Listening on http://127.0.0.1:8301 (CSP enforced)
```
Open `http://127.0.0.1:8301/` and the browser console (F12). **What to expect from the code** (verify each in your browser; I have not run it):

| Button | Enforced policy | In report-only mode |
|---|---|---|
| Add an inline event handler | Refused (`TypeError` from Trusted Types, because `setAttribute('onclick', string)` is a script sink) and a violation line in the console | The handler runs and the page title changes, with only a report: report-only is not protection |
| innerHTML with untrusted text | Refused (`TypeError`) | The string becomes markup; the `<img>` is inserted |
| Through the policy | The text is shown literally, including the angle brackets | Same |
| Call eval | Refused (an `EvalError` from CSP or a `TypeError` from Trusted Types: read the name shown) | `eval` runs and shows `eval returned 2`, with a report |

The console lines starting `[csp]` come from the `securitypolicyviolation` event. Stop the server (Ctrl+C), start it with `CSP_REPORT_ONLY=1` (macOS and Linux: `CSP_REPORT_ONLY=1 npm run serve`; Windows PowerShell: `$env:CSP_REPORT_ONLY='1'; npm run serve`), reload, and repeat. Also open `http://127.0.0.1:8301/api/session` and look at the cookie in DevTools, Application, Cookies: you should see `__Host-session` with the Secure, HttpOnly and SameSite columns set. Browsers treat `localhost` as a secure context, so a `Secure` cookie is accepted on it in Chrome, Edge and Firefox; Safari does not, so test cookies over real HTTPS.

**Rolling out a policy on a real site**
1. Ship `Content-Security-Policy-Report-Only` with the strict policy. Collect reports for a week or two (more if traffic is low).
2. Group reports by violated directive and blocked URI. Fix first-party code (remove inline handlers, add nonces). Third-party items: remove, replace or load through a nonce'd loader.
3. Switch to the enforcing header for a small share of traffic or one route first; keep report-only running alongside with a stricter candidate.
4. Alert on a rise in reports, because it is either an attack or a deployment that broke the policy.

### Step 8. Write the package policy check and the workflows
**File: `scripts/check-package-policy.mjs`**
```js
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
```
```text
npm run check:packages --silent
```
Expected output:
```text
Package policy OK: 2 dependencies pinned
```
Try changing `"typescript": "7.0.2"` to `"^7.0.2"` and run it again: it should print `devDependencies.typescript is "^7.0.2": pin an exact version` and exit with code 1. Undo.

**File: `.github/workflows/security.yml`**
```yaml
name: security

on:
  pull_request:
  schedule:
    - cron: '17 4 * * 1'

permissions:
  contents: read

jobs:
  audit:
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false

      - uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7.1.0
        with:
          node-version: '26.13.1'
          cache: npm

      - name: Install without running package scripts
        run: npm ci --ignore-scripts

      - name: Package policy (exact versions, no install hooks)
        run: node scripts/check-package-policy.mjs

      - name: Verify registry signatures and provenance
        run: npm audit signatures

      - name: Known vulnerabilities in production dependencies
        run: npm audit --omit=dev --audit-level=high

  dependency-review:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false

      - uses: actions/dependency-review-action@bbc44d14a204704ccc493733616cd1e93a0321ec # v5.0.1
        with:
          fail-on-severity: high
```
What changed compared with lesson 05's workflow, and why:
- **Actions are pinned to a full commit SHA**, with the version in a comment. A tag such as `@v7` can be moved by whoever controls the action's repository (or whoever steals their account) to malicious code that then runs with your repository's permissions. A SHA cannot be moved. The cost: updates need a tool or a person; Dependabot's `github-actions` ecosystem (next file) opens pull requests that update the SHA and the comment together. The SHAs above were looked up for the versions named in the comments when this lesson was written: look them up again for the version you adopt (the tag page on the action's GitHub repository shows the commit).
- **`npm audit signatures`** verifies the registry signatures of installed packages and the provenance attestations of those that have them. Provenance proves a package was built from a stated source by a stated pipeline; it does not prove the source is harmless. `npm audit` checks the advisory database; it only knows **known** vulnerabilities.
- **`dependency-review`** looks at the dependencies a pull request adds or changes and fails on known high-severity advisories. It requires the repository's dependency graph feature; check the action's documentation for what your plan supports.
- The weekly `schedule` catches advisories published after a merge, when no pull request is open.

**File: `.github/dependabot.yml`**
```yaml
version: 2
updates:
  - package-ecosystem: npm
    directory: /
    schedule:
      interval: weekly
    open-pull-requests-limit: 5
    cooldown:
      default-days: 7
    groups:
      typescript-tooling:
        patterns:
          - typescript
          - '@types/*'

  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
    cooldown:
      default-days: 7
```
`cooldown` delays version updates until a release is at least seven days old. Compromised releases are usually discovered and pulled within days, so a short delay avoids most of them; security updates are not delayed by it. `groups` merges related updates into one pull request so reviewers do not drown. Check the Dependabot documentation for the options your repository supports.

## Run it
**Predict first:**
1. Which of the four buttons would still be dangerous if the policy allowed `'unsafe-inline'` but kept Trusted Types?
2. If you remove `'strict-dynamic'` from the policy, does the page still load its script? Why?
3. What does the `legacy` policy's `'self'` do for `script-src` when a nonce and `strict-dynamic` are *added* later?

Answers: (1) Trusted Types alone still stops the `innerHTML` and `setAttribute('onclick', …)` buttons (they are sinks); `eval` is stopped by Trusted Types too. A policy with `unsafe-inline` but without Trusted Types would allow all of them; the layers cover each other's gaps. (2) Yes: the script tag has the nonce, and a nonce alone permits it. `strict-dynamic` matters for scripts that *load other scripts*. (3) Nothing: browsers that support `strict-dynamic` ignore `'self'` and host sources in `script-src` when it is present; they remain as a fallback for old browsers.

## How it works
1. **The browser enforces, the server only declares.** A policy is a header the browser applies to one response. Everything else (nonce freshness, no-caching, reporting) is your server's job.
2. **Layers.** CSP stops an injected script from running; Trusted Types stop dangerous DOM calls even before CSP matters; `HttpOnly` cookies keep session secrets out of reach of any script that does run; `SameSite` limits cross-site requests; dependency controls reduce the chance that the "injected" code is already in your bundle.
3. **Reports.** `securitypolicyviolation` (in the page) and `report-to` (to your server) are how you learn about breakage and attacks.

**Common misconception:** "We sanitise our inputs, so we do not need CSP." Sanitising covers the sinks you remembered; CSP and Trusted Types cover the ones you did not, and the ones in your dependencies. They are for the day a bug gets through.

**Where should the access token live? (ADR style)**

| Option | Who can read it | Failure mode | When it is right |
|---|---|---|---|
| `localStorage` or `sessionStorage` | Any script in the page (XSS, a compromised dependency, an extension content script) | One XSS bug means the attacker has a reusable token; it survives reloads, so it persists after you "fix" the page | Low-risk apps without sensitive data, with a short token lifetime. It is the most common choice and the easiest to attack |
| In memory only (a variable) | Any script that runs while the page is open; not after a reload | The attacker can still *use* the token during the session, but cannot copy a long-lived one away; reload needs a silent refresh | Single-page apps with short-lived access tokens, strict CSP and Trusted Types |
| `HttpOnly` cookie set by a backend you control (a "backend for frontend", BFF) | Only the browser sends it; JavaScript cannot read it | CSRF (use `SameSite`, an `Origin` check and a custom header); needs a server component that holds the real tokens | Anything sensitive. It moves the secret out of the browser entirely, at the cost of running a BFF |

The capstone web clients use the OpenID Connect authorization code flow with PKCE against Keycloak and keep their tokens in the browser through a client library; read each capstone's authentication chapter and the library's documentation to see where it stores them by default and how to change it, and compare that with this table before shipping. Do not use the older implicit flow, which returns tokens in the URL.

**Failure modes**
- **A nonce reused or guessable.** Use at least 128 bits from a cryptographic generator (`randomBytes(16)`), new for every response, and never cache the page.
- **`'unsafe-inline'` in `script-src` "to make it work".** That throws away the main protection. Fix the inline code instead; use a nonce or a hash for the rare unavoidable inline script.
- **Hash sources for pages that change.** A hash is for a static inline script; if the text changes by one character the hash no longer matches (see the exercise).
- **Style policy.** `style-src 'unsafe-inline'` is a common concession because component libraries inject styles. It is a weaker risk than script injection but not zero (data exfiltration through CSS is documented). Prefer nonces for styles where your framework supports them, and measure what you give up.
- **Trusted Types and libraries.** A dependency that writes `innerHTML` throws a `TypeError` once enforcement starts. Roll out in report-only mode, list the policy names your libraries create in `trusted-types`, and for stubborn ones create a `default` policy that sanitises (a last resort, since it makes every string at every sink go through it).
- **Report flood and report spoofing.** Anyone can post to your report endpoint. Bound, sample, aggregate and never trust.
- **`Access-Control-Allow-Origin: *` with credentials, or reflected origins.** Cross-origin resource sharing (CORS) is how a server lets *other* origins read responses. A wildcard or an echoed `Origin` on an authenticated endpoint hands your users' data to any site. Allow an explicit list.
- **Open redirects and `postMessage` without an origin check.** Both turn your domain into part of someone else's attack: check `event.origin` and validate redirect targets against an allow-list.
- **Dependency confusion and typosquatting.** An internal package name registered on the public registry, or `reakt` instead of `react`. Use scopes you own, a private registry configuration that pins scopes, and review new dependencies by name.
- **CI is production's front door.** A workflow with `permissions: write-all`, a secret exposed to pull requests from forks, or `pull_request_target` that checks out untrusted code can be turned into a deployment key leak. Keep permissions minimal, never run untrusted code with secrets, and pin actions.
- **Alert fatigue.** A hundred low-severity audit findings means the real one is missed. Fail on high severity, track the rest on a schedule.

**When not to do all of this**
- A static brochure site without user input or scripts: a short CSP (`default-src 'self'`), HTTPS and `nosniff` are enough.
- Early prototypes with no real users: keep `.npmrc` and exact pins (free), add the rest before real data arrives.
- Do not build your own sanitiser or your own crypto. Use maintained libraries and the platform.

## Try it
Copy your project to `security-lab-try`. The starter is in `exercise/starter`.
1. **Guided.** A page whose inline script never changes can use a **hash source** instead of a nonce, which allows the HTML to be cached. Copy the starter's `src/hash-source.ts` and `src/exercise.ts`, implement `hashSource` (SHA-256 of the script text, encoded in base64, wrapped as `'sha256-…'`) with Node's `crypto`, build, and run `node dist/exercise.js`. Expected output:
```text
true 53
true false
```
2. **Change.** Add a rule to `lint` that reports `connect-src` containing `*` or a bare scheme, and a case in `print-policy.ts` that shows it. Decide where the line between "finding" and "opinion" is, and write down one policy it would flag that you think is acceptable.
3. **Stretch (no single answer).** Write a four-line ADR for one of the capstone web clients: where should its access token live, what would it cost to move to a BFF, and which single control from this lesson would you add first? Name the attack each control stops.

<details><summary>Solution</summary>

**File: `exercise/solution/src/hash-source.ts`**
```ts
import { createHash } from 'node:crypto';
import type { HashSource } from './csp.js';

// Hash sources suit pages that are static: the hash is the same on every response, so the HTML can be cached.
export function hashSource(scriptText: string): HashSource {
  const digest = createHash('sha256').update(scriptText, 'utf8').digest('base64');
  return `'sha256-${digest}'`;
}
```
The length is 53 because a SHA-256 digest is 32 bytes, which is 44 characters in base64 (with one `=` of padding), plus the 8 characters of `'sha256-` and the closing quote. The second printed line shows two facts: the same text always gives the same hash (`true`), and one extra space gives a different hash (`false`), which is also why a build step that re-formats an inline script silently breaks a hash-based policy. `src/exercise.ts` is the same file as in the starter.

</details>

## Check yourself
1. Why does `strict-dynamic` make host allow-lists unnecessary and why is that good? <details><summary>Answer</summary>Trust flows from the nonce'd script to the scripts it loads, so hosts need not be listed; allow-lists are bypassable through any permitted host that serves attacker-influenced script.</details>
2. Why must a page with a nonce never be served from a shared cache? <details><summary>Answer</summary>Every visitor would receive the same nonce, so an attacker who sees it once can reuse it for injected scripts.</details>
3. Report-only mode printed a violation but the inline handler still ran. Is the site protected? <details><summary>Answer</summary>No. Report-only never blocks; it only reports. It is for rollout, not for protection.</details>
4. Find the bug: `Set-Cookie: session=abc; Secure; SameSite=Lax`. Name two improvements. <details><summary>Answer</summary>Add <code>HttpOnly</code> so scripts cannot read it, and use the <code>__Host-</code> prefix with <code>Path=/</code> so it cannot be overwritten by a sibling subdomain. Also set <code>Max-Age</code>.</details>
5. Why does the workflow pin actions by SHA but `package.json` pins by version? <details><summary>Answer</summary>A tag can be moved to different code; a commit SHA cannot. For npm, the lockfile records integrity hashes of each exact version, which gives the same immutability.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| The page is blank and the console says a script was blocked by CSP (typical wording: `Refused to load the script ... because it violates the following Content Security Policy directive`) | The script tag has no nonce, or the nonce differs from the header | Make sure `{{NONCE}}` is replaced and the same value is in the header; do not cache the page |
| `Refused to apply inline style` (typical wording) | An inline `style` attribute or `<style>` under `style-src 'self'` | Move styles into the stylesheet or use a nonce |
| `This document requires 'TrustedHTML' assignment.` (typical wording) | A plain string reached `innerHTML` under Trusted Types | Pass the value through your policy |
| `Failed to execute 'createPolicy' on 'TrustedTypePolicyFactory': Policy with name "app" disallowed.` (typical wording) | The policy name is not in the `trusted-types` list | Add the name to the CSP or fix the name |
| Port already in use (`EADDRINUSE`) | Another process (or an older run) is using 8301 | Stop it, or change `PORT` |
| `Package policy` prints a "pin an exact version" line | A `^` or `~` range in `package.json` | Replace with the exact version |
| `npm.ps1 cannot be loaded` | PowerShell execution policy | Use `npm.cmd` |

## Best practice
Start from a strict CSP and Trusted Types, keep secrets out of JavaScript's reach, and treat your dependencies and your CI as part of the attack surface. Source: OWASP, [Content Security Policy Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Content_Security_Policy_Cheat_Sheet.html) and [DOM based XSS Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/DOM_based_XSS_Prevention_Cheat_Sheet.html); web.dev, [Mitigate cross-site scripting (XSS) with a strict Content Security Policy](https://web.dev/articles/strict-csp); MDN, [Trusted Types API](https://developer.mozilla.org/en-US/docs/Web/API/Trusted_Types_API).

## Production checklist
- [ ] Strict CSP (nonce or hash, `strict-dynamic`, `object-src 'none'`, `base-uri 'none'`, `frame-ancestors`) enforced; report-only candidate running for the next tightening.
- [ ] Trusted Types enforced (or in report-only with a dated plan), one named policy, a maintained sanitiser inside it.
- [ ] HTML with nonces is never cacheable; nonce is at least 128 bits from a cryptographic generator.
- [ ] Session or refresh secrets in `HttpOnly`, `Secure`, `SameSite` cookies (`__Host-` prefix); CSRF defences documented; access tokens short-lived.
- [ ] HSTS rolled out in steps; `nosniff`, `Referrer-Policy`, `Permissions-Policy`, `COOP` set.
- [ ] CORS lists explicit origins; no wildcard with credentials; `postMessage` checks `origin`.
- [ ] Lockfile committed; exact versions; `ignore-scripts`; `npm audit signatures`; dependency review on pull requests; Dependabot with cooldown.
- [ ] CI: minimal `permissions`, pinned actions, no untrusted code with secrets, expression values passed through `env`.
- [ ] A report endpoint with size limits, sampling and alerts; an incident contact in `/.well-known/security.txt`.
- [ ] A scheduled review of third-party scripts and dependencies; removals are as welcome as additions.

## Going further
- MDN: [Content Security Policy guide](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CSP) and the [Trusted Types API](https://developer.mozilla.org/en-US/docs/Web/API/Trusted_Types_API).
- OWASP: the [Top 10](https://owasp.org/www-project-top-ten/) (broken access control, injection, vulnerable and outdated components, software and data integrity failures).
- Capstone link: the CSP in the React capstone's nginx configuration ([capstones/web-react/tutorials/phase-5-ship/05-build-run-ship.md](../../../../capstones/web-react/tutorials/phase-5-ship/05-build-run-ship.md)) uses `'self'` sources and forbids inline script and style; compare it with the policy built here and write down what it would take to add nonces and Trusted Types to it.

## Summary
- You built, linted and rolled out a strict CSP, and explained nonces, `strict-dynamic` and report-only mode.
- You used Trusted Types to remove dangerous sinks and listed what breaks when they are enforced.
- You compared token storage options and chose with the failure mode in view.
- You hardened the supply chain: exact versions, no install scripts, signatures, dependency review, pinned actions.

## Next lesson
09. Micro-frontends, release strategy and a production readiness checklist: decide how teams ship independently and how you know a release is safe.
