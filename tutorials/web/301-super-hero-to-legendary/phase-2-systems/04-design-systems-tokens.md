---
track: web
level: 301
phase: 2
phase_name: systems
lesson: 04
title: "Design systems and design tokens"
time: 150 min
prerequisites: [web-201.01, web-301.03]
versions: { node: "26.13.1", npm: "11.20.0", typescript: "7.0.2", "@types/node": "26.6.6" }
verified: not yet run
source: source/web/301-super-hero-to-legendary/phase-2-systems/04-design-systems-tokens/
assets: []
---

# 04. Design systems and design tokens

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- explain the three tiers of tokens (primitive, semantic, component) and why components never use primitives directly
- build a token pipeline that reads JSON, resolves references, checks contrast and generates CSS, TypeScript names and a documentation page
- ship light, dark and "follow the system" themes from one set of custom properties without a flash of the wrong theme
- decide between your own pipeline and an existing tool (Style Dictionary) and record the decision as an ADR

## Recap
1. In Web 201 you used CSS custom properties. Which element does a property set on `:root` reach, and why?
   <details><summary>Answer</summary>Every element in the document: custom properties are inherited, so a value set on <code>:root</code> (the <code>html</code> element) is visible to all descendants unless one overrides it.</details>
2. What is the minimum contrast ratio for normal body text under WCAG 2.2 level AA?
   <details><summary>Answer</summary>4.5 to 1 (success criterion 1.4.3). Large text needs 3 to 1.</details>
3. In lesson 02 you derived types from one table. What is the CSS analogue of that table?
   <details><summary>Answer</summary>The token source files: everything else (CSS, names, documentation) is generated from them.</details>

## Why it matters
A design system fails slowly: a colour copied into forty files, a "slightly different" blue, a dark mode that nobody updates. Tokens are the cure: named design decisions (`color-text-muted`) stored once and compiled into every platform. At level 301 the question is not how to write a custom property but how to keep a *system* correct as teams, themes and products multiply. The answer is the same discipline as lessons 01 to 03: one source of truth, generated outputs, tests that fail the build.

## What you will build
A token pipeline in about 250 lines of TypeScript with no runtime dependency:
1. Four JSON files: core primitives, component tokens, and a light and a dark set of semantic tokens.
2. A build that loads them, resolves `{references}`, refuses mismatched themes, checks the contrast of ten text pairs (five per theme), and only then writes `build/tokens.css`, `build/tokens.ts`, `build/tokens.html` and `build/docs.css`.
3. A small demo page that consumes the CSS and has a theme toggle.

## Before you start
- Lessons 01 to 03 finished (Node 26.13.1, npm 11.20.0, TypeScript 7.0.2). A current Chrome, Edge or Firefox for the demo.
- Builds on Web 201 lesson [01 Custom properties and theming](../../201-hero-to-super-hero/phase-1-modern-css/01-custom-properties-and-theming.md), which shows hand-written tokens, `color-scheme`, `light-dark()` and a theme toggle. This lesson adds the part that matters at scale: a pipeline that generates the tokens, checks contrast per theme and documents them.
- Time: 120 to 150 minutes. Break after step 9.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/web/301-super-hero-to-legendary/phase-2-systems/04-design-systems-tokens/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- No `package-lock.json` is shipped; `npm install` creates it.
- The token file format is a subset of the Design Tokens Community Group format (`$value`, `$type`, `$description`, `{group.token}` references). Check the current specification before you rely on features beyond that subset.

## Steps

### Step 1. Create the project
```text
mkdir tokens-lab
cd tokens-lab
mkdir src
mkdir tokens
mkdir demo
```
Expected result: `tokens-lab` containing three empty folders: `src` (the pipeline), `tokens` (the sources of truth) and `demo` (a page that uses the output).

