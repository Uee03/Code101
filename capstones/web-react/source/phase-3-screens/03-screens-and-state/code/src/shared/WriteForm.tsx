import { useRef, useState, type ReactNode } from 'react';
import { useOnline } from '../core/connectivity';
import { Icon } from './Icon';
export function Field({ name, label, value = '', required = false, maxLength = 200, type = 'text', pattern }:
  { name: string; label: string; value?: string; required?: boolean; maxLength?: number; type?: string; pattern?: string }) {
  return <label>{label}<input name={name} defaultValue={value} required={required} maxLength={maxLength} type={type} pattern={pattern} /></label>;
}
export function WriteForm({ label, children, submit }: {
  label: string; children: ReactNode; submit: (values: Record<string, string>, key: string) => Promise<unknown>;
}) {
  const online = useOnline(); const [pending, setPending] = useState(false); const [error, setError] = useState('');
  const summary = useRef<HTMLParagraphElement>(null); const attempt = useRef({ body: '', key: '' });
  return <form onSubmit={async event => {
    event.preventDefault(); if (!online || pending) return;
    const values = Object.fromEntries(new FormData(event.currentTarget)) as Record<string, string>;
    const body = JSON.stringify(values);
    if (attempt.current.body !== body || !attempt.current.key) attempt.current = { body, key: crypto.randomUUID() };
    setPending(true); setError('');
    try { await submit(values, attempt.current.key); attempt.current.key = ''; }
    catch (failure) { setError(failure instanceof Error ? failure.message : 'Request failed.'); requestAnimationFrame(() => summary.current?.focus()); }
    finally { setPending(false); }
  }}><p ref={summary} tabIndex={-1} role="alert">{error}</p>{children}
    <button disabled={!online || pending}><Icon name="plus" />{pending ? 'Saving' : label}</button>
  </form>;
}
