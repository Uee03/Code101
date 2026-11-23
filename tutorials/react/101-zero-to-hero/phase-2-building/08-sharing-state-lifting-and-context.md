---
track: react
level: 101
phase: 2
phase_name: building
lesson: 08
title: "Sharing state: lifting up and context"
time: 75 min
prerequisites: [react.101.2.07]
versions: { node: "26.13.1", npm: "11.20.0", react: "19.3.1", vite: "8.3.8", typescript: "5.9.3", react-router: "8.5.2" }
verified: not yet run
source: source/react/101-zero-to-hero/phase-2-building/08-sharing-state-lifting-and-context/
assets: []
---

# 08. Sharing state: lifting up and context

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- decide where a piece of state should live when two components need it;
- lift state up to the nearest common parent and pass it down as props;
- create a context with a provider and a `use...` function, and read it from any depth;
- say when props are better than context.

## Recap
1. How does a child tell its parent that something happened? <details><summary>Answer</summary>By calling a function the parent passed as a prop (<code>onToggle</code>, <code>onAdd</code>).</details>
2. In lesson 07, why was the list fetched twice? <details><summary>Answer</summary>The list page and the detail page each owned their own copy and loaded it separately.</details>

## Why it matters
A family keeps one calendar on the fridge, not one per person, so everybody sees the same plans. State that several components need should live in **one** place above them. If the place is close, pass it by props (lifting up). If it is needed everywhere, put it in a **context**: a shared shelf that any component below can read.

## What you will build
- The "Show unread only" switch becomes a separate `FilterBar` component; the filter state moves up so the bar and the list share it.
- All books, loading status and the actions to mark and add live in one place, `BooksContext`. The header now shows "2 unread" and the detail page no longer fetches again.

## Before you start
- Time: 75 minutes. Project `react-app` after lesson 07, dev server running.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/react/101-zero-to-hero/phase-2-building/08-sharing-state-lifting-and-context/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Unchanged: `package.json`, config files, `index.html`, `.gitignore`, `public/books.json`, `main.tsx`, `books.ts`, `Footer.tsx`, `Panel.tsx`, `AddBookForm.tsx`, `Counter.tsx`, `BookCard.tsx`, `About.tsx` and `NotFound.tsx`.

## Steps

### Step 1. Lifting state up: write FilterBar
Two siblings need the same fact: the bar shows the switch, the list hides read books. Neither can reach the other's state, so the state moves to their parent, `Home`.

**File: `src/components/FilterBar.tsx`**
```tsx
type FilterBarProps = {
  unreadOnly: boolean;
  onChange: (value: boolean) => void;
};

export default function FilterBar({ unreadOnly, onChange }: FilterBarProps) {
  return (
    <label className="filter">
      <input type="checkbox" checked={unreadOnly} onChange={(event) => onChange(event.target.checked)} /> Show
      unread only
    </label>
  );
}
```

**File: `src/pages/Home.tsx`**
```tsx
import { useState } from 'react';
import Panel from '../components/Panel';
import FilterBar from '../components/FilterBar';
import BookList from '../components/BookList';

export default function Home() {
  const [unreadOnly, setUnreadOnly] = useState(false);
  return (
    <Panel title="My books">
      <FilterBar unreadOnly={unreadOnly} onChange={setUnreadOnly} />
      <BookList unreadOnly={unreadOnly} />
    </Panel>
  );
}
```

### Step 2. Create the context
A context needs three parts: the context object, a **provider** component that holds the state, and a small function that reads it. Create `src/BooksContext.tsx` (next to `books.ts`, not in a folder).

**File: `src/BooksContext.tsx`**
```tsx
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
```

### Step 3. Wrap the app in the provider
Everything inside `BooksProvider` can call `useBooks()`. The layout `App` is the right place, because the header, the pages and the list are all below it.