### Step 2. Write package.json and tsconfig.json
**File: `package.json`**
```json
{
  "name": "web301-04-design-tokens",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "typecheck": "tsc --noEmit",
    "build": "tsc",
    "tokens": "tsc && node dist/build.js"
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
`npm run tokens` compiles the pipeline and runs it. There is no runtime dependency on purpose; the decision is discussed in "Build or buy" below.

**File: `tsconfig.json`** (identical to lesson 01, step 3: explained there)
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
Expected result: `node_modules` and `package-lock.json` appear.

### Step 3. Write the token sources
Three tiers, each with a different job:

| Tier | Example | Who may use it | Changes when |
|---|---|---|---|
| Primitive (core) | `palette-blue-600` | Only other tokens | The brand palette changes |
| Semantic | `color-action-background` | Components | Meaning or theme changes |
| Component | `button-padding-inline` | One component | That component is redesigned |

The rule that makes the system work: **components use semantic and component tokens, never primitives.** If a button used `palette-blue-600` directly, the dark theme could not change it.

**File: `tokens/core.tokens.json`**
```json
{
  "palette": {
    "$type": "color",
    "gray": {
      "50": { "$value": "#f9fafb" },
      "300": { "$value": "#d1d5db" },
      "500": { "$value": "#6b7280" },
      "700": { "$value": "#374151" },
      "900": { "$value": "#111827" }
    },
    "blue": {
      "300": { "$value": "#93c5fd" },
      "600": { "$value": "#2563eb" }
    },
    "white": { "$value": "#ffffff" }
  },
  "space": {
    "$type": "dimension",
    "1": { "$value": "0.25rem" },
    "2": { "$value": "0.5rem" },
    "4": { "$value": "1rem" },
    "6": { "$value": "1.5rem" }
  },
  "radius": {
    "$type": "dimension",
    "sm": { "$value": "0.25rem" },
    "md": { "$value": "0.5rem" }
  },
  "font": {
    "size": {
      "$type": "dimension",
      "sm": { "$value": "0.875rem" },
      "md": { "$value": "1rem" },
      "lg": { "$value": "1.25rem" }
    },
    "family": {
      "$type": "fontFamily",
      "body": { "$value": "system-ui, sans-serif" }
    }
  }
}
```
- A node with `$value` is a token; any other object is a group. A `$type` on a group applies to everything below it, so `palette` declares `color` once.
- The token's name is its path joined with hyphens: `palette` / `gray` / `50` becomes `palette-gray-50`, and later the custom property `--palette-gray-50`.
- Dimensions are in `rem`, not `px`, so text and spacing follow the user's browser font-size setting (an accessibility requirement, WCAG 1.4.4 resize text).

**File: `tokens/component.tokens.json`**
```json
{
  "button": {
    "$type": "dimension",
    "padding-block": { "$value": "{space.2}" },
    "padding-inline": { "$value": "{space.4}" },
    "radius": { "$value": "{radius.md}" },
    "font-size": { "$value": "{font.size.md}" }
  }
}
```
`{space.2}` is a **reference**: "use whatever `space.2` is". References keep a single value in one place.

**File: `tokens/semantic.light.tokens.json`**
```json
{
  "color": {
    "$type": "color",
    "surface": { "$value": "{palette.white}", "$description": "Page background" },
    "surface-subtle": { "$value": "{palette.gray.50}", "$description": "Cards and panels" },
    "text": {
      "default": { "$value": "{palette.gray.900}", "$description": "Body text" },
      "muted": { "$value": "{palette.gray.700}", "$description": "Secondary text" }
    },
    "border": {
      "default": { "$value": "{palette.gray.300}", "$description": "Dividers and outlines" }
    },
    "action": {
      "background": { "$value": "{palette.blue.600}", "$description": "Primary button background" },
      "text": { "$value": "{palette.white}", "$description": "Text on the primary button" }
    },
    "focus": { "$value": "{palette.blue.600}", "$description": "Keyboard focus ring" }
  }
}
```
**File: `tokens/semantic.dark.tokens.json`**
```json
{
  "color": {
    "$type": "color",
    "surface": { "$value": "{palette.gray.900}", "$description": "Page background" },
    "surface-subtle": { "$value": "{palette.gray.700}", "$description": "Cards and panels" },
    "text": {
      "default": { "$value": "{palette.gray.50}", "$description": "Body text" },
      "muted": { "$value": "{palette.gray.300}", "$description": "Secondary text" }
    },
    "border": {
      "default": { "$value": "{palette.gray.500}", "$description": "Dividers and outlines" }
    },
    "action": {
      "background": { "$value": "{palette.blue.300}", "$description": "Primary button background" },
      "text": { "$value": "{palette.gray.900}", "$description": "Text on the primary button" }
    },
    "focus": { "$value": "{palette.blue.300}", "$description": "Keyboard focus ring" }
  }
}
```
Both themes define **exactly the same names**. Only the values differ. The description is documentation that travels with the token; it becomes the "Use" column of the generated page.

### Step 4. Write the token loader and resolver
**File: `src/tokens.ts`**
```ts
import { readFileSync } from 'node:fs';

export type TokenType = 'color' | 'dimension' | 'fontFamily';

export interface Token {
  readonly path: readonly string[];
  readonly name: string;
  readonly type: TokenType;
  readonly raw: string;
  readonly description: string | undefined;
}

const TOKEN_TYPES: readonly string[] = ['color', 'dimension', 'fontFamily'];
const REFERENCE = /^\{([^{}]+)\}$/;

function isTokenType(value: unknown): value is TokenType {
  return typeof value === 'string' && TOKEN_TYPES.includes(value);
}

export function loadTokens(file: string): Token[] {
  return flatten(JSON.parse(readFileSync(file, 'utf8')) as unknown, file);
}

