---
track: react
level: 101
phase: 2
phase_name: building
lesson: 06
title: "Effects and fetching data"
time: 75 min
prerequisites: [react.101.2.05]
versions: { node: "26.13.1", npm: "11.20.0", react: "19.3.1", vite: "8.3.8", typescript: "5.9.3" }
verified: not yet run
source: source/react/101-zero-to-hero/phase-2-building/06-effects-and-fetching-data/
assets: []
---

# 06. Effects and fetching data

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- explain what an effect is and when it runs;
- load data from a file with `fetch` inside `useEffect` and show loading, error and ready states;
- clean up an effect so an old request cannot overwrite newer data;
- change the browser tab title from a component.

## Recap
1. Why must `pages` be converted with `Number(...)` in the form? <details><summary>Answer</summary>Inputs give text.</details>
2. Which hook stores a value between draws? <details><summary>Answer</summary><code>useState</code>.</details>

## Why it matters
When you order food, you do not stand at the counter with a blank plate: you get a number, and the plate comes later. Data that comes from outside the page (a file, a server) arrives later too. An **effect** is code React runs *after* drawing, for work that reaches outside the component: loading data, changing the tab title, starting a timer.

## What you will build
The book list stops being hard-coded. It loads `books.json`, shows "Loading books..." first, shows an error message if loading fails, and keeps the browser tab title in step ("Reading list (2 unread)").

## Before you start
- Time: 75 minutes. Project `react-app` after lesson 05, dev server running.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/react/101-zero-to-hero/phase-2-building/06-effects-and-fetching-data/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Unchanged: config files, `index.html`, `main.tsx`, `App.tsx`, `styles.css`, `AddBookForm.tsx`, `BookCard.tsx`, `Counter.tsx`, `Header.tsx`, `Footer.tsx`, `Panel.tsx`.

## Steps

### Step 1. Put the data in a file the browser can fetch
Make a folder `public` next to `package.json` (hover over the top folder, **New Folder**). Everything in `public` is served as is from the site's root, so `public/books.json` is available at `/books.json`.

**File: `public/books.json`**
```json
[
  { "id": 1, "title": "A Field Guide to Birds", "author": "Mira Lind", "pages": 320, "read": true },
  { "id": 2, "title": "Cooking with Beans", "author": "Tomas Reyes", "pages": 180, "read": false },
  { "id": 3, "title": "The Quiet Garden", "author": "Hana Okafor", "pages": 450, "read": false },
  { "id": 4, "title": "Night Trains", "author": "Jonas Weber", "pages": 260, "read": true }
]
```
Expected result: open `http://localhost:5173/books.json` in the browser and see the four entries as text.

### Step 2. Keep only the type in books.ts
**File: `src/books.ts`**
```typescript
export type Book = {
  id: number;
  title: string;
  author: string;
  pages: number;
  read: boolean;
};
```

### Step 3. Load the data in BookList
Replace the whole file.

