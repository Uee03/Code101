---
track: react
level: 101
phase: 3
phase_name: data-and-polish
lesson: 11
title: "Custom hooks"
time: 70 min
prerequisites: [react.101.3.10]
versions: { node: "26.13.1", npm: "11.20.0", react: "19.3.1", vite: "8.3.8", typescript: "5.9.3" }
verified: not yet run
source: source/react/101-zero-to-hero/phase-3-data-and-polish/11-custom-hooks/
assets: []
---

# 11. Custom hooks

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- state the two rules of hooks and say why they exist;
- extract repeated hook logic into your own `use...` function;
- write a generic hook (`useLocalStorage<T>`) that saves state in the browser;
- reuse a hook in several components.

## Recap
1. Which hook did you use to run code after drawing? <details><summary>Answer</summary><code>useEffect</code>.</details>
2. What was `useBooks()`? <details><summary>Answer</summary>A small function of ours that calls <code>useContext</code>: a custom hook.</details>

## Why it matters
A recipe card for "make the sauce" lets every dish reuse the same steps. If three pages set the tab title with the same four lines, or two places save to the browser the same way, a **custom hook** is that recipe card: a function that starts with `use` and may call other hooks.

## What you will build
- `usePageTitle(title)`: sets the tab title; used on every page.
- `useLocalStorage(key, initial)`: like `useState` but the value survives a reload. It stores the books you add, the books you mark and the "unread only" switch.

## Before you start
- Time: 70 minutes. Project `react-app` after lesson 10, dev server running.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/react/101-zero-to-hero/phase-3-data-and-polish/11-custom-hooks/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Unchanged: all other files, including `package.json`, `main.tsx`, `App.tsx`, `styles.css`, `api.ts`, the icon files and all components.

## Steps

### Step 1. The two rules of hooks
1. Call hooks only at the **top level** of a component or of another hook: never inside `if`, loops or nested functions. React remembers hooks by their order, so the order must be the same every time.
2. Call hooks only from components or custom hooks, not from ordinary functions.
A custom hook's name must start with `use`, so tools and people can see that rule 1 applies.

### Step 2. Write usePageTitle
Create the folder `src/hooks`.

**File: `src/hooks/usePageTitle.ts`**
```typescript
import { useEffect } from 'react';

export default function usePageTitle(title: string) {
  useEffect(() => {
    document.title = title;
  }, [title]);
}
```

### Step 3. Write useLocalStorage
`localStorage` is a small key-value store in the browser that survives reloads (about 5 MB, text only). It is not secure and not private: never store passwords or tokens in it.

**File: `src/hooks/useLocalStorage.ts`**
```typescript
import { useEffect, useState } from 'react';

export default function useLocalStorage<T>(key: string, initial: T) {
  const [value, setValue] = useState<T>(() => {
    try {
      const stored = window.localStorage.getItem(key);
      return stored === null ? initial : (JSON.parse(stored) as T);
    } catch {
      return initial;
    }
  });

  useEffect(() => {
    try {
      window.localStorage.setItem(key, JSON.stringify(value));
    } catch {
      // Storage can be full or blocked; the app keeps working without saving.
    }
  }, [key, value]);

  return [value, setValue] as const;
}
```

### Step 4. Use useLocalStorage in the provider
The `useEffect` that set the title is removed from the provider; each page sets its own title now.

**File: `src/BooksContext.tsx`**
```tsx
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
```

### Step 5. Use usePageTitle (and the storage) in the pages
**File: `src/pages/Home.tsx`**
```tsx
import Panel from '../components/Panel';
import FilterBar from '../components/FilterBar';
import BookList from '../components/BookList';
import { useBooks } from '../BooksContext';
import useLocalStorage from '../hooks/useLocalStorage';
import usePageTitle from '../hooks/usePageTitle';

export default function Home() {
  const [unreadOnly, setUnreadOnly] = useLocalStorage('reading-list.unreadOnly', false);
  const { books, status } = useBooks();
  const unread = books.filter((book) => !book.read).length;
  usePageTitle(status === 'success' ? `Reading list (${unread} unread)` : 'Reading list');
  return (
    <Panel title="My books">
      <FilterBar unreadOnly={unreadOnly} onChange={setUnreadOnly} />
      <BookList unreadOnly={unreadOnly} />
    </Panel>
  );
}
```

**File: `src/pages/About.tsx`**
```tsx
import Panel from '../components/Panel';
import Counter from '../components/Counter';
import usePageTitle from '../hooks/usePageTitle';

export default function About() {
  usePageTitle('About - Reading list');
  return (
    <Panel title="About">
      <p>A small app that grows lesson by lesson.</p>
      <Counter />
    </Panel>
  );
}
```

**File: `src/pages/NotFound.tsx`**
```tsx
import { Link } from 'react-router';
import usePageTitle from '../hooks/usePageTitle';

export default function NotFound() {
  usePageTitle('Page not found - Reading list');
  return (
    <section>
      <h2>Page not found</h2>
      <p>There is nothing at this address.</p>
      <Link to="/">Back to the list</Link>
    </section>
  );
}
```

**File: `src/pages/BookPage.tsx`**
```tsx
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
```
In `BookPage` the hook call sits **before** the early returns: rule 1.

