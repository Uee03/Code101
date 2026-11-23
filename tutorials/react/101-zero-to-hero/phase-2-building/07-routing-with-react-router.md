---
track: react
level: 101
phase: 2
phase_name: building
lesson: 07
title: "Routing with React Router"
time: 75 min
prerequisites: [react.101.2.06]
versions: { node: "26.13.1", npm: "11.20.0", react: "19.3.1", vite: "8.3.8", typescript: "5.9.3", react-router: "8.5.2" }
verified: not yet run
source: source/react/101-zero-to-hero/phase-2-building/07-routing-with-react-router/
assets: []
---

# 07. Routing with React Router

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- explain what a single-page app is and what a router does;
- define routes (pages), a layout with `Outlet` and a catch-all "not found" route;
- link between pages with `Link` and `NavLink` without a page reload;
- read a value from the address with `useParams`.

## Recap
1. What does the dependency array `[id]` of an effect mean? <details><summary>Answer</summary>Run the effect after the first draw and again whenever <code>id</code> changes.</details>
2. What does `fetch` do for a 404? <details><summary>Answer</summary>It does not throw; check <code>response.ok</code>.</details>

## Why it matters
A hotel has one building and many rooms; the room number on your key tells you where to go. A **single-page app** has one HTML page and many "rooms" (screens). The **router** reads the address (`/about`, `/books/3`), decides which room to show, and changes the address when you click a link, without loading a new page.

## What you will build
Three screens: the book list at `/`, a detail page for one book at `/books/1`, `/books/2` and so on, and an About page at `/about`, plus a "Page not found" screen for any other address. A navigation bar sits on top of all of them.

## Before you start
- Time: 75 minutes. Project `react-app` after lesson 06.
- Stop the dev server (Ctrl+C in its terminal) before Step 1.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/react/101-zero-to-hero/phase-2-building/07-routing-with-react-router/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Unchanged: `vite.config.ts`, the three `tsconfig` files, `index.html`, `.gitignore`, `public/books.json`, `books.ts`, `Header.tsx`, `Footer.tsx`, `Panel.tsx`, `AddBookForm.tsx`, `Counter.tsx` and `BookList.tsx`.

## Steps

### Step 1. Add the router package
Replace `package.json`. The only change is one new line in `dependencies`: `"react-router": "8.5.2"` (and the comma after `react-dom`).

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
Then in the terminal:

**Folder: `react-app`**
```powershell
npm install
```
Expected result: npm prints a summary such as `added 3 packages` (the number varies; do not worry about it) and updates `package-lock.json`.

### Step 2. Write the pages
Make a folder `src/pages` and create the four files.

**File: `src/pages/Home.tsx`**
```tsx
import Panel from '../components/Panel';
import BookList from '../components/BookList';

export default function Home() {
  return (
    <Panel title="My books">
      <BookList />
    </Panel>
  );
}
```

**File: `src/pages/About.tsx`**
```tsx
import Panel from '../components/Panel';
import Counter from '../components/Counter';

export default function About() {
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

export default function NotFound() {
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
```
Note the repeated `fetch` code: this page loads the list again and looks for its book. That duplication is on purpose; lesson 08 fixes it.

### Step 3. Make App the layout
`App` no longer shows the books itself. It draws the parts every page shares and an `Outlet`, the hole where the current page appears.

**File: `src/App.tsx`**
```tsx
import { NavLink, Outlet } from 'react-router';
import Header from './components/Header';
import Footer from './components/Footer';

export default function App() {
  return (
    <>
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
    </>
  );
}
```

### Step 4. Define the routes in main.tsx
**File: `src/main.tsx`**
```tsx
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { createBrowserRouter } from 'react-router';
import { RouterProvider } from 'react-router/dom';
import App from './App';
import Home from './pages/Home';
import BookPage from './pages/BookPage';
import About from './pages/About';
import NotFound from './pages/NotFound';
import './styles.css';

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
    <RouterProvider router={router} />
  </StrictMode>,
);
```

