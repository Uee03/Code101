import type { RefObject } from 'react';
import type { FieldErrors } from '../forms/validate';

type ErrorSummaryProps = {
  errors: FieldErrors;
  headingRef: RefObject<HTMLHeadingElement | null>;
};

export default function ErrorSummary({ errors, headingRef }: ErrorSummaryProps) {
  const entries = Object.entries(errors);
  if (entries.length === 0) {
    return null;
  }
  return (
    <section className="summary" aria-labelledby="summary-title">
      <h2 id="summary-title" ref={headingRef} tabIndex={-1}>
        There {entries.length === 1 ? 'is 1 problem' : `are ${entries.length} problems`} with the form
      </h2>
      <ul>
        {entries.map(([name, message]) => (
          <li key={name}>
            <a
              href={`#field-${name}`}
              onClick={(event) => {
                event.preventDefault();
                document.getElementById(`field-${name}`)?.focus();
              }}
            >
              {message}
            </a>
          </li>
        ))}
      </ul>
    </section>
  );
}
