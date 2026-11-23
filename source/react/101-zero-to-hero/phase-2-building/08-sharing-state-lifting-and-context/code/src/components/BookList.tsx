import { useBooks } from '../BooksContext';
import BookCard from './BookCard';
import AddBookForm from './AddBookForm';

type BookListProps = {
  unreadOnly: boolean;
};

export default function BookList({ unreadOnly }: BookListProps) {
  const { books, status, message, toggleRead, addBook } = useBooks();

  if (status === 'pending') {
    return <p role="status">Loading books...</p>;
  }
  if (status === 'error') {
    return <p role="alert">{message}</p>;
  }

  const readCount = books.filter((book) => book.read).length;
  const visible = unreadOnly ? books.filter((book) => !book.read) : books;

  return (
    <>
      <p>
        {readCount} of {books.length} read
      </p>
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
