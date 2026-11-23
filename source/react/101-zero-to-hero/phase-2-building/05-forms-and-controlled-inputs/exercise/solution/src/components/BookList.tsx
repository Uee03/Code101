import { useState } from 'react';
import { books, type Book } from '../books';
import BookCard from './BookCard';
import AddBookForm from './AddBookForm';

export default function BookList() {
  const [items, setItems] = useState<Book[]>(books);
  const [unreadOnly, setUnreadOnly] = useState(false);
  const [query, setQuery] = useState('');

  function toggleRead(id: number) {
    setItems(items.map((book) => (book.id === id ? { ...book, read: !book.read } : book)));
  }

  function addBook(newBook: Omit<Book, 'id'>) {
    const nextId = Math.max(0, ...items.map((book) => book.id)) + 1;
    setItems([...items, { id: nextId, ...newBook }]);
  }

  const readCount = items.filter((book) => book.read).length;
  const unreadFiltered = unreadOnly ? items.filter((book) => !book.read) : items;
  const visible = unreadFiltered.filter((book) => book.title.toLowerCase().includes(query.trim().toLowerCase()));

  return (
    <>
      <p>
        {readCount} of {items.length} read
      </p>
      <div className="field">
        <label htmlFor="search">Search titles</label>
        <input id="search" value={query} onChange={(event) => setQuery(event.target.value)} />
      </div>
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