// Walk the nested JSON. A node with "$value" is a token; "$type" is inherited from the nearest group.
export function flatten(root: unknown, source: string): Token[] {
  const tokens: Token[] = [];

  const walk = (node: unknown, path: string[], inherited: TokenType | undefined): void => {
    const where = path.join('.') || '(root)';
    if (typeof node !== 'object' || node === null || Array.isArray(node)) {
      throw new Error(`${source}: ${where} must be an object`);
    }
    const record = node as Record<string, unknown>;
    let type = inherited;
    const declared = record['$type'];
    if (declared !== undefined) {
      if (!isTokenType(declared)) {
        throw new Error(`${source}: ${where} has an unknown $type ${String(declared)}`);
      }
      type = declared;
    }
    if ('$value' in record) {
      const value = record['$value'];
      if (typeof value !== 'string') {
        throw new Error(`${source}: ${where} $value must be a string`);
      }
      if (type === undefined) {
        throw new Error(`${source}: ${where} has no $type (set one on the token or its group)`);
      }
      const description = record['$description'];
      tokens.push({
        path,
        name: path.join('-'),
        type,
        raw: value,
        description: typeof description === 'string' ? description : undefined,
      });
      return;
    }
    for (const [key, child] of Object.entries(record)) {
      if (!key.startsWith('$')) {
        walk(child, [...path, key], type);
      }
    }
  };

  walk(root, [], undefined);
  return tokens;
}

// "{palette.white}" becomes "palette-white"; a plain value returns undefined.
export function referenceTarget(raw: string): string | undefined {
  return REFERENCE.exec(raw)?.[1]?.replaceAll('.', '-');
}

// Follow every reference to its final value. Unknown targets, cycles and type changes are errors.
export function resolveAll(tokens: readonly Token[]): Map<string, string> {
  const byName = new Map(tokens.map((token) => [token.name, token] as const));
  const resolved = new Map<string, string>();

  const resolve = (name: string, trail: readonly string[]): string => {
    const cached = resolved.get(name);
    if (cached !== undefined) {
      return cached;
    }
    if (trail.includes(name)) {
      throw new Error(`Circular reference: ${[...trail, name].join(' -> ')}`);
    }
    const token = byName.get(name);
    if (token === undefined) {
      throw new Error(`Unknown token "${name}" referenced from "${trail.at(-1) ?? 'the top level'}"`);
    }
    const target = referenceTarget(token.raw);
    let value = token.raw;
    if (target !== undefined) {
      const targetToken = byName.get(target);
      if (targetToken !== undefined && targetToken.type !== token.type) {
        throw new Error(`Type mismatch: ${name} is ${token.type} but ${target} is ${targetToken.type}`);
      }
      value = resolve(target, [...trail, name]);
    }
    resolved.set(name, value);
    return value;
  };

  for (const token of tokens) {
    resolve(token.name, []);
  }
  return resolved;
}

// Every themed token must exist in every theme, otherwise one theme silently falls back to nothing.
export function assertSameNames(light: readonly Token[], dark: readonly Token[]): void {
  const lightNames = new Set(light.map((token) => token.name));
  const darkNames = new Set(dark.map((token) => token.name));
  const problems = [
    ...[...lightNames].filter((name) => !darkNames.has(name)).map((name) => `${name} is missing in the dark theme`),
    ...[...darkNames].filter((name) => !lightNames.has(name)).map((name) => `${name} is missing in the light theme`),
  ];
  if (problems.length > 0) {
    throw new Error(`Theme mismatch:\n${problems.join('\n')}`);
  }
}
```
How it works:
- `flatten` is a recursive walk. JSON is `unknown` until validated: the file is *data*, so every shape assumption is checked and produces an error that names the file and the path. This is the lesson 02 "boundary" idea applied to your own tooling.
- `resolveAll` follows references with a **trail** (the names visited so far). If a name reappears in its own trail you have a loop (`a` refers to `b` refers to `a`), and the error prints the whole loop. A reference to a token that does not exist is an error, not an empty string.
- A **type mismatch** check stops `{space.2}` being used for a colour.
- `assertSameNames` is the theme-parity rule: it is a failure mode in every real design system that a token is added to light and forgotten in dark.

### Step 5. Write the contrast checker
**File: `src/contrast.ts`**
```ts
export interface Pair {
  readonly foreground: string;
  readonly background: string;
}

function channel(hex: string, offset: number): number {
  const value = Number.parseInt(hex.slice(offset, offset + 2), 16) / 255;
  // sRGB to linear light. 0.04045 is the sRGB threshold; WCAG 2.x text says 0.03928, which gives the same result for 8-bit values.
  return value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4;
}

// WCAG relative luminance of a #rrggbb colour.
export function luminance(hex: string): number {
  if (!/^#[0-9a-f]{6}$/i.test(hex)) {
    throw new Error(`Expected a colour like #rrggbb, got "${hex}"`);
  }
  return 0.2126 * channel(hex, 1) + 0.7152 * channel(hex, 3) + 0.0722 * channel(hex, 5);
}

export function contrastRatio(first: string, second: string): number {
  const a = luminance(first);
  const b = luminance(second);
  return (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);
}

export function checkPairs(
  theme: string,
  resolved: ReadonlyMap<string, string>,
  pairs: readonly Pair[],
  minimum: number,
): string[] {
  const failures: string[] = [];
  for (const { foreground, background } of pairs) {
    const fg = resolved.get(foreground);
    const bg = resolved.get(background);
    if (fg === undefined || bg === undefined) {
      failures.push(`${theme}: unknown token in pair ${foreground} on ${background}`);
      continue;
    }
    const ratio = contrastRatio(fg, bg);
    if (ratio < minimum) {
      failures.push(`${theme}: ${foreground} on ${background} is ${ratio.toFixed(2)}:1 (minimum ${minimum}:1)`);
    }
  }
  return failures;
}
```
The formula is the WCAG relative-luminance definition: convert each 8-bit channel to linear light, weight red, green and blue by 0.2126, 0.7152 and 0.0722, then divide `(lighter + 0.05) / (darker + 0.05)`. Black on white gives exactly 21 to 1; two identical colours give 1 to 1. **A pair that passes in the light theme can fail in the dark theme**, which is why each pair is checked once per theme.

**File: `src/pairs.ts`**
```ts
import type { Pair } from './contrast.js';

