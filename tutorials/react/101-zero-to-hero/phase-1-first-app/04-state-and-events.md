---
track: react
level: 101
phase: 1
phase_name: first-app
lesson: 04
title: "State with useState and events"
time: 70 min
prerequisites: [react.101.1.03]
versions: { node: "26.13.1", npm: "11.20.0", react: "19.3.1", vite: "8.3.8", typescript: "5.9.3" }
verified: not yet run
source: source/react/101-zero-to-hero/phase-1-first-app/04-state-and-events/
assets: []
---

# 04. State with useState and events

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- add a piece of state with `useState` and change it from a click;
- explain why you call the setter instead of changing the variable;
- update an array in state without changing the old array;
- compute a value from state instead of storing it twice.

## Recap
1. How does a parent give data to a child? <details><summary>Answer</summary>As props.</details>
2. What is `key` for? <details><summary>Answer</summary>To tell list items apart.</details>

## Why it matters
A scoreboard remembers the score and redraws when it changes. A component is a function that runs again every time something changes, and ordinary variables are forgotten between runs. **State** is the memory React keeps for a component between runs, and it also tells React to redraw.

## What you will build
Each book card gets a button "Mark as read" / "Mark as unread". The list shows "2 of 4 read" and a button that shows only unread books. A small click counter lives in the About panel.

## Before you start
- Time: 70 minutes. Project `react-app` after lesson 03, dev server running.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/react/101-zero-to-hero/phase-1-first-app/04-state-and-events/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Unchanged: config files, `index.html`, `src/main.tsx`, `src/books.ts`, `Header.tsx`, `Footer.tsx` and `Panel.tsx`.

## Steps

### Step 1. Write a counter (the smallest state)
Create `src/components/Counter.tsx`.

**File: `src/components/Counter.tsx`**
```tsx
import { useState } from 'react';

export default function Counter() {
  const [count, setCount] = useState(0);
  return (
    <button type="button" onClick={() => setCount(count + 1)}>
      Clicked {count} times
    </button>
  );
}
```
`useState(0)` returns a pair: the current value (`count`) and a function to replace it (`setCount`). `onClick` is an **event handler**: a function React calls when the click happens.

### Step 2. Show the counter in App
**File: `src/App.tsx`**
```tsx
import Header from './components/Header';
import Footer from './components/Footer';
import Panel from './components/Panel';
import BookList from './components/BookList';
import Counter from './components/Counter';

export default function App() {
  return (
    <>
      <Header />
      <main>
        <Panel title="My books">
          <BookList />
        </Panel>
        <Panel title="About">
          <p>A small app that grows lesson by lesson.</p>
          <Counter />
        </Panel>
      </main>
      <Footer />
    </>
  );
}
```
Expected result: a button "Clicked 0 times". Each click adds 1. Reload the page: it is 0 again (state lives in memory only).

### Step 3. Make BookCard report a click
`BookCard` does not own the "read" fact: the parent does. So the card gets a function prop `onToggle` and calls it with its `id`.

**File: `src/components/BookCard.tsx`**
```tsx
type BookCardProps = {
  id: number;
  title: string;
  author: string;
  pages: number;
  read: boolean;
  onToggle: (id: number) => void;
};

export default function BookCard({ id, title, author, pages, read, onToggle }: BookCardProps) {
  return (
    <li className="card">
      <h3>{title}</h3>
      <p>
        by {author}, {pages} pages
      </p>
      {read ? <p className="badge">Read</p> : <p>Not read yet</p>}
      <button type="button" onClick={() => onToggle(id)}>
        {read ? 'Mark as unread' : 'Mark as read'}
      </button>
    </li>
  );
}
```
`(id: number) => void` is a **function type**: takes a number, returns nothing. Note `onClick={() => onToggle(id)}`: we pass a function that calls `onToggle`, we do not call it while drawing.

### Step 4. Put the state in BookList
**File: `src/components/BookList.tsx`**
```tsx
import { useState } from 'react';
import { books, type Book } from '../books';
import BookCard from './BookCard';

export default function BookList() {
  const [items, setItems] = useState<Book[]>(books);
  const [unreadOnly, setUnreadOnly] = useState(false);

  function toggleRead(id: number) {
    setItems(items.map((book) => (book.id === id ? { ...book, read: !book.read } : book)));
  }

  const readCount = items.filter((book) => book.read).length;
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
    </>
  );
}
```

### Step 5. Style the buttons
Replace `src/styles.css`.

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

main {
  max-width: 40rem;
  margin: 0 auto;
  padding: 1rem;
}