**File: `src/components/BookList.tsx`**
```tsx
import { useEffect, useState } from 'react';
import type { Book } from '../books';
import BookCard from './BookCard';
import AddBookForm from './AddBookForm';

export default function BookList() {
  const [items, setItems] = useState<Book[]>([]);
  const [status, setStatus] = useState<'loading' | 'error' | 'ready'>('loading');
  const [message, setMessage] = useState('');
  const [unreadOnly, setUnreadOnly] = useState(false);

  const readCount = items.filter((book) => book.read).length;
  const unreadCount = items.length - readCount;

  useEffect(() => {
    const controller = new AbortController();
    async function load() {
      try {
        const response = await fetch('/books.json', { signal: controller.signal });
        if (!response.ok) {
          throw new Error(`Could not load books (${response.status})`);
        }
        const data: Book[] = await response.json();
        setItems(data);
        setStatus('ready');
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
    document.title = status === 'ready' ? `Reading list (${unreadCount} unread)` : 'Reading list';
  }, [status, unreadCount]);

  function toggleRead(id: number) {
    setItems(items.map((book) => (book.id === id ? { ...book, read: !book.read } : book)));
  }

  function addBook(newBook: Omit<Book, 'id'>) {
    const nextId = Math.max(0, ...items.map((book) => book.id)) + 1;
    setItems([...items, { id: nextId, ...newBook }]);
  }

  if (status === 'loading') {
    return <p role="status">Loading books...</p>;
  }
  if (status === 'error') {
    return <p role="alert">{message}</p>;
  }

  const visible = unreadOnly ? items.filter((book) => !book.read) : items;

  return (
    <>
      <p>
        {readCount} of {items.length} read
      </p>
      <button type="button" onClick={() => setUnreadOnly(!unreadOnly)}>
        {unreadOnly ? 'Show all' : 'Show unread only'}
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
Expected result: after a brief "Loading books..." the same four cards as before appear, and the tab title reads `Reading list (2 unread)`.

## Run it
**Folder: `react-app`**
```powershell
npm run dev
```
Then try the error path: in `BookList.tsx` change `'/books.json'` to `'/nothing.json'`, save, and look. Typical result: the page does not show the 404 text, because the Vite dev server answers unknown addresses with `index.html` (status 200), so `response.json()` fails and the red-text message is a JSON parsing message such as `Unexpected token '<', "<!doctype "... is not valid JSON` (wording differs per browser). Change the address back and save.

## How it works
1. React draws `BookList` the first time with `status` `'loading'`, so the user sees "Loading books...".
2. **After** drawing, React runs each effect function. The first effect calls `fetch`. `fetch` returns a **promise** (you used them in Web 101 lesson 11): the code after `await` runs when the answer arrives.
3. On success, `setItems(data)` and `setStatus('ready')` ask React to draw again, now with data. The early `return` lines (`loading`, `error`) come **after** all hooks, because hooks must always run in the same order.
4. The **dependency array** (the second argument) lists the values the effect uses. `[]` means "run once after the first draw". `[status, unreadCount]` means "run again when either changes". If a value used inside is missing from the list, you read stale data; if there is no array at all, the effect runs after every draw.
5. **Cleanup:** the function you return runs before the effect runs again and when the component disappears. Here it calls `controller.abort()`, which cancels the request. In development `StrictMode` deliberately runs *mount, cleanup, mount* once, so you will see two requests in the Network tab: the first is cancelled. In the finished site there is one. The check `controller.signal.aborted` stops the cancelled request from showing an error.
6. `response.ok` is `true` for status 200 to 299. `fetch` does **not** throw for 404 or 500; you must check yourself.
7. Setting `document.title` reaches outside React (the browser tab), so it is an effect and not part of the JSX.

**Common misconception:** "put everything in `useEffect`." Do not. If a value can be calculated from props and state, calculate it while drawing (`readCount`, `visible`). Effects are for talking to the outside world. Read "You Might Not Need an Effect" (link below).

## Try it
Starter: `exercise/starter/src/components/BookList.tsx` (four TODOs).
1. **Guided.** Add a "Reload" button: add `reloadCount` state, put it in the effect's dependency array, set the status back to `'loading'`, and add the button. Expected: clicking Reload shows "Loading books..." for a moment, then the cards, and the list resets to the file's content (your marks and added books are replaced).
2. **Change.** Make "Reload" also appear on the error screen so the user can try again.
3. **Stretch (optional).** The reset in rung 1 may surprise a user who has marked books. Decide what you would do (ask first? keep marks?) and write one sentence.

<details><summary>Solution</summary>

**File: `exercise/solution/src/components/BookList.tsx`**
```tsx
import { useEffect, useState } from 'react';
import type { Book } from '../books';
import BookCard from './BookCard';
import AddBookForm from './AddBookForm';

