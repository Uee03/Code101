---
track: react
level: 101
phase: 3
phase_name: data-and-polish
lesson: 09
title: "Calling an API with fetch (and a first look at TanStack Query)"
time: 80 min
prerequisites: [react.101.2.08]
versions: { node: "26.13.1", npm: "11.20.0", react: "19.3.1", vite: "8.3.8", typescript: "5.9.3", react-router: "8.5.2", tanstack-query: "5.108.3" }
verified: not yet run
source: source/react/101-zero-to-hero/phase-3-data-and-polish/09-calling-an-api-with-fetch/
assets: []
---

# 09. Calling an API with fetch (and a first look at TanStack Query)

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- say what an API, a request, a status code and a header are;
- write one small typed `fetch` helper that checks the status and the content type;
- replace a hand-written loading effect with `useQuery` and read `status`, `isFetching` and `refetch`;
- explain what TanStack Query remembers for you (the cache).

## Recap
1. Which three states did the hand-written loading code in lesson 06 keep? <details><summary>Answer</summary>loading, error and ready (plus the data and the error message).</details>
2. Which hook reads a context? <details><summary>Answer</summary><code>useContext</code> (wrapped by <code>useBooks</code>).</details>

## Why it matters
An API (application programming interface) is a restaurant's order window: you hand in a request in an agreed format, and you get back a plate in an agreed format. Almost every real app is a screen on top of an API. Writing the "ask, wait, handle failure" code by hand in every component gets long, so teams use a library for it. **TanStack Query** is the one used in the capstone at the end of level 201.

## What you will build
The same app, but the books come from `/api/books.json` through one helper function, and the loading logic of lesson 08 is replaced by `useQuery`. You will see a "Reload" button that says "Updating..." while it works.

## Before you start
- Time: 80 minutes. Project `react-app` after lesson 08. Stop the dev server before Step 1.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/react/101-zero-to-hero/phase-3-data-and-polish/09-calling-an-api-with-fetch/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Unchanged: config files, `index.html`, `.gitignore`, `books.ts`, `App.tsx`, `styles.css`, `Header.tsx`, `Footer.tsx`, `Panel.tsx`, `AddBookForm.tsx`, `Counter.tsx`, `BookCard.tsx`, `FilterBar.tsx`, `Home.tsx`, `About.tsx`, `NotFound.tsx` and `BookPage.tsx`.

## Steps

### Step 1. The words you need
- A **request** is what the browser sends: a **method** (`GET` reads, `POST` creates, `PUT`/`PATCH` change, `DELETE` removes), an address (URL), **headers** (labelled extra information such as `Accept: application/json`) and sometimes a **body**.
- A **response** has a **status code** (200 to 299 mean success, 400 to 499 mean the request was wrong, for example 404 "not found", and 500 to 599 mean the server failed), headers (such as `Content-Type`) and a body.
- **JSON** is the text format you used in Web 101 for data.
- In this course the "API" is a static file, `/api/books.json`, served by Vite. A real API is a program that answers the same way, and your code would not change much.

### Step 2. Move the data and install the query library
Make a folder `public/api` and move `public/books.json` into it (file explorer: drag it; delete the old one). The file content stays the same.

**File: `public/api/books.json`**
```json
[
  { "id": 1, "title": "A Field Guide to Birds", "author": "Mira Lind", "pages": 320, "read": true },
  { "id": 2, "title": "Cooking with Beans", "author": "Tomas Reyes", "pages": 180, "read": false },
  { "id": 3, "title": "The Quiet Garden", "author": "Hana Okafor", "pages": 450, "read": false },
  { "id": 4, "title": "Night Trains", "author": "Jonas Weber", "pages": 260, "read": true }
]
```
Replace `package.json` (one new line: `"@tanstack/react-query": "5.108.3"`).

**File: `package.json`**
```json
{
  "name": "react-app",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "@tanstack/react-query": "5.108.3",
    "react": "19.3.1",
    "react-dom": "19.3.1",
    "react-router": "8.5.2"
  },
  "devDependencies": {
    "@types/react": "19.3.0",
    "@types/react-dom": "19.3.0",
    "@vitejs/plugin-react": "6.3.0",
    "typescript": "5.9.3",
    "vite": "8.3.8"
  }
}
```
**Folder: `react-app`**
```powershell
npm install
```
Expected result: a summary such as `added 2 packages` (numbers vary).

