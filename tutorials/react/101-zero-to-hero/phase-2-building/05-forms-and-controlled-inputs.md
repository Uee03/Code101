---
track: react
level: 101
phase: 2
phase_name: building
lesson: 05
title: "Forms and controlled inputs"
time: 70 min
prerequisites: [react.101.1.04]
versions: { node: "26.13.1", npm: "11.20.0", react: "19.3.1", vite: "8.3.8", typescript: "5.9.3" }
verified: not yet run
source: source/react/101-zero-to-hero/phase-2-building/05-forms-and-controlled-inputs/
assets: []
---

# 05. Forms and controlled inputs

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- connect an input to state so React always knows what the field contains;
- handle a form submit without a page reload;
- validate input and show an error message;
- add an item to a list held in state.

## Recap
1. Why do we write `{ ...book, read: true }` instead of changing the book? <details><summary>Answer</summary>State must be replaced by a new object so React notices.</details>
2. Which input element did you use for forms in Web 101 lesson 03, and what does `label for` do? <details><summary>Answer</summary><code>input</code> with a <code>label</code>; <code>for</code> ties the label to the field so a click on the label focuses it and screen readers read it.</details>

## Why it matters
A paper form has boxes and a person who checks them before filing. A **controlled input** is a box whose content is kept in a variable you own, so you can check, change or clear it at any time.

## What you will build
Under the book list, a form "Add a book" with title, author, pages and an "Already read" checkbox. A wrong entry shows a red message; a good one adds a new card and empties the form.

## Before you start
- Time: 70 minutes. Project `react-app` after lesson 04, dev server running.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/react/101-zero-to-hero/phase-2-building/05-forms-and-controlled-inputs/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Unchanged: config files, `index.html`, `main.tsx`, `books.ts`, `App.tsx`, `BookCard.tsx`, `Counter.tsx`, `Header.tsx`, `Footer.tsx`, `Panel.tsx`.

## Steps

### Step 1. Write the form component
Create `src/components/AddBookForm.tsx`.

**File: `src/components/AddBookForm.tsx`**
```tsx
import { useId, useState, type FormEvent } from 'react';
import type { Book } from '../books';

type AddBookFormProps = {
  onAdd: (book: Omit<Book, 'id'>) => void;
};

export default function AddBookForm({ onAdd }: AddBookFormProps) {
  const [title, setTitle] = useState('');
  const [author, setAuthor] = useState('');
  const [pages, setPages] = useState('');
  const [read, setRead] = useState(false);
  const [error, setError] = useState('');
  const id = useId();

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const pageCount = Number(pages);
    if (title.trim() === '' || author.trim() === '') {
      setError('Title and author are required.');
      return;
    }
    if (!Number.isInteger(pageCount) || pageCount < 1) {
      setError('Pages must be a whole number of at least 1.');
      return;
    }
    onAdd({ title: title.trim(), author: author.trim(), pages: pageCount, read });
    setTitle('');
    setAuthor('');
    setPages('');
    setRead(false);
    setError('');
  }

  return (
    <form onSubmit={handleSubmit} noValidate>
      <h3>Add a book</h3>
      <div className="field">
        <label htmlFor={`${id}-title`}>Title</label>
        <input id={`${id}-title`} value={title} onChange={(event) => setTitle(event.target.value)} />
      </div>
      <div className="field">
        <label htmlFor={`${id}-author`}>Author</label>
        <input id={`${id}-author`} value={author} onChange={(event) => setAuthor(event.target.value)} />
      </div>
      <div className="field">
        <label htmlFor={`${id}-pages`}>Pages</label>
        <input
          id={`${id}-pages`}
          type="number"
          min="1"
          value={pages}
          onChange={(event) => setPages(event.target.value)}
        />
      </div>
      <div className="field">
        <label>
          <input type="checkbox" checked={read} onChange={(event) => setRead(event.target.checked)} /> Already read
        </label>
      </div>
      {error && (
        <p role="alert" className="error">
          {error}
        </p>
      )}
      <button type="submit">Add book</button>
    </form>
  );
}
```
Expected result: no change in the browser yet.

### Step 2. Add the new book in BookList
**File: `src/components/BookList.tsx`**
```tsx
import { useState } from 'react';
import { books, type Book } from '../books';
import BookCard from './BookCard';
import AddBookForm from './AddBookForm';

export default function BookList() {
  const [items, setItems] = useState<Book[]>(books);
  const [unreadOnly, setUnreadOnly] = useState(false);

  function toggleRead(id: number) {
    setItems(items.map((book) => (book.id === id ? { ...book, read: !book.read } : book)));
  }

  function addBook(newBook: Omit<Book, 'id'>) {
    const nextId = Math.max(0, ...items.map((book) => book.id)) + 1;
    setItems([...items, { id: nextId, ...newBook }]);
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
      <AddBookForm onAdd={addBook} />
    </>
  );
}
```

### Step 3. Style the form
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
Expected result: below the four cards a bordered form with the heading "Add a book", three labelled boxes, a checkbox "Already read" and a button "Add book".