// Body text needs 4.5:1 (WCAG 2.2 success criterion 1.4.3, level AA).
export const MINIMUM_RATIO = 4.5;

// Every foreground/background combination the components are allowed to use.
export const CONTRAST_PAIRS: readonly Pair[] = [
  { foreground: 'color-text-default', background: 'color-surface' },
  { foreground: 'color-text-muted', background: 'color-surface' },
  { foreground: 'color-text-default', background: 'color-surface-subtle' },
  { foreground: 'color-text-muted', background: 'color-surface-subtle' },
  { foreground: 'color-action-text', background: 'color-action-background' },
];
```
The list is *policy as data*. The rule to enforce in review: a component may only put text on a background if the pair is in this list. Large text and non-text parts (the focus ring, input borders) have a 3 to 1 minimum (WCAG 1.4.11 non-text contrast); add them with a separate minimum when your system has them.

### Step 6. Write the CSS emitter
**File: `src/emit-css.ts`**
```ts
import type { Token } from './tokens.js';
import { referenceTarget } from './tokens.js';

export interface ThemeTokens {
  readonly shared: readonly Token[];
  readonly light: readonly Token[];
  readonly dark: readonly Token[];
}

// A reference stays a reference: "{space.2}" becomes var(--space-2), so one override at runtime flows through.
function declaration(token: Token): string {
  const target = referenceTarget(token.raw);
  return `  --${token.name}: ${target === undefined ? token.raw : `var(--${target})`};`;
}

export function emitCss({ shared, light, dark }: ThemeTokens): string {
  const lines: string[] = ['/* Generated by src/build.ts. Do not edit. */'];

  const rule = (selectors: readonly string[], tokens: readonly Token[], scheme?: 'light' | 'dark', indent = ''): void => {
    lines.push(`${indent}${selectors.join(`,\n${indent}`)} {`);
    if (scheme !== undefined) {
      lines.push(`${indent}  color-scheme: ${scheme};`);
    }
    for (const token of tokens) {
      lines.push(`${indent}${declaration(token)}`);
    }
    lines.push(`${indent}}`);
  };

  rule([':root'], shared);
  rule([':root', '[data-theme="light"]'], light, 'light');
  rule(['[data-theme="dark"]'], dark, 'dark');
  lines.push('@media (prefers-color-scheme: dark) {');
  rule([':root:not([data-theme="light"])'], dark, 'dark', '  ');
  lines.push('}');

  return `${lines.join('\n')}\n`;
}
```
Design decisions in the output:
- Shared tokens go on `:root` once. Themed tokens are written **three times**: for the default light theme (also reachable explicitly with `data-theme="light"`), for an explicit `data-theme="dark"`, and inside a `prefers-color-scheme: dark` media query for visitors who have not chosen. The `:not([data-theme="light"])` inside the media query is what lets an explicit "light" choice beat the operating system.
- `color-scheme` tells the browser to draw its own parts (scrollbars, form controls, default canvas) in the matching scheme. Without it, a dark page can have a bright scrollbar.
- A reference stays `var(--space-2)` instead of being flattened to `0.5rem`. Trade-off: overriding `--space-2` on one subtree then changes every token that points at it (powerful for density modes), at the cost of one extra lookup per reference (negligible; measure if you doubt it).

### Step 7. Write the TypeScript and documentation emitters
**File: `src/emit-types.ts`**
```ts
import type { Token } from './tokens.js';

// Generate a TypeScript file so components can only ask for tokens that exist.
export function emitTypes(tokens: readonly Token[]): string {
  const names = tokens.map((token) => `  '${token.name}',`);
  return [
    '// Generated by src/build.ts. Do not edit.',
    'export const tokenNames = [',
    ...names,
    '] as const;',
    '',
    'export type TokenName = (typeof tokenNames)[number];',
    '',
    'export function cssVar(name: TokenName): string {',
    '  return `var(--${name})`;',
    '}',
    '',
  ].join('\n');
}
```
This is lesson 02 in practice: a typo such as `cssVar('color-text-mutd')` becomes a compile error in a component that uses JavaScript for styling (canvas, charts, inline SVG).

**File: `src/emit-docs.ts`**
```ts
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
```
How it works: the page is generated **from the same data** as the CSS, so documentation cannot go stale. It uses a real `<table>` with a `<caption>` and `scope` attributes so screen readers announce the row and column headers. The swatches get their colour from generated CSS rules (`.swatch[data-token="..."]`), not `style="..."` attributes, so the page also works under a strict Content-Security-Policy (lesson 08 explains why inline styles are blocked there). The documentation page itself uses the tokens it documents: if the theme breaks, the page that documents it breaks too, which is a cheap early warning.

### Step 8. Write the build entry point
**File: `src/build.ts`**
```ts
import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { checkPairs } from './contrast.js';
import { emitCss } from './emit-css.js';
import { emitDocs } from './emit-docs.js';
import { emitTypes } from './emit-types.js';
import { CONTRAST_PAIRS, MINIMUM_RATIO } from './pairs.js';
import { assertSameNames, loadTokens, resolveAll } from './tokens.js';

