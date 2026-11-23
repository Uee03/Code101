---
track: react
level: 101
phase: 1
phase_name: first-app
lesson: 03
title: "Props and rendering lists"
time: 60 min
prerequisites: [react.101.1.02]
versions: { node: "26.13.1", npm: "11.20.0", react: "19.3.1", vite: "8.3.8", typescript: "5.9.3" }
verified: not yet run
source: source/react/101-zero-to-hero/phase-1-first-app/03-props-and-lists/
assets: []
---

# 03. Props and rendering lists

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- describe a component's inputs with a TypeScript type and pass them as props;
- give a prop a default and make it optional;
- draw one component per array item with `map` and a `key`;
- show something only when a condition is true.

## Recap
1. Why does a component name start with a capital letter? <details><summary>Answer</summary>So React can tell your component from an HTML tag.</details>
2. What do curly braces do inside JSX? <details><summary>Answer</summary>They run an expression and show its result.</details>

## Why it matters
A rubber stamp makes the same card shape every time; only the words you write on it differ. **Props** (short for properties) are the words you write: the same `BookCard` shows any book. And a list on a page is almost always "one card for each item of an array".

## What you will build
A page that shows four book cards from an array. Each card shows the title, the author and number of pages, and a "Read" label or "Not read yet".

## Before you start
- Time: 60 minutes. Project `react-app` after lesson 02, dev server running.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/react/101-zero-to-hero/phase-1-first-app/03-props-and-lists/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Unchanged: all config files, `index.html`, `src/main.tsx`, `src/components/Header.tsx` and `src/components/Footer.tsx`.

## Steps

### Step 1. Write the data
Create `src/books.ts`. A **type** names the shape of an object (you met `type` in Web 101); `Book[]` means "an array of `Book`".

**File: `src/books.ts`**
```typescript
export type Book = {
  id: number;
  title: string;
  author: string;
  pages: number;
  read: boolean;
};

export const books: Book[] = [
  { id: 1, title: 'A Field Guide to Birds', author: 'Mira Lind', pages: 320, read: true },
  { id: 2, title: 'Cooking with Beans', author: 'Tomas Reyes', pages: 180, read: false },
  { id: 3, title: 'The Quiet Garden', author: 'Hana Okafor', pages: 450, read: false },
  { id: 4, title: 'Night Trains', author: 'Jonas Weber', pages: 260, read: true },
];
```
Expected result: no change in the browser. The titles are invented.

### Step 2. Write the BookCard component
**File: `src/components/BookCard.tsx`**
```tsx
type BookCardProps = {
  title: string;
  author: string;
  pages: number;
  read?: boolean;
};

export default function BookCard({ title, author, pages, read = false }: BookCardProps) {
  return (
    <li className="card">
      <h3>{title}</h3>
      <p>
        by {author}, {pages} pages
      </p>
      {read ? <p className="badge">Read</p> : <p>Not read yet</p>}
    </li>
  );
}
```
The `?` in `read?` makes the prop optional and `= false` is its default.

### Step 3. Write BookList
**File: `src/components/BookList.tsx`**
```tsx
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
```

### Step 4. Write Panel (a component with children)
**File: `src/components/Panel.tsx`**
```tsx
import type { ReactNode } from 'react';

type PanelProps = {
  title: string;
  children: ReactNode;
};

export default function Panel({ title, children }: PanelProps) {
  return (
    <section className="panel">
      <h2>{title}</h2>
      {children}
    </section>
  );
}
```

### Step 5. Use them in App
**File: `src/App.tsx`**
```tsx
import Header from './components/Header';
import Footer from './components/Footer';
import Panel from './components/Panel';
import BookList from './components/BookList';

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
        </Panel>
      </main>
      <Footer />
    </>
  );
}
```

### Step 6. Style the cards
Replace the content of `src/styles.css`.

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
Expected result (browser, saved files):
```text
Reading list                         (bar)
My books
 [A Field Guide to Birds / by Mira Lind, 320 pages / Read]
 [Cooking with Beans / by Tomas Reyes, 180 pages / Not read yet]
 [The Quiet Garden / by Hana Okafor, 450 pages / Not read yet]
 [Night Trains / by Jonas Weber, 260 pages / Read]
About
A small app that grows lesson by lesson.
Made with React                      (bar)
```
Each `[...]` is a bordered card; the word "Read" is bold green.

