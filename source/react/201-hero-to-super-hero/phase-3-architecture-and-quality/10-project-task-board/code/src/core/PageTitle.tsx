import { useEffect, useRef } from 'react';
import { useNavigationType } from 'react-router';

type PageTitleProps = {
  children: string;
};

// The page heading: sets the document title and, after a link navigation, moves keyboard focus to the heading.
export default function PageTitle({ children }: PageTitleProps) {
  const heading = useRef<HTMLHeadingElement>(null);
  const navigationType = useNavigationType();

  useEffect(() => {
    document.title = `${children} - Task board`;
  }, [children]);

  useEffect(() => {
    if (navigationType !== 'POP') {
      heading.current?.focus();
    }
  }, [navigationType]);

  return (
    <h1 ref={heading} tabIndex={-1}>
      {children}
    </h1>
  );
}
