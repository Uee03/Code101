import type { ReactNode } from 'react';

type FieldRenderProps = {
  id: string;
  describedBy: string | undefined;
  invalid: boolean;
};

type FieldProps = {
  name: string;
  label: string;
  hint?: string;
  error?: string;
  children: (props: FieldRenderProps) => ReactNode;
};

export default function Field({ name, label, hint, error, children }: FieldProps) {
  const inputId = `field-${name}`;
  const hintId = `${inputId}-hint`;
  const errorId = `${inputId}-error`;
  const describedBy = [hint ? hintId : '', error ? errorId : ''].filter(Boolean).join(' ') || undefined;
  return (
    <div className="field">
      <label htmlFor={inputId}>{label}</label>
      {hint && (
        <p id={hintId} className="hint">
          {hint}
        </p>
      )}
      {children({ id: inputId, describedBy, invalid: Boolean(error) })}
      {error && (
        <p id={errorId} className="error">
          <span className="visually-hidden">Error: </span>
          {error}
        </p>
      )}
    </div>
  );
}
