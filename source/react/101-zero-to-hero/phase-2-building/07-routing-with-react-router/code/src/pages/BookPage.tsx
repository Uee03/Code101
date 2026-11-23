import { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router';
import type { Book } from '../books';

export default function BookPage() {
  const { id } = useParams();
  const [book, setBook] = useState<Book | null>(null);
  const [status, setStatus] = useState<'loading' | 'error' | 'ready'>('loading');

  useEffect(() => {
    const controller = new AbortController();
    async function load() {
      setStatus('loading');
      try {
        const response = await fetch('/books.json', { signal: controller.signal });
        const data: Book[] = await response.json();
        setBook(data.find((item) => String(item.id) === id) ?? null);
        setStatus('ready');
      } catch {
        if (!controller.signal.aborted) {
          setStatus('error');
        }
      }
    }
    void load();
    return () => controller.abort();
  }, [id]);

  if (status === 'loading') {
    return <p role="status">Loading book...</p>;
  }
  if (status === 'error') {
    return <p role="alert">Could not load this book.</p>;
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
