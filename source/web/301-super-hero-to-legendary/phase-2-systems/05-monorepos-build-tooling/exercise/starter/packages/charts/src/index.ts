import { cssVar } from '@code101/tokens';

// TODO 1: this import works today only by accident. Declare the dependency in package.json.
// TODO 2: tell TypeScript about it with "references" in tsconfig.json.
// TODO 3: add this project to the root tsconfig.json references.
export function barColor(): string {
  return cssVar('color-action-background');
}
