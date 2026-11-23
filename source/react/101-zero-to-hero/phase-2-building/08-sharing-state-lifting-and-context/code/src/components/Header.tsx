import { useBooks } from '../BooksContext';

export default function Header() {
  const { books, status } = useBooks();
  const unread = books.filter((book) => !book.read).length;
  return (
    <header>
      <h1>Reading list</h1>
      {status === 'success' && <p className="count">{unread} unread</p>}
    </header>
  );
}