## Run it
**Folder: `react-app`**
```powershell
npm run dev
```
Try these four things in order and compare:
1. Click **Add book** with empty boxes. Expected: red text "Title and author are required."
2. Type title `Moon Maps`, author `Lea Cho`, pages `0`. Expected: "Pages must be a whole number of at least 1."
3. Set pages `210`, tick **Already read**, click **Add book**. Expected: a fifth card "Moon Maps by Lea Cho, 210 pages, Read"; the boxes are empty; the top line says "3 of 5 read".
4. Reload the page. Expected: the new book is gone (saving comes in lesson 11).

## How it works
- A **controlled input** has `value={title}` and `onChange={...setTitle...}`. The state is the single truth: React draws what the state says, and every keystroke asks the state to change first. Without `onChange` a field with `value` would be frozen (React warns).
- `event.target.value` is the text in the field; for a checkbox use `event.target.checked`. A number field still gives text, so `pages` is a string in state and `Number(pages)` converts it when submitting.
- `onSubmit` runs when the user presses the button or Enter. `event.preventDefault()` stops the browser's own submit, which would reload the page. `noValidate` switches off the browser's own bubbles so our messages show; lesson 10 and level 201 return to validation.
- `Omit<Book, 'id'>` is a built-in TypeScript type: `Book` without `id` (the list creates the id).
- `useId()` makes a unique id string, so a label can be tied to its input with `htmlFor` even when the component is used twice on a page.
- `role="alert"` makes a screen reader read the message when it appears.
- Data flows up through a function prop: the form calls `onAdd(...)`, the list owns the array. This is the same pattern as `onToggle`.

**Common misconception:** "I can read the input value when I need it, like `document.querySelector`." In React you keep it in state; the DOM follows the state.

## Try it
Starter: `exercise/starter/src/components/BookList.tsx`.
1. **Guided.** Follow the three TODOs: add `query` state, a labelled search input, and a filter on the title. Expected: typing `the` shows only "The Quiet Garden".
2. **Change.** Make the search ignore leading and trailing spaces and capital letters (the solution does this; check yours with `  NIGHT `).
3. **Stretch (optional).** Show "No books match your search." instead of "Nothing to show." when a search is active. Decide how to detect it.

<details><summary>Solution</summary>

**File: `exercise/solution/src/components/BookList.tsx`**
```tsx
import { useState } from 'react';
import { books, type Book } from '../books';
import BookCard from './BookCard';
import AddBookForm from './AddBookForm';

export default function BookList() {
  const [items, setItems] = useState<Book[]>(books);
  const [unreadOnly, setUnreadOnly] = useState(false);
  const [query, setQuery] = useState('');

  function toggleRead(id: number) {
    setItems(items.map((book) => (book.id === id ? { ...book, read: !book.read } : book)));
  }

  function addBook(newBook: Omit<Book, 'id'>) {
    const nextId = Math.max(0, ...items.map((book) => book.id)) + 1;
    setItems([...items, { id: nextId, ...newBook }]);
  }

  const readCount = items.filter((book) => book.read).length;
  const unreadFiltered = unreadOnly ? items.filter((book) => !book.read) : items;
  const visible = unreadFiltered.filter((book) => book.title.toLowerCase().includes(query.trim().toLowerCase()));

  return (
    <>
      <p>
        {readCount} of {items.length} read
      </p>
      <div className="field">
        <label htmlFor="search">Search titles</label>
        <input id="search" value={query} onChange={(event) => setQuery(event.target.value)} />
      </div>
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
The search text is state; the filtered list is derived from it each draw, exactly like `readCount`.

</details>

## Check yourself
1. What makes an input "controlled"? <details><summary>Answer</summary>Its <code>value</code> comes from state and <code>onChange</code> updates that state.</details>
2. What happens if you forget `event.preventDefault()` in `onSubmit`? <details><summary>Answer</summary>The browser submits the form in the old way and reloads the page, losing state.</details>
3. Predict: pages is `12.5`. What does the form show? <details><summary>Answer</summary>"Pages must be a whole number of at least 1." because <code>Number.isInteger(12.5)</code> is false.</details>
4. Why is `pages` a string in state? <details><summary>Answer</summary>Inputs always give text; convert when you submit.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| Typing in a field does nothing | `value` without `onChange` | Add `onChange` that sets the state |
| Page reloads on submit and the list resets | Missing `event.preventDefault()` | Call it first in the handler |
| `Type 'string' is not assignable to type 'number'` (typical message) | `setPages(event.target.value)` with number state | Keep a string in state, convert on submit |
| Warning: `A component is changing an uncontrolled input to be controlled` (typical message) | `value` starts as `undefined` | Start state with `''` |
| Clicking a label does not focus the box | `htmlFor` and `id` differ | Use the same string in both |
| Checkbox never changes | Used `value` instead of `checked` | `checked={read}` and `event.target.checked` |

## Best practice
Validate on submit, show an error next to the form with `role="alert"`, and keep what the user typed so they can fix it. Source: Reacting to Input with State https://react.dev/learn/reacting-to-input-with-state

## Going further
`<input>` reference: https://react.dev/reference/react-dom/components/input

## Summary
- You made controlled inputs and a controlled checkbox.
- You handled submit with `preventDefault` and showed a validation error.
- You sent a new book up with a function prop and added it to state.

## Next lesson
06. Effects and fetching data: load the books from a file.
