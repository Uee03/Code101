import { books } from '../books';
import BookCard from './BookCard';

export default function BookList() {
  if (books.length === 0) {
    return <p>No books yet.</p>;
  }
  return (
    <ul className="books">
      {books.map((book) => (
        <BookCard
          key={book.id}
          title={book.title}
          author={book.author}
          pages={book.pages}
          read={book.read}
        />
      ))}
    </ul>
  );
}