### Step 5. Link the cards to their page
**File: `src/components/BookCard.tsx`**
```tsx
import { Link } from 'react-router';

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
      <h3>
        <Link to={`/books/${id}`}>{title}</Link>
      </h3>
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

### Step 6. Style the navigation
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
Try, in order:
1. Open `http://localhost:5173/`. Expected: the bar with **Books** (bold, underlined) and **About**, and the four cards; each title is now a link.
2. Click "Night Trains". Expected: the address becomes `http://localhost:5173/books/4`, the page shows the heading "Night Trains", "by Jonas Weber, 260 pages" and "You have read this book.", and the browser did not reload.
3. Click the browser's Back button. Expected: the list returns.
4. Click **About**. Expected: `/about`, the About panel and the counter.
5. Type `http://localhost:5173/books/99` in the address bar. Expected: "Book not found" with a link back.
6. Type `http://localhost:5173/nothing`. Expected: "Page not found".

## How it works
- `createBrowserRouter` takes a list of **route objects**. Each says "when the address matches `path`, draw `element`". `RouterProvider` (imported from `react-router/dom`) starts the router and listens to the address.
- `children` nest routes inside the layout route: React draws `App`, and the matching child appears where `<Outlet />` is.
- `index: true` is the child for exactly `/`. `books/:id` has a **parameter**: `:id` matches any text, and `useParams()` gives it as a string (`'4'`), which is why the page compares `String(item.id) === id`.
- `path: '*'` matches everything else: the "not found" page.
- `Link` draws an `<a>` that changes the address without asking the server for a new page. A plain `<a href="/about">` would reload everything and lose state. `NavLink` is a `Link` that adds the class `active` to the link that matches the address; `end` on `/` stops it from matching every address.
- The dev server answers any address with `index.html`, so reloading `/books/4` works. A production host must be set up the same way (the capstone shows nginx doing it).
- The effect in `BookPage` has `[id]` as dependency, so when `id` changes it loads again.

**Common misconception:** "each route is a separate HTML file." There is one HTML file; the router swaps components.

## Try it
Starter: `exercise/starter/src/pages/NotFound.tsx` (three TODOs).
1. **Guided.** Show the wrong address on the not-found page. Expected at `/oops`: "Nothing lives at /oops".
2. **Change.** Add a "Go back" button that returns one step in the history.
3. **Stretch (optional).** Add a new page `/contact` with its own file, route and nav link. Decide where the link goes.

<details><summary>Solution</summary>

**File: `exercise/solution/src/pages/NotFound.tsx`**
```tsx
import { Link, useLocation, useNavigate } from 'react-router';

export default function NotFound() {
  const location = useLocation();
  const navigate = useNavigate();
  return (
    <section>
      <h2>Page not found</h2>
      <p>Nothing lives at {location.pathname}</p>
      <button type="button" onClick={() => navigate(-1)}>
        Go back
      </button>
      <Link to="/">Back to the list</Link>
    </section>
  );
}
```
`useLocation` gives the current address; `useNavigate` gives a function: `navigate(-1)` is the browser's Back.

</details>

## Check yourself
1. What does `<Outlet />` draw? <details><summary>Answer</summary>The child route that matches the current address.</details>
2. What is the type of `id` from `useParams()`? <details><summary>Answer</summary>A string (or <code>undefined</code>).</details>
3. Predict: what does `/books/abc` show? <details><summary>Answer</summary>The route matches, no book has id "abc", so "Book not found".</details>
4. Why `Link` and not `<a href>`? <details><summary>Answer</summary><code>Link</code> changes the address without a page load, so state is kept.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Cannot find module 'react-router'` (typical message) | Package not installed | Edit `package.json`, run `npm install`, restart `npm run dev` |
| Page is blank, console says a hook may only be used inside a router (typical message) | `Link` used outside `RouterProvider` | Keep every component under the router in `main.tsx` |
| Whole page reloads on every click | `<a href>` used | Use `Link` or `NavLink` |
| Child page never appears | `<Outlet />` missing in the layout | Add it in `App.tsx` |
| "Books" is always highlighted | `end` missing on the `/` link | Add `end` |
| Reloading `/books/4` shows "Cannot GET" in production (not in dev) | The host does not send `index.html` for unknown paths | Configure the host fallback (capstone chapter 5) |

## Best practice
Keep the list of routes in one place, put shared parts in a layout route, and always provide a catch-all route. Source: React Router, Data mode installation https://reactrouter.com/start/data/installation

## Going further
React Router, Data mode installation: https://reactrouter.com/start/data/installation

## Summary
- You defined routes, a layout with `Outlet` and a not-found route.
- You linked pages with `Link` and `NavLink`.
- You read `:id` with `useParams` and loaded a page's data from it.

## Next lesson
08. Sharing state: lifting state up and context, to stop loading the same list twice.