const root = process.cwd();
const fromTokens = (file: string) => loadTokens(join(root, 'tokens', file));

const shared = [...fromTokens('core.tokens.json'), ...fromTokens('component.tokens.json')];
const light = fromTokens('semantic.light.tokens.json');
const dark = fromTokens('semantic.dark.tokens.json');
assertSameNames(light, dark);

const resolvedLight = resolveAll([...shared, ...light]);
const resolvedDark = resolveAll([...shared, ...dark]);
console.log(`Tokens: ${shared.length} shared, ${light.length} light, ${dark.length} dark`);

const failures = [
  ...checkPairs('light', resolvedLight, CONTRAST_PAIRS, MINIMUM_RATIO),
  ...checkPairs('dark', resolvedDark, CONTRAST_PAIRS, MINIMUM_RATIO),
];

if (failures.length > 0) {
  // Fail before writing anything: a bad token set must never reach the output folder.
  console.error(failures.join('\n'));
  process.exitCode = 1;
} else {
  console.log(`Contrast: ${CONTRAST_PAIRS.length * 2} pairs passed (minimum ${MINIMUM_RATIO}:1)`);
  const out = join(root, 'build');
  mkdirSync(out, { recursive: true });
  writeFileSync(join(out, 'tokens.css'), emitCss({ shared, light, dark }));
  writeFileSync(join(out, 'tokens.ts'), emitTypes([...shared, ...light]));
  const docs = emitDocs({ shared, light, resolvedLight, resolvedDark });
  writeFileSync(join(out, 'tokens.html'), docs.html);
  writeFileSync(join(out, 'docs.css'), docs.css);
  console.log('Wrote build/tokens.css, build/tokens.ts, build/tokens.html, build/docs.css');
}
```
`process.cwd()` is the folder you run the command in: run `npm run tokens` from the project folder, never from `dist`. `process.exitCode = 1` marks the process as failed without cutting off pending output, which is what CI looks at.

### Step 9. Run the pipeline
```text
npm run tokens --silent
```
Expected output (not yet run):
```text
Tokens: 22 shared, 8 light, 8 dark
Contrast: 10 pairs passed (minimum 4.5:1)
Wrote build/tokens.css, build/tokens.ts, build/tokens.html, build/docs.css
```
The 22 is 18 core tokens (8 palette, 4 space, 2 radius, 3 font sizes, 1 font family) plus 4 button tokens. Now open `build/tokens.css`. Because the emitter is deterministic, you can predict it exactly:

**Expected file: `build/tokens.css`** (generated; it is not part of the source pack)
```css
/* Generated by src/build.ts. Do not edit. */
:root {
  --palette-gray-50: #f9fafb;
  --palette-gray-300: #d1d5db;
  --palette-gray-500: #6b7280;
  --palette-gray-700: #374151;
  --palette-gray-900: #111827;
  --palette-blue-300: #93c5fd;
  --palette-blue-600: #2563eb;
  --palette-white: #ffffff;
  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-4: 1rem;
  --space-6: 1.5rem;
  --radius-sm: 0.25rem;
  --radius-md: 0.5rem;
  --font-size-sm: 0.875rem;
  --font-size-md: 1rem;
  --font-size-lg: 1.25rem;
  --font-family-body: system-ui, sans-serif;
  --button-padding-block: var(--space-2);
  --button-padding-inline: var(--space-4);
  --button-radius: var(--radius-md);
  --button-font-size: var(--font-size-md);
}
:root,
[data-theme="light"] {
  color-scheme: light;
  --color-surface: var(--palette-white);
  --color-surface-subtle: var(--palette-gray-50);
  --color-text-default: var(--palette-gray-900);
  --color-text-muted: var(--palette-gray-700);
  --color-border-default: var(--palette-gray-300);
  --color-action-background: var(--palette-blue-600);
  --color-action-text: var(--palette-white);
  --color-focus: var(--palette-blue-600);
}
[data-theme="dark"] {
  color-scheme: dark;
  --color-surface: var(--palette-gray-900);
  --color-surface-subtle: var(--palette-gray-700);
  --color-text-default: var(--palette-gray-50);
  --color-text-muted: var(--palette-gray-300);
  --color-border-default: var(--palette-gray-500);
  --color-action-background: var(--palette-blue-300);
  --color-action-text: var(--palette-gray-900);
  --color-focus: var(--palette-blue-300);
}
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    color-scheme: dark;
    --color-surface: var(--palette-gray-900);
    --color-surface-subtle: var(--palette-gray-700);
    --color-text-default: var(--palette-gray-50);
    --color-text-muted: var(--palette-gray-300);
    --color-border-default: var(--palette-gray-500);
    --color-action-background: var(--palette-blue-300);
    --color-action-text: var(--palette-gray-900);
    --color-focus: var(--palette-blue-300);
  }
}
```
Notice that the file is plain CSS with no build step needed by consumers: any project can `<link>` it. Notice also the duplicated dark block: that duplication is the price of supporting both "follow the system" and "explicit choice" in pure CSS (a CSS preprocessor or `light-dark()` can shrink it; see Going further).

### Step 10. Write the demo page
**File: `demo/index.html`**
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Tokens demo</title>
  <link rel="stylesheet" href="../build/tokens.css">
  <link rel="stylesheet" href="components.css">
  <script src="theme.js"></script>
</head>
<body>
  <main>
    <h1>Task summary</h1>
    <section class="card" aria-labelledby="card-title">
      <h2 id="card-title">Release checklist</h2>
      <p>Three tasks are blocked.</p>
      <button class="button" type="button">Open board</button>
    </section>
    <p><button id="theme-toggle" class="button" type="button" aria-pressed="false">Dark mode</button></p>
  </main>
</body>
</html>
```
**File: `demo/components.css`**
```css
body {
  margin: 0;
  background: var(--color-surface);
  color: var(--color-text-default);
  font-family: var(--font-family-body);
  font-size: var(--font-size-md);
}

main {
  max-width: 40rem;
  margin: var(--space-6) auto;
  padding-inline: var(--space-4);
}

.card {
  background: var(--color-surface-subtle);
  border: 1px solid var(--color-border-default);
  border-radius: var(--radius-md);
  padding: var(--space-4);
}

.card p {
  color: var(--color-text-muted);
}

.button {
  background: var(--color-action-background);
  color: var(--color-action-text);
  border: 0;
  border-radius: var(--button-radius);
  padding: var(--button-padding-block) var(--button-padding-inline);
  font-size: var(--button-font-size);
  cursor: pointer;
}

.button:focus-visible {
  outline: 3px solid var(--color-focus);
  outline-offset: 2px;
}
```
Every colour and size comes from a semantic or component token: there is no hex value and no pixel number in this file. **File: `demo/theme.js`**
```js
const root = document.documentElement;
const saved = localStorage.getItem('theme');
if (saved === 'light' || saved === 'dark') {
  root.dataset.theme = saved;
}

addEventListener('DOMContentLoaded', () => {
  const button = document.querySelector('#theme-toggle');
  if (!(button instanceof HTMLButtonElement)) {
    return;
  }
  const currentTheme = () =>
    root.dataset.theme ?? (matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
  const sync = () => button.setAttribute('aria-pressed', String(currentTheme() === 'dark'));

  button.addEventListener('click', () => {
    const next = currentTheme() === 'dark' ? 'light' : 'dark';
    root.dataset.theme = next;
    localStorage.setItem('theme', next);
    sync();
  });
  sync();
});
```
- The script is loaded in `<head>` **without** `defer`, on purpose: it must run before the first paint so a saved "dark" choice is applied before the page is drawn. If it ran late, a visitor who chose dark would see a flash of the light theme (the "flash of wrong theme"). The cost: a tiny render-blocking script. Keep it tiny; lesson 07 shows how to measure that cost.
- The first half sets `data-theme` only when the visitor made an explicit choice; with no saved choice nothing is set, and the `prefers-color-scheme` rule decides.
- The toggle is a real `<button>` with `aria-pressed`, so keyboard and screen reader users can operate it and hear its state. The button's accessible name stays "Dark mode" while the state changes, which is the correct pattern for a toggle button.

