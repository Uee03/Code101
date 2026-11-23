export const tokenNames = [
  'color-surface',
  'color-text-default',
  'color-action-background',
  'color-action-text',
] as const;

export type TokenName = (typeof tokenNames)[number];

export function cssVar(name: TokenName): string {
  return `var(--${name})`;
}