### Step 3. Write the fetch helper
**File: `src/api.ts`**
```typescript
import type { Book } from './books';

export class HttpError extends Error {
  status: number;

  constructor(status: number, message: string) {
    super(message);
    this.name = 'HttpError';
    this.status = status;
  }
}

async function getJson<T>(url: string, signal?: AbortSignal): Promise<T> {
  const response = await fetch(url, { signal, headers: { Accept: 'application/json' } });
  if (!response.ok) {
    throw new HttpError(response.status, `Request failed (${response.status})`);
  }
  if (!response.headers.get('Content-Type')?.includes('application/json')) {
    throw new HttpError(response.status, 'The server did not send JSON');
  }
  return (await response.json()) as T;
}

export function fetchBooks(signal?: AbortSignal): Promise<Book[]> {
  return getJson<Book[]>('/api/books.json', signal);
}
```

### Step 4. Provide a QueryClient
**File: `src/main.tsx`**
```tsx
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { createBrowserRouter } from 'react-router';
import { RouterProvider } from 'react-router/dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import App from './App';
import Home from './pages/Home';
import BookPage from './pages/BookPage';
import About from './pages/About';
import NotFound from './pages/NotFound';
import './styles.css';

const queryClient = new QueryClient();

const router = createBrowserRouter([
  {
    path: '/',
    element: <App />,
    children: [
      { index: true, element: <Home /> },
      { path: 'books/:id', element: <BookPage /> },
      { path: 'about', element: <About /> },
      { path: '*', element: <NotFound /> },
    ],
  },
]);

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <RouterProvider router={router} />
    </QueryClientProvider>
  </StrictMode>,
);
```

### Step 5. Use useQuery in the provider
The effect with `fetch` disappears from `BooksProvider`. The books you mark or add are still kept in the browser, because the static file cannot save changes (a real API would, level 201 shows how).

**File: `src/BooksContext.tsx`**
```tsx
import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import { useQuery } from '@tanstack/react-query';
import { fetchBooks } from './api';
import type { Book } from './books';

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
  const [added, setAdded] = useState<Book[]>([]);
  const [flipped, setFlipped] = useState<number[]>([]);

  const books = [...(query.data ?? []), ...added].map((book) =>
    flipped.includes(book.id) ? { ...book, read: !book.read } : book,
  );
  const unreadCount = books.filter((book) => !book.read).length;

  useEffect(() => {
    document.title = query.status === 'success' ? `Reading list (${unreadCount} unread)` : 'Reading list';
  }, [query.status, unreadCount]);

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
```

### Step 6. Show the Reload button and an error retry
**File: `src/components/BookList.tsx`**
```tsx
import { useBooks } from '../BooksContext';
import BookCard from './BookCard';
import AddBookForm from './AddBookForm';

type BookListProps = {
  unreadOnly: boolean;
};

export default function BookList({ unreadOnly }: BookListProps) {
  const { books, status, message, isFetching, reload, toggleRead, addBook } = useBooks();

  if (status === 'pending') {
    return <p role="status">Loading books...</p>;
  }
  if (status === 'error') {
    return (
      <>
        <p role="alert">{message}</p>
        <button type="button" onClick={reload}>
          Try again
        </button>
      </>
    );
  }

  const readCount = books.filter((book) => book.read).length;
  const visible = unreadOnly ? books.filter((book) => !book.read) : books;

  return (
    <>
      <p>
        {readCount} of {books.length} read
      </p>
      <button type="button" onClick={reload} disabled={isFetching}>
        {isFetching ? 'Updating...' : 'Reload'}
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
```

## Run it
**Folder: `react-app`**
```powershell
npm run dev
```
Try:
1. Open `http://localhost:5173/`. Expected: "Loading books..." for a moment, then four cards and a "Reload" button.
2. Open `http://localhost:5173/api/books.json` in a new tab. Expected: the four entries as text: this is what the helper asks for.
3. Click **Reload**. Expected: the button says "Updating..." for a blink and the list stays on screen (no "Loading books..." flash, because Query keeps the old data while it refreshes).
4. Click a title, then Back. Expected: the list is shown at once from the cache.
5. In `api.ts` change `'/api/books.json'` to `'/api/nothing.json'`, save and reload. Typical result: after a few seconds (Query retries three times by default, with waits) the red message `The server did not send JSON` appears with a "Try again" button, because the dev server answers with the HTML page. Change it back.

