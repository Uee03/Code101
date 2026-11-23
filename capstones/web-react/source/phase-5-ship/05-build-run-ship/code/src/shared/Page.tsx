import type { ReactNode } from 'react';
import { useTitleFocus } from '../core/use-title-focus';
export function Page({ title, children }: { title: string; children: ReactNode }) {
  useTitleFocus(title);
  return <section><h1 tabIndex={-1}>{title}</h1>{children}</section>;
}