## Run it
**Folder: `react-app`**
```powershell
npm run dev
```
Open `http://localhost:5173/`: the page above appears. Then change `read: false` to `read: true` for book 2 in `books.ts`, save, and watch the card change.

## How it works
- `BookCardProps` is the **contract**: what a parent must pass. `{ title, author, pages, read = false }` is **destructuring**, the same idea as in Web 101: it picks the props out of the one object React passes.
- A parent passes props like HTML attributes: `title={book.title}`. A string literal needs only quotes (`title="My books"`), anything else needs braces.
- Props flow **one way**: parent to child. A child must not change its own props.
- `children` is the special prop for whatever is written **between** the tags: `Panel` shows it under its heading.
- `books.map(...)` turns an array of data into an array of elements. React needs a `key` on each one: a stable, unique value (`book.id`) so it can tell items apart when the list changes. The key is not passed as a prop.
- `{read ? A : B}` shows one of two things; `{condition && <p />}` shows something or nothing. Beware `{items.length && ...}`: when the length is `0`, React prints the number `0`. Compare instead: `items.length > 0 && ...`.
- `BookList` returns early with a message for an empty list: an **empty state**.

**Common misconception:** "the key is a prop I can read in the child." It is not; if the child needs the id, pass it as a second prop with another name.

## Try it
Starter: `exercise/starter/src/components/BookCard.tsx`.
1. **Guided.** Follow the TODO: show `Long read` (class `long`) for a book with more than 400 pages. Expected: only "The Quiet Garden" shows it.
2. **Change.** Add a fifth book to `books.ts` and see a fifth card without changing any component.
3. **Stretch (optional).** Decide what the list should show when every book is read. No single answer; write the text and where it would go.

<details><summary>Solution</summary>

**File: `exercise/solution/src/components/BookCard.tsx`**
```tsx
type BookCardProps = {
  title: string;
  author: string;
  pages: number;
  read?: boolean;
};

export default function BookCard({ title, author, pages, read = false }: BookCardProps) {
  return (
    <li className="card">
      <h3>{title}</h3>
      <p>
        by {author}, {pages} pages
      </p>
      {pages > 400 && <p className="long">Long read</p>}
      {read ? <p className="badge">Read</p> : <p>Not read yet</p>}
    </li>
  );
}
```
`pages > 400` is a boolean, so nothing odd is printed for short books.

</details>

## Check yourself
1. What does `read?: boolean` mean? <details><summary>Answer</summary>The prop is optional; when missing it is `undefined` (here the default `false` applies).</details>
2. Why does each list item need a `key`? <details><summary>Answer</summary>React uses it to match old and new items when the list changes.</details>
3. Predict: `{[].length && <p>Hi</p>}` shows what? <details><summary>Answer</summary>The number <code>0</code>.</details>
4. Find the bug: `<BookCard title={book.title} />` when `author` and `pages` are required. <details><summary>Answer</summary>TypeScript reports missing properties; pass all required props.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Property 'author' is missing in type ... but required in type 'BookCardProps'` (typical message) | A required prop not passed | Pass it, or make it optional in the type |
| Console: `Each child in a list should have a unique "key" prop.` | Missing `key` in `map` | Add `key={book.id}` on the outermost element returned by `map` |
| A stray `0` appears on the page | `{count && ...}` with a number | Use `count > 0 && ...` |
| `Type 'string' is not assignable to type 'number'` (typical message) | `pages="320"` instead of `pages={320}` | Use braces for numbers |
| `Cannot find module '../books'` (typical message) | File name or folder mismatch | `books.ts` sits in `src`, the import path starts with `../` from `components` |

## Best practice
Use a stable id from your data as the `key`, never the array index when items can be added, removed or reordered. Source: Rendering Lists https://react.dev/learn/rendering-lists

## Going further
Passing Props to a Component: https://react.dev/learn/passing-props-to-a-component

## Summary
- You typed a component's props and gave one a default.
- You drew a card per array item with `map` and `key`.
- You used `children` and conditional rendering.

## Next lesson
04. State with `useState` and events: make the cards respond to clicks.
