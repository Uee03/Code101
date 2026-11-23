import type { Token } from './tokens.js';

export interface DocsInput {
  readonly shared: readonly Token[];
  readonly light: readonly Token[];
  readonly resolvedLight: ReadonlyMap<string, string>;
  readonly resolvedDark: ReadonlyMap<string, string>;
}

const escapeHtml = (text: string): string =>
  text.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');

const BASE_CSS = `body { margin: 0; background: var(--color-surface); color: var(--color-text-default); font-family: var(--font-family-body); }
main { max-width: 60rem; margin-inline: auto; padding: var(--space-4); }
table { border-collapse: collapse; width: 100%; margin-block: var(--space-6); }
caption { text-align: left; font-weight: 700; padding-block: var(--space-2); }
th, td { text-align: left; padding: var(--space-2); border-bottom: 1px solid var(--color-border-default); }
.swatch { display: inline-block; width: 1.5rem; height: 1.5rem; vertical-align: middle; border: 1px solid var(--color-border-default); border-radius: var(--radius-sm); }
`;

// The page uses no inline styles, so it also works under a strict Content-Security-Policy (lesson 08).
export function emitDocs({ shared, light, resolvedLight, resolvedDark }: DocsInput): { html: string; css: string } {
  const swatchRules: string[] = [];

  const themedRows = light.map((token) => {
    const lightValue = resolvedLight.get(token.name) ?? '';
    const darkValue = resolvedDark.get(token.name) ?? '';
    swatchRules.push(
      `.swatch[data-token="${token.name}"][data-mode="light"] { background: ${lightValue}; }`,
      `.swatch[data-token="${token.name}"][data-mode="dark"] { background: ${darkValue}; }`,
    );
    const swatch = (mode: string, value: string): string =>
      `<span class="swatch" data-token="${token.name}" data-mode="${mode}"></span> <code>${escapeHtml(value)}</code>`;
    return [
      '      <tr>',
      `        <th scope="row"><code>--${token.name}</code></th>`,
      `        <td>${escapeHtml(token.description ?? '')}</td>`,
      `        <td>${swatch('light', lightValue)}</td>`,
      `        <td>${swatch('dark', darkValue)}</td>`,
      '      </tr>',
    ].join('\n');
  });

  const sharedRows = shared.map((token) =>
    [
      '      <tr>',
      `        <th scope="row"><code>--${token.name}</code></th>`,
      `        <td>${token.type}</td>`,
      `        <td><code>${escapeHtml(token.raw)}</code></td>`,
      '      </tr>',
    ].join('\n'),
  );

  const html = [
    '<!doctype html>',
    '<html lang="en">',
    '<head>',
    '  <meta charset="utf-8">',
    '  <meta name="viewport" content="width=device-width, initial-scale=1">',
    '  <title>Design tokens</title>',
    '  <link rel="stylesheet" href="tokens.css">',
    '  <link rel="stylesheet" href="docs.css">',
    '</head>',
    '<body>',
    '  <main>',
    '    <h1>Design tokens</h1>',
    '    <table>',
    '      <caption>Themed colour tokens (light and dark values)</caption>',
    '      <thead><tr><th scope="col">Token</th><th scope="col">Use</th><th scope="col">Light</th><th scope="col">Dark</th></tr></thead>',
    '      <tbody>',
    ...themedRows,
    '      </tbody>',
    '    </table>',
    '    <table>',
    '      <caption>Shared tokens (the same in every theme)</caption>',
    '      <thead><tr><th scope="col">Token</th><th scope="col">Type</th><th scope="col">Value</th></tr></thead>',
    '      <tbody>',
    ...sharedRows,
    '      </tbody>',
    '    </table>',
    '  </main>',
    '</body>',
    '</html>',
    '',
  ].join('\n');

  return { html, css: `${BASE_CSS}${swatchRules.join('\n')}\n` };
}
