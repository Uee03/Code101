import { useEffect, useState } from 'react';
import type { Book } from '../books';
import BookCard from './BookCard';
import AddBookForm from './AddBookForm';

export default function BookList() {
  const [items, setItems] = useState<Book[]>([]);
  const [status, setStatus] = useState<'loading' | 'error' | 'ready'>('loading');
  const [message, setMessage] = useState('');
  const [unreadOnly, setUnreadOnly] = useState(false);
  const [reloadCount, setReloadCount] = useState(0);

  const readCount = items.filter((book) => book.read).length;
  const unreadCount = items.length - readCount;

  useEffect(() => {
    const controller = new AbortController();
    async function load() {
      setStatus('loading');
      try {
        const response = await fetch('/books.json', { signal: controller.signal });
        if (!response.ok) {
          throw new Error(`Could not load books (${response.status})`);
        }
        const data: Book[] = await response.json();
        setItems(data);
        setStatus('ready');
      } catch (error) {
        if (controller.signal.aborted) {
          return;
        }
        setMessage(error instanceof Error ? error.message : 'Could not load books');
        setStatus('error');
      }
    }
    void load();
    return () => controller.abort();
  }, [reloadCount]);

  useEffect(() => {
    document.title = status === 'ready' ? `Reading list (${unreadCount} unread)` : 'Reading list';
  }, [status, unreadCount]);

  function toggleRead(id: number) {
    setItems(items.map((book) => (book.id === id ? { ...book, read: !book.read } : book)));
  }

  function addBook(newBook: Omit<Book, 'id'>) {
    const nextId = Math.max(0, ...items.map((book) => book.id)) + 1;
    setItems([...items, { id: nextId, ...newBook }]);
  }

  if (status === 'loading') {
    return <p role="status">Loading books...</p>;
  }
  if (status === 'error') {
    return <p role="alert">{message}</p>;
  }

  const visible = unreadOnly ? items.filter((book) => !book.read) : items;

  return (
    <>
      <p>
        {readCount} of {items.length} read
      </p>
      <button type="button" onClick={() => setReloadCount(reloadCount + 1)}>
        Reload
      </button>
      <button type="button" onClick={() => setUnreadOnly(!unreadOnly)}>
        {unreadOnly ? 'Show all' : 'Show unread only'}
      </button>
      {visible.length === 0 ? (
        <p>Nothing to show.</p>
      ) : (
        <ul className="books">
          {visible.map((book) => (
            <BookCard
              key={book.id}
              id={book.id}
              title={book.title}
              author={book.author}
              pages={book.pages}
              read={book.read}
              onToggle={toggleRead}
            />
          ))}
        </ul>
      )}
      <AddBookForm onAdd={addBook} />
    </>
  );
}