## How it works
- `getJson` is the only place that calls `fetch`. It checks `response.ok`, checks the `Content-Type` header, parses the JSON, and throws an `HttpError` (a class that extends `Error` and keeps the status) when something is wrong. `<T>` is a **generic**: the caller says what type it expects (`Book[]`). TypeScript cannot check the file's content, so the type is a promise you make. Level 201 adds a validator and a generated client.
- `useQuery({ queryKey, queryFn })` does five jobs: it runs `queryFn` when the component appears, keeps the result in a **cache** under `queryKey` (`['books']`), shares it with every component that asks for the same key, refetches in the background when it may be stale, and reports `status`: `'pending'` (nothing yet), `'error'` or `'success'`.
- `isFetching` is `true` whenever a request is in flight, also during a refresh; `status` is about whether data exists. That is why Reload shows "Updating..." but the list stays.
- `queryFn` receives a `signal`, so Query can cancel requests that are no longer needed.
- `QueryClientProvider` is a context provider, exactly like `BooksProvider`; `QueryClient` holds the cache.
- **What we did not use:** a `POST` to create data. A creating call would look like this (not part of the project):
```typescript
await fetch('/api/books', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ title: 'Moon Maps', author: 'Lea Cho', pages: 210, read: true }),
});
```
Level 201 lesson 02 uses `useMutation` for this.

**Common misconception:** "`fetch` throws on a 404." It does not; only a network failure throws. That is why `getJson` checks `response.ok`.

## Try it
Starter: `exercise/starter/src/main.tsx` (one TODO).
1. **Guided.** Give the `QueryClient` two default options for queries: `staleTime` of 30 seconds and `retry` of 1. Expected: with the wrong address from Run it step 5, the error appears faster (one retry instead of three).
2. **Change.** Click Reload twice within 30 seconds and describe in one sentence what `staleTime` changes. (Hint: it decides when data counts as fresh; an explicit `refetch` always asks again.)
3. **Stretch (optional).** Decide whether the helper should also send an `Authorization` header and where that would live. No code needed.

<details><summary>Solution</summary>

**File: `exercise/solution/src/main.tsx`**
```tsx
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { createBrowserRouter } from 'react-router';
import { RouterProvider } from 'react-router/dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import App from './App';
import Home from './pages/Home';
import BookPage from './pages/BookPage';
import About from './pages/About';
import NotFound from './pages/NotFound';
import './styles.css';

const queryClient = new QueryClient({
  defaultOptions: { queries: { staleTime: 30_000, retry: 1 } },
});

const router = createBrowserRouter([
  {
    path: '/',
    element: <App />,
    children: [
      { index: true, element: <Home /> },
      { path: 'books/:id', element: <BookPage /> },
      { path: 'about', element: <About /> },
      { path: '*', element: <NotFound /> },
    ],
  },
]);

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <RouterProvider router={router} />
    </QueryClientProvider>
  </StrictMode>,
);
```
`30_000` is the number 30000 (the underscore is only for reading); `staleTime` is in milliseconds.

</details>

## Check yourself
1. Which status code range means "the request was wrong"? <details><summary>Answer</summary>400 to 499.</details>
2. What does the query key `['books']` do? <details><summary>Answer</summary>It names the cache entry; every component using the same key shares the data.</details>
3. Predict: `status` is `'success'` and `isFetching` is `true`. What does the user see? <details><summary>Answer</summary>The old list stays on screen while the new data loads (the button says "Updating...").</details>
4. Why does `getJson` check `Content-Type`? <details><summary>Answer</summary>A wrong address may return an HTML page with status 200; the check turns that into a clear error.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `No QueryClient set, use QueryClientProvider to set one` (typical message) | `useQuery` used outside the provider | Wrap the app in `QueryClientProvider` (Step 4) |
| `Cannot find module '@tanstack/react-query'` (typical message) | Package not installed | Edit `package.json`, run `npm install`, restart the dev server |
| The error appears only after several seconds | Default retries with waits | Set `retry` (exercise) or wait |
| `The server did not send JSON` | Wrong path, so the server sent HTML | Check the file is in `public/api/` |
| Marks reset on Reload | The marks are local state, the list is cached server data | Expected here; a real API would store marks |

## Best practice
Put every network call in one small module and let a query library own loading, caching and retries, so components only describe what they show. Source: TanStack Query, Overview https://tanstack.com/query/latest/docs/framework/react/overview

## Going further
- Quick Start: https://tanstack.com/query/latest/docs/framework/react/quick-start
- MDN, Using the Fetch API: https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch

## Summary
- You described requests, responses and status codes.
- You wrote one checked `fetch` helper with a generic type.
- You replaced a hand-written effect with `useQuery` and used `status`, `isFetching` and `refetch`.

## Next lesson
10. Styling and accessibility: icons, a clear focus style and labels that every user can use.
