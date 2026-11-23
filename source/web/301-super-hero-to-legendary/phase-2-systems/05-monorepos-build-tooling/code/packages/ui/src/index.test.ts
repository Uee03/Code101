import assert from 'node:assert/strict';
import { test } from 'node:test';
import { button, buttonCss, escapeHtml } from './index.js';

test('button escapes the label', () => {
  assert.equal(
    button('<b>Hi</b>'),
    '<button type="button" class="button button-primary">&lt;b&gt;Hi&lt;/b&gt;</button>',
  );
});

test('escapeHtml handles ampersands first', () => {
  assert.equal(escapeHtml('a & b'), 'a &amp; b');
});

test('css uses tokens, never raw colours', () => {
  assert.ok(!/#[0-9a-f]{3,8}/i.test(buttonCss));
});
