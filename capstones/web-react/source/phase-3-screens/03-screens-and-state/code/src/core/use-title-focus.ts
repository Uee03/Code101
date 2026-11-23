import { useLocation } from 'react-router';
import { useEffect } from 'react';
export function useTitleFocus(title: string) {
  const location = useLocation();
  useEffect(() => {
    document.title = `${title} | Tasks and Teams`;
    document.querySelector<HTMLHeadingElement>('h1')?.focus();
  }, [title, location.key]);
}
