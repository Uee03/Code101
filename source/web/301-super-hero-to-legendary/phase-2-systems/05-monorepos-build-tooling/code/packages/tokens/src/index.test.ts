import assert from 'node:assert/strict';
import { test } from 'node:test';
import { cssVar, tokenNames } from './index.js';

test('cssVar wraps a token name in var()', () => {
  assert.equal(cssVar('color-surface'), 'var(--color-surface)');
});

test('token names are unique', () => {
  assert.equal(new Set(tokenNames).size, tokenNames.length);
});