**File: `src/App.tsx`**
```tsx
import { NavLink, Outlet } from 'react-router';
import { BooksProvider } from './BooksContext';
import Header from './components/Header';
import Footer from './components/Footer';

export default function App() {
  return (
    <BooksProvider>
      <Header />
      <nav className="nav" aria-label="Main">
        <NavLink to="/" end>
          Books
        </NavLink>
        <NavLink to="/about">About</NavLink>
      </nav>
      <main>
        <Outlet />
      </main>
      <Footer />
    </BooksProvider>
  );
}
```

### Step 4. Read the context in the components
**File: `src/components/BookList.tsx`**
```tsx
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
```

**File: `src/pages/BookPage.tsx`**
```tsx
import { Link, useParams } from 'react-router';
import { useBooks } from '../BooksContext';

export default function BookPage() {
  const { id } = useParams();
  const { books, status, message } = useBooks();

  if (status === 'pending') {
    return <p role="status">Loading book...</p>;
  }
  if (status === 'error') {
    return <p role="alert">{message}</p>;
  }
  const book = books.find((item) => String(item.id) === id);
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
```

**File: `src/components/Header.tsx`**
```tsx
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
```

### Step 5. Two new style rules
Replace `src/styles.css`. The new rules are `.count` and `.filter`.

**File: `src/styles.css`**
```css
body {
  font-family: system-ui, sans-serif;
  margin: 0;
}

header,
footer {
  background: #e7f0fa;
  padding: 0.5rem 1rem;
}

header h1 {
  margin: 0;
  font-size: 1.5rem;
}

.count {
  margin: 0.25rem 0 0;
}

main {
  max-width: 40rem;
  margin: 0 auto;
  padding: 1rem;
}

.nav {
  display: flex;
  gap: 1rem;
  padding: 0.5rem 1rem;
  border-bottom: 1px solid #66788a;
}

.nav a {
  color: #0759aa;
  padding: 0.25rem 0.5rem;
}

.nav a.active {
  font-weight: bold;
  text-decoration: none;
  border-bottom: 3px solid #0759aa;
}

button {
  font: inherit;
  padding: 0.4rem 0.8rem;
  cursor: pointer;
}

.filter {
  display: block;
  margin: 0.5rem 0;
}

.panel {
  margin-bottom: 1.5rem;
}

.books {
  list-style: none;
  padding: 0;
  display: grid;
  gap: 0.75rem;
}

.card {
  border: 1px solid #66788a;
  border-radius: 0.5rem;
  padding: 0.75rem;
}

.card h3,
.card p {
  margin: 0.25rem 0;
}

.badge {
  color: #0b5d1e;
  font-weight: bold;
}

form {
  margin-top: 1.5rem;
  padding: 0.75rem;
  border: 1px solid #66788a;
  border-radius: 0.5rem;
}

.field {
  margin: 0.5rem 0;
}

.field label {
  display: block;
  margin-bottom: 0.25rem;
}

input[type='text'],
input:not([type]),
input[type='number'] {
  font: inherit;
  padding: 0.4rem;
  width: 100%;
  box-sizing: border-box;
}

.error {
  color: #a11a1a;
  font-weight: bold;
}
```

## Run it
**Folder: `react-app`**
```powershell
npm run dev
```
Try:
1. Open `http://localhost:5173/`. Expected: the header bar shows "Reading list" and under it "2 unread"; below the nav the panel "My books" with a checkbox "Show unread only" and "2 of 4 read".
2. Tick the checkbox. Expected: only two cards remain (Cooking with Beans, The Quiet Garden).
3. Click "Mark as read" on one of them. Expected: the header changes to "1 unread" at once, and the list shows one card.
4. Click a title, then "Back to the list". Expected: the detail page appears instantly without "Loading", and your changes are still there, because the data lives in the provider (which stays mounted) and not in the page. (Reloading the whole browser page resets everything: nothing is saved yet.)

