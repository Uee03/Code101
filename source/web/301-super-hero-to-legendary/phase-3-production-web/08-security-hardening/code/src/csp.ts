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
