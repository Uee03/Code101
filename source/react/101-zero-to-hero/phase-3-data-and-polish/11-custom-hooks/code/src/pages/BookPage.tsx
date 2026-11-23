import { Link, useParams } from 'react-router';
import { useBooks } from '../BooksContext';
import usePageTitle from '../hooks/usePageTitle';

export default function BookPage() {
  const { id } = useParams();
  const { books, status, message } = useBooks();
  const book = books.find((item) => String(item.id) === id);
  usePageTitle(book ? `${book.title} - Reading list` : 'Reading list');

  if (status === 'pending') {
    return <p role="status">Loading book...</p>;
  }
  if (status === 'error') {
    return <p role="alert">{message}</p>;
  }
  if (!book) {
    return (
      <section>
        <h2>Book not found</h2>
        <Link to="/">Back to the list</Link>
      </section>
    );
  }
  return (
    <article>
      <h2>{book.title}</h2>
      <p>
        by {book.author}, {book.pages} pages
      </p>
      <p>{book.read ? 'You have read this book.' : 'You have not read this book yet.'}</p>
      <Link to="/">Back to the list</Link>
    </article>
  );
}
