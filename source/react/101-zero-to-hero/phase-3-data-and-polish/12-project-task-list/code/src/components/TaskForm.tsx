import { useId, useRef, useState, type FormEvent } from 'react';
import Icon from './Icon';

type TaskFormProps = {
  onAdd: (title: string) => void;
};

export default function TaskForm({ onAdd }: TaskFormProps) {
  const [title, setTitle] = useState('');
  const [error, setError] = useState('');
  const inputRef = useRef<HTMLInputElement>(null);
  const id = useId();
  const errorId = `${id}-error`;

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const trimmed = title.trim();
    if (trimmed === '') {
      setError('Write a task first.');
      inputRef.current?.focus();
      return;
    }
    onAdd(trimmed);
    setTitle('');
    setError('');
    inputRef.current?.focus();
  }

  return (
    <form onSubmit={handleSubmit} noValidate>
      <label htmlFor={`${id}-title`}>New task</label>
      <div className="row">
        <input
          id={`${id}-title`}
          ref={inputRef}
          value={title}
          maxLength={100}
          aria-describedby={error ? errorId : undefined}
          onChange={(event) => setTitle(event.target.value)}
        />
        <button type="submit">
          <Icon name="plus" />
          Add
        </button>
      </div>
      {error && (
        <p id={errorId} role="alert" className="error">
          {error}
        </p>
      )}
    </form>
  );
}