## Run it
**Folder: `react-app`**
```powershell
npm run dev
```
Try:
1. Mark a book as read, add a book "Moon Maps", tick "Show unread only". Reload the browser page (F5). Expected: all three changes are still there.
2. Click a title. Expected: the tab title becomes `<book title> - Reading list`.
3. Open DevTools (F12), choose **Application** (Chromium browsers) or **Storage** (Firefox), then Local Storage. Expected: three keys starting `reading-list.`. Delete them and reload to start fresh.

## How it works
- A custom hook is an ordinary function that calls built-in hooks. Each component that calls it gets **its own** copy of the state; the hook shares **logic**, not data (sharing data is what context was for).
- `useLocalStorage<T>` is **generic**: `T` is filled in by the caller (`Book[]`, `number[]`, `boolean`). `useState(() => ...)` gets a **function** as its starting value (a **lazy initial state**): React calls it only on the first draw, so we read `localStorage` once, not on every draw.
- `JSON.stringify` turns the value into text for storage and `JSON.parse` turns it back; the `try/catch` handles missing, broken or blocked storage.
- `as const` makes the return a fixed pair (`readonly [T, Dispatch<...>]`) instead of an array, so callers can destructure it like `useState`.
- The effect saves after every change to `key` or `value`.
- Notice what is **not** saved: the books from `/api/books.json`; only your changes are. The cached server data and your local changes stay separate.

**Common misconception:** "a custom hook shares state between components." It does not; each call has its own state. Two components that need the same state still need lifting up or context.

## Try it
Starter: `exercise/starter/src/hooks/useToggle.ts` and `exercise/starter/src/pages/About.tsx`.
1. **Guided.** Write `useToggle(initial)` that returns `[value, toggle]`, and add the button in `About.tsx` (two TODOs). Expected: "Show details" reveals "Built with React, TypeScript and Vite." and the button text becomes "Hide details".
2. **Change.** Make the About page remember the open state with `useLocalStorage` instead of `useState` inside `useToggle`. Decide which of the two hooks should call the other.
3. **Stretch (optional).** Write `useOnline()` that returns `true` or `false` using the browser's `online` and `offline` events (with cleanup in the effect).

<details><summary>Solution</summary>

**File: `exercise/solution/src/hooks/useToggle.ts`**
```typescript
import { useState } from 'react';

export default function useToggle(initial: boolean) {
  const [value, setValue] = useState(initial);
  function toggle() {
    setValue((current) => !current);
  }
  return [value, toggle] as const;
}
```

**File: `exercise/solution/src/pages/About.tsx`**
```tsx
import Panel from '../components/Panel';
import Counter from '../components/Counter';
import usePageTitle from '../hooks/usePageTitle';
import useToggle from '../hooks/useToggle';

export default function About() {
  usePageTitle('About - Reading list');
  const [open, toggle] = useToggle(false);
  return (
    <Panel title="About">
      <p>A small app that grows lesson by lesson.</p>
      <button type="button" onClick={toggle} aria-expanded={open}>
        {open ? 'Hide details' : 'Show details'}
      </button>
      {open && <p>Built with React, TypeScript and Vite.</p>}
      <Counter />
    </Panel>
  );
}
```
`setValue((current) => !current)` is an **updater function**: React hands it the latest value, which is safer than `setValue(!value)` when several updates happen together. `aria-expanded` tells a screen reader whether the button's content is shown.

</details>

## Check yourself
1. Why can't you call a hook inside an `if`? <details><summary>Answer</summary>React matches hooks by call order; a hook that is sometimes skipped breaks the order.</details>
2. Do two components using `useLocalStorage('a', 0)` share one state? <details><summary>Answer</summary>No; each has its own state. They read the same stored value only at start.</details>
3. Predict: `localStorage` is full. What happens when you mark a book? <details><summary>Answer</summary>The catch block ignores the save error; the app keeps working but the change is lost on reload.</details>
4. Why does the lazy initial state matter? <details><summary>Answer</summary>The function runs only on the first draw, so storage is read once.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `React Hook "usePageTitle" is called conditionally` or `Rendered more hooks than during the previous render.` (typical message) | Hook after an early `return` | Move the hook above the returns |
| `Cannot find module '../hooks/useLocalStorage'` (typical message) | Wrong folder or name | Files are in `src/hooks`, names match exactly |
| Changes vanish after reload | Wrong storage key, or storage blocked (private window) | Check the key in DevTools; try a normal window |
| The tab title flickers between two texts | Two places set `document.title` | Keep one owner per page (the provider no longer sets it) |
| Old data after you changed the shape of a saved value | Stored text has the old shape | Delete the `reading-list.*` keys in DevTools |

## Best practice
Extract a custom hook when the same logic appears twice, name it `useThing`, and keep it free of JSX. Source: Reusing Logic with Custom Hooks https://react.dev/learn/reusing-logic-with-custom-hooks

## Going further
Rules of Hooks: https://react.dev/reference/rules/rules-of-hooks

## Summary
- You wrote two custom hooks and used them in several components.
- You saved state in `localStorage` and restored it with a lazy initial value.
- You explained that hooks share logic, not data.

## Next lesson
12. Project: a task list app that uses everything from this track in a new project.