Open `demo/index.html` by double-clicking it (a `file://` page works for this demo). What you should see, by reading the CSS: in the light theme, a white page with near-black text, a very light grey card with a thin grey border, and blue buttons with white text. Pressing "Dark mode" should switch to a near-black page, a dark grey card and light-blue buttons with near-black text. Emulate the system preference without changing your system: in Chrome or Edge DevTools open the command menu (Ctrl+Shift+P, or Command+Shift+P on macOS), type "prefers-color-scheme", and choose the emulate option. Press Tab to move to a button and check for a visible 3-pixel focus ring. I describe the expected look from the code; confirm it in your browser.

## Run it
**Predict first:**
1. What does the build print if you change `color-text-muted` in the light theme to `{palette.gray.300}`?
2. What happens if you delete `focus` from `semantic.dark.tokens.json`?
3. What is `--button-padding-inline` in the browser's computed styles?

Answers: (1) a failure line for `color-text-muted` on `color-surface` and on `color-surface-subtle` in the light theme, with a ratio shown to two decimals (the exact numbers are yours to read), the process exit code is 1 and **no files are written**; (2) `Theme mismatch:` followed by `color-focus is missing in the dark theme`, thrown before anything else runs (the process prints a stack trace and exits with code 1); (3) the Computed pane in DevTools shows `1rem`, because `var()` references inside a custom property are substituted when its computed value is calculated.

Try both experiments, then undo them.

