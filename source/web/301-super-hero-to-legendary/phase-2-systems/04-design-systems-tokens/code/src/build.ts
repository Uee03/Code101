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