export default function BookList() {
  const [items, setItems] = useState<Book[]>([]);
  const [status, setStatus] = useState<'loading' | 'error' | 'ready'>('loading');
  const [message, setMessage] = useState('');
  const [unreadOnly, setUnreadOnly] = useState(false);
  const [reloadCount, setReloadCount] = useState(0);

  const readCount = items.filter((book) => book.read).length;
  const unreadCount = items.length - readCount;

  useEffect(() => {
    const controller = new AbortController();
    async function load() {
      setStatus('loading');
      try {
        const response = await fetch('/books.json', { signal: controller.signal });
        if (!response.ok) {
          throw new Error(`Could not load books (${response.status})`);
        }
        const data: Book[] = await response.json();
        setItems(data);
        setStatus('ready');
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
  }, [reloadCount]);

  useEffect(() => {
    document.title = status === 'ready' ? `Reading list (${unreadCount} unread)` : 'Reading list';
  }, [status, unreadCount]);

  function toggleRead(id: number) {
    setItems(items.map((book) => (book.id === id ? { ...book, read: !book.read } : book)));
  }

  function addBook(newBook: Omit<Book, 'id'>) {
    const nextId = Math.max(0, ...items.map((book) => book.id)) + 1;
    setItems([...items, { id: nextId, ...newBook }]);
  }

  if (status === 'loading') {
    return <p role="status">Loading books...</p>;
  }
  if (status === 'error') {
    return <p role="alert">{message}</p>;
  }

  const visible = unreadOnly ? items.filter((book) => !book.read) : items;

  return (
    <>
      <p>
        {readCount} of {items.length} read
      </p>
      <button type="button" onClick={() => setReloadCount(reloadCount + 1)}>
        Reload
      </button>
      <button type="button" onClick={() => setUnreadOnly(!unreadOnly)}>
        {unreadOnly ? 'Show all' : 'Show unread only'}
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
Changing `reloadCount` makes React run the cleanup of the old effect (abort) and then the effect again. For rung 2 return `<><p role="alert">{message}</p><button type="button" onClick={() => setReloadCount(reloadCount + 1)}>Try again</button></>` in the error branch.

</details>

## Check yourself
1. When does an effect with `[]` run? <details><summary>Answer</summary>Once after the first draw (twice in development StrictMode, with a cleanup between).</details>
2. What does the cleanup function return value do? <details><summary>Answer</summary>React calls it before re-running the effect and when the component leaves the page; here it cancels the request.</details>
3. A server answers 404. Does `fetch` throw? <details><summary>Answer</summary>No. Check <code>response.ok</code> and throw yourself.</details>
4. Predict: you remove `status` from `[status, unreadCount]`. What goes wrong? <details><summary>Answer</summary>The title would not update when loading finishes if the unread count stays the same; the effect would read stale data.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Unexpected token '<', "<!doctype "... is not valid JSON` (typical message) | The address is wrong, so the server sent the page `index.html` | Check the path; put the file in `public` |
| Page loops, many requests | Effect without dependency array that sets state | Add `[]` or the right list |
| Browser tab shows `Reading list` only | Effect not run or `status` not `'ready'` yet | Check `books.json` loads and the browser console |
| `Rendered more hooks than during the previous render.` (typical message) | An early `return` placed before a hook | Move every hook above the early returns |
| `AbortError` in the console | A cancelled request treated as an error | Keep the `controller.signal.aborted` check |
| Cards show `undefined` or wrong values | The file shape does not match `Book` (TypeScript cannot check a file) | Check the keys in `books.json`; level 201 validates data at the edge |

## Best practice
Use effects only to synchronise with something outside React, always return a cleanup for requests, and compute everything else while drawing. Source: You Might Not Need an Effect https://react.dev/learn/you-might-not-need-an-effect

## Going further
Synchronizing with Effects: https://react.dev/learn/synchronizing-with-effects

## Summary
- You loaded data with `fetch` in `useEffect` and showed loading and error states.
- You wrote a dependency array and a cleanup that aborts the request.
- You updated the tab title from an effect.

## Next lesson
07. Routing with React Router: give the app several pages.
