import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import type { Book } from './books';

type BooksValue = {
  books: Book[];
  status: 'pending' | 'error' | 'success';
  message: string;
  toggleRead: (id: number) => void;
  addBook: (book: Omit<Book, 'id'>) => void;
};

const BooksContext = createContext<BooksValue | null>(null);

export function BooksProvider({ children }: { children: ReactNode }) {
  const [books, setBooks] = useState<Book[]>([]);
  const [status, setStatus] = useState<BooksValue['status']>('pending');
  const [message, setMessage] = useState('');

  const unreadCount = books.filter((book) => !book.read).length;

  useEffect(() => {
    const controller = new AbortController();
    async function load() {
      try {
        const response = await fetch('/books.json', { signal: controller.signal });
        if (!response.ok) {
          throw new Error(`Could not load books (${response.status})`);
        }
        const data: Book[] = await response.json();
        setBooks(data);
        setStatus('success');
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
  }, []);

  useEffect(() => {
    document.title = status === 'success' ? `Reading list (${unreadCount} unread)` : 'Reading list';
  }, [status, unreadCount]);

  function toggleRead(id: number) {
    setBooks(books.map((book) => (book.id === id ? { ...book, read: !book.read } : book)));
  }

  function addBook(newBook: Omit<Book, 'id'>) {
    const nextId = Math.max(0, ...books.map((book) => book.id)) + 1;
    setBooks([...books, { id: nextId, ...newBook }]);
  }

  return <BooksContext value={{ books, status, message, toggleRead, addBook }}>{children}</BooksContext>;
}

export function useBooks(): BooksValue {
  const value = useContext(BooksContext);
  if (!value) {
    throw new Error('useBooks must be used inside BooksProvider');
  }
  return value;
}
