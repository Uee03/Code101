import { useBooks } from '../BooksContext';

export default function Header() {
  const { books, status } = useBooks();
  const unread = books.filter((book) => !book.read).length;
  // TODO 1: count the books that are read (the opposite of unread).
  return (
    <header>
      <h1>Reading list</h1>
      {/* TODO 2: show "2 read, 2 unread" (use your count and the unread count) instead of the line below. */}
      {status === 'success' && <p className="count">{unread} unread</p>}
    </header>
  );
}
