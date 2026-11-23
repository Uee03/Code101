import type { Pair } from './contrast.js';

export const MINIMUM_RATIO = 4.5;

export const CONTRAST_PAIRS: readonly Pair[] = [
  { foreground: 'color-text-default', background: 'color-surface' },
  { foreground: 'color-text-muted', background: 'color-surface' },
  { foreground: 'color-text-default', background: 'color-surface-subtle' },
  { foreground: 'color-text-muted', background: 'color-surface-subtle' },
  { foreground: 'color-action-text', background: 'color-action-background' },
  { foreground: 'color-danger-text', background: 'color-danger-background' },
];
