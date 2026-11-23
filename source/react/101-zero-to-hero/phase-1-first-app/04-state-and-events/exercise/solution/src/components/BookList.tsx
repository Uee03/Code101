import { useState } from 'react';
import { books, type Book } from '../books';
import BookCard from './BookCard';

export default function BookList() {
  const [items, setItems] = useState<Book[]>(books);
  const [unreadOnly, setUnreadOnly] = useState(false);

  function toggleRead(id: number) {
    setItems(items.map((book) => (book.id === id ? { ...book, read: !book.read } : book)));
  }

  function markAllRead() {
    setItems(items.map((book) => ({ ...book, read: true })));
  }

  const readCount = items.filter((book) => book.read).length;
  const visible = unreadOnly ? items.filter((book) => !book.read) : items;

  return (
    <>
      <p>
        {readCount} of {items.length} read
      </p>
      <button type="button" onClick={() => setUnreadOnly(!unreadOnly)}>
        {unreadOnly ? 'Show all' : 'Show unread only'}
      </button>
      <button type="button" onClick={markAllRead}>
        Mark all as read
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
    </>
  );
}
