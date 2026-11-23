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