## How it works
1. **Source of truth.** JSON files are the only things a human edits.
2. **Compile.** `build.ts` validates (shape, references, type, theme parity, contrast) and only then generates.
3. **Consume.** Components use CSS custom properties. The cascade resolves them at runtime, so changing a theme is one attribute on one element, not a rewritten stylesheet.

**Common misconception:** "Dark mode means inverting colours." It means choosing a second set of *meanings* (`surface`, `text`) with new values, checked for contrast on their own. That is why a primitive-only system cannot do dark mode and a semantic system can.

**Build or buy: ADR**

| | Own pipeline (this lesson) | Style Dictionary |
|---|---|---|
| Context | One web platform, one team, about 100 tokens | Several platforms (web, iOS, Android), many outputs |
| Setup | 250 lines you own and can read | A dependency and a config to learn |
| Outputs | Exactly what you wrote | Many built-in formats and transforms; custom ones are possible |
| Risk | You maintain it; a format change in the token standard is yours to follow | Another dependency in your supply chain (lesson 08) and its breaking releases |
| Decision | Start here when you ship to the web only | Move when you need a second platform or many output formats |

Keep the **format** (the Design Tokens Community Group subset) stable and the **tool** replaceable: then switching later is a configuration task, not a redesign.

**Custom properties: trade-offs and failure modes**
- **Runtime cost.** Changing a custom property on `:root` invalidates style for the whole tree; the browser recalculates styles for every element that uses it. For a one-time theme switch this is fine. For per-frame animation of a root property it is not: animate on the smallest subtree instead. Measure: DevTools Performance panel, record while toggling the theme, and look at the "Recalculate Style" entries. Write down your own numbers.
- **Untyped values.** A custom property is a string until used. `@property` registers a syntax (`syntax: '<color>'`), which makes it type-checked, animatable and gives it a default value. Browser support is good in current browsers; check MDN's compatibility table for your support matrix and keep a fallback.
- **Inheritance surprises.** A custom property set on an element is inherited by descendants, so a component deep in a dark section inherits dark values: usually what you want. Scoped themes (`<section data-theme="dark">`) rely on it.
- **Too many tokens.** Every token is a promise. Add a token only when two places need the same decision. A system with 800 tokens that nobody can name is as bad as hard-coded colours.
- **Naming churn.** Renaming a token breaks every consumer. Use roles (`text-muted`), not appearances (`gray-700-text`), and deprecate with a period before deleting.
- **Forced colours (Windows High Contrast).** In `forced-colors` mode the browser overrides most colour properties with system colours, regardless of your tokens. Test your components there; do not assume your theme survives.
- **Flash of wrong theme.** Described above; the `<head>` script is the remedy.

**When not to build a design system**
- One application with one designer and no second consumer in sight: a single CSS file with custom properties is enough.
- When the design is still being discovered every week. Tokens freeze decisions; freeze them after they stabilise.
- When nobody will own it. A design system without an owner decays into the same chaos with extra steps.

## Try it
Copy your project to `tokens-lab-try`. The starter files for the first rung are in `exercise/starter`.
1. **Guided.** Add a `danger` colour group for destructive buttons. Copy the starter's `tokens/semantic.light.tokens.json`, `tokens/semantic.dark.tokens.json` and `src/pairs.ts` over your own. The starter's danger colours are wrong on purpose: run `npm run tokens`, read the contrast failures, then add a red scale to `tokens/core.tokens.json` (the values `#fca5a5` for 300 and `#dc2626` for 600 are one workable choice) and point the danger tokens at it until the build passes. Expected final output: `Tokens: 24 shared, 10 light, 10 dark` and `Contrast: 12 pairs passed (minimum 4.5:1)`.
2. **Change.** Make the build fail when a themed token has no `$description`. Where does the check belong: `flatten` or `build.ts`? Add a negative case by removing one description.
3. **Stretch (no single answer).** Add a `density` axis (compact and comfortable spacing) as a *second* theme dimension. Does it need a third copy of the file set? Can references to `space` tokens do the work? Write the trade-off in three sentences.

<details><summary>Solution</summary>

The solution changes four files (`exercise/solution/`):

**File: `tokens/core.tokens.json`** adds, between `blue` and `white`:
```json
    "red": {
      "300": { "$value": "#fca5a5" },
      "600": { "$value": "#dc2626" }
    },
```
**File: `tokens/semantic.light.tokens.json`** (the `danger` group):
```json
    "danger": {
      "background": { "$value": "{palette.red.600}", "$description": "Destructive button background" },
      "text": { "$value": "{palette.white}", "$description": "Text on the destructive button" }
    },
```
**File: `tokens/semantic.dark.tokens.json`** (the `danger` group):
```json
    "danger": {
      "background": { "$value": "{palette.red.300}", "$description": "Destructive button background" },
      "text": { "$value": "{palette.gray.900}", "$description": "Text on the destructive button" }
    },
```
`src/pairs.ts` is the starter's, which already lists `color-danger-text` on `color-danger-background`. With the solution in place, `npm run tokens --silent` should print (not yet run):
```text
Tokens: 24 shared, 10 light, 10 dark
Contrast: 12 pairs passed (minimum 4.5:1)
Wrote build/tokens.css, build/tokens.ts, build/tokens.html, build/docs.css
```
The pair now passes because white on `#dc2626` is above 4.5 to 1 in the light theme and near-black on `#fca5a5` is far above it in the dark theme. Verify by reading the build output, not by trusting this paragraph.

