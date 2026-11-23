const base = process.argv[2] ?? 'http://localhost:8201';
for (const path of ['/', '/teams']) {
  const response = await fetch(`${base}${path}`);
  if (response.status !== 200 || !response.headers.get('Content-Security-Policy')?.includes("script-src 'self'")) throw new Error(`Static serving failed: ${path}`);
  if (!(await response.text()).includes('<div id="root"></div>')) throw new Error('SPA fallback missing');
  console.log(`GET ${path}: 200; CSP: present`);
}
