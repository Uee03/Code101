import { createContext, useContext, type ReactNode } from 'react';
import { useQuery } from '@tanstack/react-query';
import { fetchBooks } from './api';
import type { Book } from './books';
import useLocalStorage from './hooks/useLocalStorage';

type BooksValue = {
  books: Book[];
  status: 'pending' | 'error' | 'success';
  message: string;
  isFetching: boolean;
  reload: () => void;
  toggleRead: (id: number) => void;
  addBook: (book: Omit<Book, 'id'>) => void;
};

const BooksContext = createContext<BooksValue | null>(null);

export function BooksProvider({ children }: { children: ReactNode }) {
  const query = useQuery({ queryKey: ['books'], queryFn: ({ signal }) => fetchBooks(signal) });
  const [added, setAdded] = useLocalStorage<Book[]>('reading-list.added', []);
  const [flipped, setFlipped] = useLocalStorage<number[]>('reading-list.flipped', []);

  const books = [...(query.data ?? []), ...added].map((book) =>
    flipped.includes(book.id) ? { ...book, read: !book.read } : book,
  );

  function toggleRead(id: number) {
    setFlipped(flipped.includes(id) ? flipped.filter((item) => item !== id) : [...flipped, id]);
  }

  function addBook(newBook: Omit<Book, 'id'>) {
    const nextId = Math.max(0, ...books.map((book) => book.id)) + 1;
    setAdded([...added, { id: nextId, ...newBook }]);
  }

  const value: BooksValue = {
    books,
    status: query.status,
    message: query.error?.message ?? '',
    isFetching: query.isFetching,
    reload: () => void query.refetch(),
    toggleRead,
    addBook,
  };
  return <BooksContext value={value}>{children}</BooksContext>;
}

export function useBooks(): BooksValue {
  const value = useContext(BooksContext);
  if (!value) {
    throw new Error('useBooks must be used inside BooksProvider');
  }
  return value;
}