For the change rung: put the check in `build.ts` next to `assertSameNames`, because "every token has a description" is a policy of *this design system*, not a property of the token file format. For the stretch rung: a density axis is independent of the colour theme, so a separate `[data-density="compact"]` block that overrides only `--space-*` avoids a 2 x 2 matrix of files; components that use `--button-padding-*` follow automatically because those tokens are references.

</details>

## Check yourself
1. Why must components use semantic tokens and not primitives? <details><summary>Answer</summary>A primitive has one value; a semantic token can have a different value per theme. A component that uses a primitive cannot change with the theme.</details>
2. What does `:root:not([data-theme="light"])` inside the media query do? <details><summary>Answer</summary>It applies the dark values only when the visitor has not explicitly chosen light, so an explicit choice beats the operating-system preference.</details>
3. The build prints a failure for a pair in the dark theme only. Is that possible, and why? <details><summary>Answer</summary>Yes. The pair resolves to different colours in each theme; contrast must be checked per theme.</details>
4. Find the bug: `theme.js` is loaded with `defer`. What does a visitor who chose dark see? <details><summary>Answer</summary>A brief flash of the light theme before the script sets the attribute, because deferred scripts run after parsing and the first paint can happen earlier.</details>
5. Why is the build allowed to write no files when contrast fails? <details><summary>Answer</summary>Generated output is a deliverable; publishing a failing set would ship the failure. Failing before writing keeps the last good output in place and keeps CI red.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Unknown token "palette-blu-600" referenced from "color-action-background"` | A typo in a reference | Fix the reference in the JSON; the message names both sides |
| `Circular reference: a -> b -> a` | Two tokens refer to each other | Break the loop; one of them must hold a real value |
| `core.tokens.json: palette.gray.50 has no $type (set one on the token or its group)` (shape of the message) | The token has no `$type` and no group above it declares one | Add `$type` to the token or its group |
| Build prints `Theme mismatch:` | A token exists in one theme only | Add it to the other theme |
| The page is unstyled | `build/tokens.css` does not exist yet, or the path in `index.html` is wrong | Run `npm run tokens`; check the `../build/tokens.css` link |
| The toggle works but reloading resets it | `localStorage` is blocked or cleared (private window, or some `file://` setups) | Serve the folder over `http://localhost`; treat storage as best effort |
| `Cannot find module` or `ENOENT` for `tokens/...` | You ran `node dist/build.js` from another folder | Run it from the project folder: the tokens are found through `process.cwd()` |
| `npm.ps1 cannot be loaded` | PowerShell execution policy | Use `npm.cmd` |

## Best practice
One source of truth, generated outputs, and a build that fails on the things people forget (theme parity, contrast, unknown references). Source: W3C WAI, [Understanding Success Criterion 1.4.3 Contrast (Minimum)](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html), and MDN, [Using CSS custom properties](https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Cascading_variables/Using_custom_properties).

## Production checklist
- [ ] Tokens live in files, not in a design tool alone, and are reviewed like code.
- [ ] Three tiers; components reference only semantic and component tokens (lint it: no `--palette-*` in component CSS).
- [ ] Every themed token exists in every theme; contrast is computed per theme in CI.
- [ ] Output is deterministic and generated; nobody edits `build/`.
- [ ] A documentation page is generated from the same data and published with the CSS.
- [ ] Dimensions use `rem`; text can zoom to 200 percent without loss (test it).
- [ ] The theme choice is applied before first paint; the toggle is a real button with a state.
- [ ] You tested `forced-colors` and `prefers-reduced-motion` behaviour of your components.
- [ ] You measured style recalculation cost for the theme switch in DevTools (record your own numbers).
- [ ] Renaming or removing a token follows a deprecation process.

## Going further
- MDN: [`light-dark()`](https://developer.mozilla.org/en-US/docs/Web/CSS/color_value/light-dark) and [`color-scheme`](https://developer.mozilla.org/en-US/docs/Web/CSS/color-scheme), the way to remove the duplicated dark block; [`@property`](https://developer.mozilla.org/en-US/docs/Web/CSS/@property).
- W3C WAI: [Non-text Contrast (1.4.11)](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html) for focus rings and input borders.
- Capstone link: the capstone web clients ([capstones/web-angular](../../../../capstones/web-angular/README.md), [capstones/web-react](../../../../capstones/web-react/README.md)) use plain CSS; replace their hard-coded colours with this pipeline's output as a refactoring exercise and re-run their accessibility checks.

## Summary
- You separated primitive, semantic and component tokens and said who may use each.
- You built a pipeline that validates, checks contrast per theme and generates CSS, TypeScript names and documentation.
- You shipped light, dark and system themes without a flash of the wrong theme.
- You compared building and buying a token tool and listed the failure modes of custom properties.

## Next lesson
05. Monorepos and build tooling: put the pipeline, a UI package and an app in one repository with workspaces, project references and a cache.