button {
  font: inherit;
  padding: 0.4rem 0.8rem;
  cursor: pointer;
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
```
Expected result when you open the page:
```text
My books
2 of 4 read
[Show unread only]
 four cards, each with a [Mark as read] or [Mark as unread] button
About
A small app that grows lesson by lesson.
[Clicked 0 times]
```
Click "Mark as read" on "Cooking with Beans": the text becomes "3 of 4 read" and the card shows "Read". Click "Show unread only": only "The Quiet Garden" remains, because you just marked the other unread book.

## Run it
**Folder: `react-app`**
```powershell
npm run dev
```
Try: mark two books, press "Show unread only", then "Show all". Nothing is saved: a reload brings back the original four.

## How it works
- Each `useState` call creates **one** memory slot. The first value is the starting value, used only on the first draw.
- Calling `setItems(newArray)` does two things: stores the new value and asks React to run the component again. During that run `items` has the new value. Changing the variable yourself (`items[0].read = true`) does nothing visible, because React is not told.
- **Never change state in place.** `{ ...book, read: !book.read }` builds a **new** object (the spread `...` copies fields) and `map` builds a **new** array. React compares old and new to see that something changed.
- `readCount` and `visible` are **derived**: calculated from `items` and `unreadOnly` every run. If you stored them as extra state, they could disagree with `items`. Rule: store the smallest state, compute the rest.
- Hooks (`useState` is the first) must be called at the top of the component, not inside `if` or loops.
- `onClick`, `onChange`, `onSubmit` are camelCase event props. The handler may receive an **event object** (you use it in lesson 05).

**Common misconception:** "After `setCount(count + 1)` the variable `count` is already new." Within the same click it still has the old value; the new value arrives on the next draw.

## Try it
Starter: `exercise/starter/src/components/BookList.tsx`.
1. **Guided.** Write `markAllRead` and a button "Mark all as read" (two TODOs). Expected: "4 of 4 read" after the click.
2. **Change.** Make the "Mark all as read" button disappear when all books are read.
3. **Stretch (optional).** Add a "Reset" button that returns to the original `books`. Decide whether it should also reset the filter.

<details><summary>Solution</summary>

**File: `exercise/solution/src/components/BookList.tsx`**
```tsx
import { useState } from 'react';
import { books, type Book } from '../books';
import BookCard from './BookCard';

export default function BookList() {
  const [items, setItems] = useState<Book[]>(books);
  const [unreadOnly, setUnreadOnly] = useState(false);

  function toggleRead(id: number) {
    setItems(items.map((book) => (book.id === id ? { ...book, read: !book.read } : book)));
  }

  function markAllRead() {
    setItems(items.map((book) => ({ ...book, read: true })));
  }

  const readCount = items.filter((book) => book.read).length;
  const visible = unreadOnly ? items.filter((book) => !book.read) : items;

  return (
    <>
      <p>
        {readCount} of {items.length} read
      </p>
      <button type="button" onClick={() => setUnreadOnly(!unreadOnly)}>
        {unreadOnly ? 'Show all' : 'Show unread only'}
      </button>
      <button type="button" onClick={markAllRead}>
        Mark all as read
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
    </>
  );
}
```
For rung 2 wrap the button: `{readCount < items.length && (<button ...>Mark all as read</button>)}`.

</details>

## Check yourself
1. What two things does a state setter do? <details><summary>Answer</summary>Stores the new value and asks React to draw the component again.</details>
2. Why `{ ...book, read: !book.read }` and not `book.read = !book.read`? <details><summary>Answer</summary>State must be replaced with a new object; changing it in place is not noticed.</details>
3. Predict: `readCount` after marking two unread books as read, starting from 2 of 4. <details><summary>Answer</summary>4 (shown as "4 of 4 read").</details>
4. Find the bug: `onClick={toggleRead(book.id)}`. <details><summary>Answer</summary>It calls the function while drawing instead of passing a function; write <code>onClick={() =&gt; toggleRead(book.id)}</code>.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| Click does nothing, but code changed `items[0].read` | State changed in place | Replace with `setItems(new array)` |
| `Too many re-renders. React limits the number of renders to prevent an infinite loop.` | Handler called while drawing: `onClick={setCount(1)}` | Pass a function: `onClick={() => setCount(1)}` |
| `React Hook "useState" is called conditionally` or the hooks error `Rendered more hooks than during the previous render.` (typical message) | Hook inside `if` or after an early `return` | Call every hook first, at the top |
| `Type 'string' is not assignable to type 'boolean'` (typical message) | Wrong state type | Give `useState<boolean>(false)` or fix the value |
| The count still shows the old value right after `setCount` | Value updates on the next draw | Use the value in the next render, not in the same handler |

## Best practice
Keep state minimal and derive everything else during the draw. Source: Choosing the State Structure https://react.dev/learn/choosing-the-state-structure

## Going further
State: A Component's Memory https://react.dev/learn/state-a-components-memory and Updating Arrays in State https://react.dev/learn/updating-arrays-in-state

## Summary
- You added state with `useState` and changed it from click handlers.
- You updated an array in state by building a new one.
- You derived the read count and the visible list instead of storing them.

## Next lesson
05. Forms and controlled inputs: add a book with a form.
