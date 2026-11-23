import { useRef, useState, type FormEvent } from 'react';

type AddTaskProps = {
  onAdd: (title: string) => void;
};

export default function AddTask({ onAdd }: AddTaskProps) {
  const [title, setTitle] = useState('');
  const inputRef = useRef<HTMLInputElement>(null);

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const trimmed = title.trim();
    if (trimmed !== '') {
      onAdd(trimmed);
      setTitle('');
    }
    inputRef.current?.focus();
  }

  return (
    <form onSubmit={handleSubmit}>
      <label>
        New task <input ref={inputRef} value={title} onChange={(event) => setTitle(event.target.value)} />
      </label>{' '}
      <button type="submit">Add</button>
    </form>
  );
}
