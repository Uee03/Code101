import { cssVar } from '@code101/tokens';

export type ButtonVariant = 'primary' | 'plain';

export function escapeHtml(text: string): string {
  return text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}

export function button(label: string, variant: ButtonVariant = 'primary'): string {
  return `<button type="button" class="button button-${variant}">${escapeHtml(label)}</button>`;
}

export const buttonCss: string = [
  `.button { background: ${cssVar('color-action-background')}; color: ${cssVar('color-action-text')}; }`,
  `.button-plain { background: ${cssVar('color-surface')}; color: ${cssVar('color-text-default')}; }`,
].join('\n');
