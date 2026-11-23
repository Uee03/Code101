import { useId, useState, type FormEvent } from 'react';
import type { Book } from '../books';
import Icon from './Icon';

type AddBookFormProps = {
  onAdd: (book: Omit<Book, 'id'>) => void;
};

export default function AddBookForm({ onAdd }: AddBookFormProps) {
  const [title, setTitle] = useState('');
  const [author, setAuthor] = useState('');
  const [pages, setPages] = useState('');
  const [read, setRead] = useState(false);
  const [error, setError] = useState('');
  const id = useId();
  const errorId = `${id}-error`;
  const describedBy = error ? errorId : undefined;

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const pageCount = Number(pages);
    if (title.trim() === '' || author.trim() === '') {
      setError('Title and author are required.');
      return;
    }
    if (!Number.isInteger(pageCount) || pageCount < 1) {
      setError('Pages must be a whole number of at least 1.');
      return;
    }
    onAdd({ title: title.trim(), author: author.trim(), pages: pageCount, read });
    setTitle('');
    setAuthor('');
    setPages('');
    setRead(false);
    setError('');
  }

  return (
    <form onSubmit={handleSubmit} noValidate>
      <h3>Add a book</h3>
      <div className="field">
        <label htmlFor={`${id}-title`}>Title</label>
        <input
          id={`${id}-title`}
          value={title}
          aria-describedby={describedBy}
          onChange={(event) => setTitle(event.target.value)}
        />
      </div>
      <div className="field">
        <label htmlFor={`${id}-author`}>Author</label>
        <input
          id={`${id}-author`}
          value={author}
          aria-describedby={describedBy}
          onChange={(event) => setAuthor(event.target.value)}
        />
      </div>
      <div className="field">
        <label htmlFor={`${id}-pages`}>Pages</label>
        <input
          id={`${id}-pages`}
          type="number"
          min="1"
          value={pages}
          aria-describedby={describedBy}
          onChange={(event) => setPages(event.target.value)}
        />
      </div>
      <div className="field">
        <label>
          <input type="checkbox" checked={read} onChange={(event) => setRead(event.target.checked)} /> Already read
        </label>
      </div>
      {error && (
        <p id={errorId} role="alert" className="error">
          {error}
        </p>
      )}
      <button type="submit">
        <Icon name="plus" />
        Add book
      </button>
    </form>
  );
}
