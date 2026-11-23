const base = process.argv[2] ?? 'http://127.0.0.1:8200';
for (const path of ['/', '/teams']) {
  const response = await fetch(base + path);
  if (!response.ok || !(await response.text()).includes('<app-root>')) throw new Error('SPA fallback failed');
  const csp = response.headers.get('Content-Security-Policy');
  if (!csp?.includes("script-src 'self'")) throw new Error('CSP missing');
  console.log(`${path}: ${response.status}`);
  console.log(`Content-Security-Policy: ${csp}`);
}