## How it works
- **Lifting state up:** if two components need the same state, move it to their closest common parent, pass the value down as a prop and a setter (or handler) down as a function prop. `Home` owns `unreadOnly`; `FilterBar` shows and changes it; `BookList` reads it.
- **Context:** `createContext<BooksValue | null>(null)` makes a context whose default is `null`. `<BooksContext value={...}>` (a **provider**) makes the value available to all components below it. `useContext(BooksContext)` reads the nearest value. In React 19 the context object itself is the provider tag; older tutorials write `<BooksContext.Provider>`, which also works.
- `useBooks()` is a **custom hook**: our own function whose name starts with `use` and that calls other hooks. It hides `useContext` and throws a clear error when the provider is missing, so the type is never `null` where you use it. Lesson 11 writes more of these.
- When the provider's value changes, every component that reads it draws again. That is fine here (small app); level 201 compares state-management options for bigger apps.
- The detail page needs no fetch any more: the list and the detail page read the same array, so they cannot disagree.

**Common misconception:** "context is the place for all state." Not so. Use props when the data goes one or two levels; use context for things many distant components read (the books, the signed-in user, the theme). Too much context makes it hard to see where data comes from.

## Try it
Starter: `exercise/starter/src/components/Header.tsx` (two TODOs).
1. **Guided.** Make the header show "2 read, 2 unread". Expected: the numbers change when you mark a book.
2. **Change.** In `About.tsx` use `useBooks` to show "You have N books and M pages in total." Compute the total pages with `reduce` or a loop.
3. **Stretch (optional).** Add a second context for a "compact" display setting and decide which components should read it. Explain in one sentence why you used (or did not use) context for it.

<details><summary>Solution</summary>

**File: `exercise/solution/src/components/Header.tsx`**
```tsx
import { useBooks } from '../BooksContext';

export default function Header() {
  const { books, status } = useBooks();
  const unread = books.filter((book) => !book.read).length;
  const read = books.length - unread;
  return (
    <header>
      <h1>Reading list</h1>
      {status === 'success' && (
        <p className="count">
          {read} read, {unread} unread
        </p>
      )}
    </header>
  );
}
```
Both numbers are derived from `books`; nothing new is stored.

</details>

## Check yourself
1. Where should a state live when two siblings need it? <details><summary>Answer</summary>In their closest common parent.</details>
2. What are the three parts of a context in this lesson? <details><summary>Answer</summary>The context object (<code>createContext</code>), the provider component that holds the state, and the <code>useBooks</code> function that reads it.</details>
3. Predict: you call `useBooks()` in a component outside `BooksProvider`. What happens? <details><summary>Answer</summary>It throws <code>useBooks must be used inside BooksProvider</code>.</details>
4. Why does the header update when you mark a book on the list? <details><summary>Answer</summary>Both read the same context value; changing the state in the provider draws every reader again.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `useBooks must be used inside BooksProvider` | A component is outside the provider | Wrap higher: see `App.tsx` |
| Header shows nothing | `status` is not `'success'` yet, or loading failed | Check `/books.json` loads |
| `Property 'unreadOnly' is missing in type '{}'` (typical message) | `<BookList />` without the new prop | Pass `unreadOnly={unreadOnly}` |
| The checkbox does not toggle | `checked` without `onChange` | Add `onChange` that calls `onChange(event.target.checked)` |
| Everything redraws on each keystroke | A rapidly changing value was put in the shared context | Keep fast-changing state (form text) local |

## Best practice
Keep state as local as possible, lift it only as far as needed, and use context for data that many distant components read. Source: Sharing State Between Components https://react.dev/learn/sharing-state-between-components and Passing Data Deeply with Context https://react.dev/learn/passing-data-deeply-with-context

## Going further
Scaling Up with Reducer and Context: https://react.dev/learn/scaling-up-with-reducer-and-context

## Summary
- You lifted a filter's state up to a common parent.
- You built a context with a provider and a `useBooks` function.
- You removed the duplicate fetch and made the header and list share data.

## Next lesson
09. Calling an API with `fetch` and a first look at TanStack Query.
