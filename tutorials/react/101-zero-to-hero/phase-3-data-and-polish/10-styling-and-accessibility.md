---
track: react
level: 101
phase: 3
phase_name: data-and-polish
lesson: 10
title: "Styling and accessibility"
time: 80 min
prerequisites: [react.101.3.09]
versions: { node: "26.13.1", npm: "11.20.0", react: "19.3.1", vite: "8.3.8", typescript: "5.9.3" }
verified: not yet run
source: source/react/101-zero-to-hero/phase-3-data-and-polish/10-styling-and-accessibility/
assets: [ui/plus, ui/x, ui/check-circle]
---

# 10. Styling and accessibility

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- style React components with one CSS file, custom properties and a dark scheme;
- show an icon that follows the text colour and is hidden from screen readers when it only decorates;
- add a skip link, a visible keyboard focus and `aria-describedby` for form errors;
- use the keyboard alone to test a page.

## Recap
1. What does `useBooks()` return? <details><summary>Answer</summary>The shared books, the loading status and the actions from <code>BooksContext</code>.</details>
2. Which HTML element did you tie to an input with `htmlFor`? <details><summary>Answer</summary>The <code>label</code>.</details>

## Why it matters
A building needs a ramp next to the stairs. Many people rely on a keyboard, a screen reader, a high-contrast setting or a small phone. If you add accessibility at the end it is expensive; if you write it with the first component it is nearly free. This lesson also makes the app look finished.

## What you will build
The same app with a cleaner look, automatic dark mode, a "Skip to the content" link, a thick focus outline, three icons (a plus on the add button, a check on the "Read" label) and form fields that point to their error message.

## Before you start
- Time: 80 minutes. Project `react-app` after lesson 09, dev server running.
- Icons: this course uses only the course's own CC0 icons from `assets/art`. You need three: `plus`, `x` and `check-circle`. Their full text is below; you create them yourself.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/react/101-zero-to-hero/phase-3-data-and-polish/10-styling-and-accessibility/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Unchanged: `package.json`, config files, `index.html`, `.gitignore`, `public/api/books.json`, `main.tsx`, `books.ts`, `api.ts`, `BooksContext.tsx`, `BookList.tsx`, `FilterBar.tsx`, `Header.tsx`, `Footer.tsx`, `Panel.tsx`, `Counter.tsx` and the four pages.

## Steps

### Step 1. Create the icon files
Make the folders `public/icons/ui` (inside `public`). An **SVG** is a picture written as text. Create three files with these exact contents. They are CC0 (public domain) icons; the licence text is in the next paragraph.

**File: `public/icons/ui/plus.svg`**
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" role="img" aria-label="Plus">
  <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
</svg>
```

**File: `public/icons/ui/x.svg`**
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" role="img" aria-label="X">
  <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
</svg>
```

**File: `public/icons/ui/check-circle.svg`**
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" role="img" aria-label="Check Circle">
  <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/>
</svg>
```
Also create `public/icons/LICENSE-ICONS-CC0.txt` and keep it next to them (the licence is "CC0 1.0 Universal": the authors gave the icons to the public domain; the full legal text is at https://creativecommons.org/publicdomain/zero/1.0/legalcode). Expected result: opening `http://localhost:5173/icons/ui/plus.svg` shows a black plus.

### Step 2. Write the Icon component
The SVG files are used as a **mask**: CSS fills the icon's shape with the text colour. So the icon turns white in dark mode, grey on a disabled button, and so on.

**File: `src/components/Icon.tsx`**
```tsx
export type IconName = 'plus' | 'x' | 'check-circle';

type IconProps = {
  name: IconName;
};

export default function Icon({ name }: IconProps) {
  return <span className={`icon icon-${name}`} aria-hidden="true" />;
}
```
`aria-hidden="true"` tells screen readers to skip it: the words beside the icon already say what it means. If an icon ever stands alone on a button, give the button an `aria-label` instead.

### Step 3. Use the icons and the error link
**File: `src/components/BookCard.tsx`**
```tsx
import { Link } from 'react-router';
import Icon from './Icon';

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
      {read ? (
        <p className="badge">
          <Icon name="check-circle" />
          Read
        </p>
      ) : (
        <p>Not read yet</p>
      )}
      <button type="button" onClick={() => onToggle(id)}>
        {read ? 'Mark as unread' : 'Mark as read'}
      </button>
    </li>
  );
}
```

**File: `src/components/AddBookForm.tsx`**
```tsx
import { useId, useState, type FormEvent } from 'react';
import type { Book } from '../books';
import Icon from './Icon';

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
  const errorId = `${id}-error`;
  const describedBy = error ? errorId : undefined;

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
        <input
          id={`${id}-title`}
          value={title}
          aria-describedby={describedBy}
          onChange={(event) => setTitle(event.target.value)}
        />
      </div>
      <div className="field">
        <label htmlFor={`${id}-author`}>Author</label>
        <input
          id={`${id}-author`}
          value={author}
          aria-describedby={describedBy}
          onChange={(event) => setAuthor(event.target.value)}
        />
      </div>
      <div className="field">
        <label htmlFor={`${id}-pages`}>Pages</label>
        <input
          id={`${id}-pages`}
          type="number"
          min="1"
          value={pages}
          aria-describedby={describedBy}
          onChange={(event) => setPages(event.target.value)}
        />
      </div>
      <div className="field">
        <label>
          <input type="checkbox" checked={read} onChange={(event) => setRead(event.target.checked)} /> Already read
        </label>
      </div>
      {error && (
        <p id={errorId} role="alert" className="error">
          {error}
        </p>
      )}
      <button type="submit">
        <Icon name="plus" />
        Add book
      </button>
    </form>
  );
}
```

### Step 4. Add the skip link and a focusable main
**File: `src/App.tsx`**
```tsx
import { NavLink, Outlet } from 'react-router';
import { BooksProvider } from './BooksContext';
import Header from './components/Header';
import Footer from './components/Footer';

export default function App() {
  return (
    <BooksProvider>
      <a className="skip" href="#content">
        Skip to the content
      </a>
      <Header />
      <nav className="nav" aria-label="Main">
        <NavLink to="/" end>
          Books
        </NavLink>
        <NavLink to="/about">About</NavLink>
      </nav>
      <main id="content" tabIndex={-1}>
        <Outlet />
      </main>
      <Footer />
    </BooksProvider>
  );
}
```

### Step 5. Replace the stylesheet
**File: `src/styles.css`**
```css
:root {
  color-scheme: light dark;
  --bg: #ffffff;
  --text: #17212b;
  --accent: #0759aa;
  --surface: #e7f0fa;
  --border: #66788a;
  --ok: #0b5d1e;
  --danger: #a11a1a;
}

@media (prefers-color-scheme: dark) {
  :root {
    --bg: #11181f;
    --text: #e8eef4;
    --accent: #7db8f5;
    --surface: #1d2b38;
    --border: #8499ad;
    --ok: #7be29a;
    --danger: #ff9b9b;
  }
}

body {
  font-family: system-ui, sans-serif;
  margin: 0;
  background: var(--bg);
  color: var(--text);
}

a {
  color: var(--accent);
}

:focus-visible {
  outline: 3px solid var(--accent);
  outline-offset: 2px;
}

.skip {
  position: absolute;
  left: -10000px;
  top: 0;
}

.skip:focus {
  left: 0;
  z-index: 10;
  padding: 0.5rem 1rem;
  background: var(--bg);
  color: var(--text);
}

header,
footer {
  background: var(--surface);
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

main:focus {
  outline: none;
}

.nav {
  display: flex;
  gap: 1rem;
  padding: 0.5rem 1rem;
  border-bottom: 1px solid var(--border);
}

.nav a {
  padding: 0.25rem 0.5rem;
}

.nav a.active {
  font-weight: bold;
  text-decoration: none;
  border-bottom: 3px solid var(--accent);
}

button {
  font: inherit;
  min-height: 2.5rem;
  padding: 0.4rem 0.9rem;
  border: 1px solid var(--border);
  border-radius: 0.4rem;
  background: var(--surface);
  color: var(--text);
  cursor: pointer;
  transition: background-color 0.15s;
}

button:hover {
  background: var(--border);
}

button:disabled {
  cursor: progress;
  opacity: 0.7;
}

.icon {
  display: inline-block;
  width: 1.1em;
  height: 1.1em;
  margin-right: 0.35em;
  vertical-align: -0.15em;
  background-color: currentColor;
}

.icon-plus {
  mask: url(/icons/ui/plus.svg) center / contain no-repeat;
}

.icon-x {
  mask: url(/icons/ui/x.svg) center / contain no-repeat;
}

.icon-check-circle {
  mask: url(/icons/ui/check-circle.svg) center / contain no-repeat;
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
  border: 1px solid var(--border);
  border-radius: 0.5rem;
  padding: 0.75rem;
}

.card h3,
.card p {
  margin: 0.25rem 0;
}

.badge {
  color: var(--ok);
  font-weight: bold;
}

form {
  margin-top: 1.5rem;
  padding: 0.75rem;
  border: 1px solid var(--border);
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
  background: var(--bg);
  color: var(--text);
  border: 1px solid var(--border);
  border-radius: 0.3rem;
}

.error {
  color: var(--danger);
  font-weight: bold;
}

@media (prefers-reduced-motion: reduce) {
  button {
    transition: none;
  }
}
```

## Run it
**Folder: `react-app`**
```powershell
npm run dev
```
Check, in order:
1. Look at the page. Expected: light page with a light-blue header bar; "Read" cards show a small check mark in front of the word. If your operating system is set to dark mode, the page is dark.
2. **Keyboard test.** Click once on an empty part of the page, then press **Tab** repeatedly. Expected: the first stop is "Skip to the content" (it appears at the top left); then the nav links, the checkbox, buttons and links, each with a thick outline. Press Enter on the skip link: focus jumps to the main area.
3. Click "Add book" with empty boxes. Expected: the red message appears; a screen reader reads it because of `role="alert"`, and each input is linked to it through `aria-describedby`.
4. Zoom the browser to 200 percent (Ctrl and +). Expected: nothing overlaps; text stays readable.

## How it works
- **Custom properties** (`--bg`, `--text`) are named values defined once in `:root` and used with `var(...)`. The dark scheme only redefines them inside `@media (prefers-color-scheme: dark)`, so all components follow. `color-scheme: light dark` also darkens built-in controls.
- **Mask icon:** `mask: url(...)` shows the background colour only where the SVG has ink. `background-color: currentColor` takes the text colour. The icon is a `span` with `aria-hidden` so it adds nothing for screen readers.
- **Focus:** `:focus-visible` styles the outline only when the keyboard (not the mouse) moved the focus. Never remove the outline without a better replacement.
- **Skip link:** the first focusable item lets keyboard users jump past the navigation. `tabIndex={-1}` on `main` lets the link move focus there.
- **`aria-describedby`** links an input to the element with the given id; a screen reader reads the description after the label. It is only set while an error exists.
- **Target size and contrast:** buttons are at least 2.5rem tall, and the text and background pairs were chosen for strong contrast. You should still check your own colours with a contrast checker when you change them.
- **Reduced motion:** users who ask the system for less movement get no transition.
- **Native first:** a real `button`, `a`, `label` and `input` give keyboard and screen reader behaviour for free. A `div` with `onClick` gives none of it.

**Common misconception:** "accessibility means adding ARIA attributes." The first rule of ARIA is to use the right HTML element; add ARIA only where HTML has no equivalent.

## Try it
Starter: `exercise/starter/src/components/AddBookForm.tsx` (two TODOs).
1. **Guided.** Add a "Clear" button with the `x` icon that empties the form. Expected: after typing, clicking Clear empties all boxes and removes any error.
2. **Change.** Make the submit handler reuse your `clear` function instead of repeating the five lines.
3. **Stretch (optional).** Test the page with only the keyboard: can you add a book without a mouse? Write down any step that fails.

<details><summary>Solution</summary>

**File: `exercise/solution/src/components/AddBookForm.tsx`**
```tsx
import { useId, useState, type FormEvent } from 'react';
import type { Book } from '../books';
import Icon from './Icon';

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
  const errorId = `${id}-error`;
  const describedBy = error ? errorId : undefined;

  function clear() {
    setTitle('');
    setAuthor('');
    setPages('');
    setRead(false);
    setError('');
  }

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
    clear();
  }

  return (
    <form onSubmit={handleSubmit} noValidate>
      <h3>Add a book</h3>
      <div className="field">
        <label htmlFor={`${id}-title`}>Title</label>
        <input
          id={`${id}-title`}
          value={title}
          aria-describedby={describedBy}
          onChange={(event) => setTitle(event.target.value)}
        />
      </div>
      <div className="field">
        <label htmlFor={`${id}-author`}>Author</label>
        <input
          id={`${id}-author`}
          value={author}
          aria-describedby={describedBy}
          onChange={(event) => setAuthor(event.target.value)}
        />
      </div>
      <div className="field">
        <label htmlFor={`${id}-pages`}>Pages</label>
        <input
          id={`${id}-pages`}
          type="number"
          min="1"
          value={pages}
          aria-describedby={describedBy}
          onChange={(event) => setPages(event.target.value)}
        />
      </div>
      <div className="field">
        <label>
          <input type="checkbox" checked={read} onChange={(event) => setRead(event.target.checked)} /> Already read
        </label>
      </div>
      {error && (
        <p id={errorId} role="alert" className="error">
          {error}
        </p>
      )}
      <button type="submit">
        <Icon name="plus" />
        Add book
      </button>{' '}
      <button type="button" onClick={clear}>
        <Icon name="x" />
        Clear
      </button>
    </form>
  );
}
```
`{' '}` puts a real space between the two buttons. The Clear button has `type="button"` so it never submits the form.

</details>

## Check yourself
1. Why is the icon `aria-hidden`? <details><summary>Answer</summary>It only decorates; the visible words carry the meaning, so a screen reader should not announce it.</details>
2. What does `:focus-visible` do? <details><summary>Answer</summary>It styles the focus outline when the keyboard moved the focus.</details>
3. Predict: what is the first stop when you press Tab on a fresh page load? <details><summary>Answer</summary>The "Skip to the content" link.</details>
4. Find the bug: `<div onClick={save}>Save</div>` as a button. <details><summary>Answer</summary>A <code>div</code> is not focusable and has no button role; use <code>&lt;button type="button"&gt;</code>.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| Icons do not appear | SVG files missing in `public/icons/ui` or wrong names | Create the three files with the exact names |
| Icon shows as a solid square | `mask` not applied (typo in the class or path) | Check `.icon-plus` and the `url(/icons/ui/plus.svg)` path |
| Focus outline missing | A global `outline: none` rule | Remove it; keep `:focus-visible` |
| Skip link always visible | `.skip` rule not saved | Check the `left: -10000px` rule |
| Dark mode does not change | OS is in light mode | Switch your system theme, or use the browser DevTools rendering panel |
| `Type '"star"' is not assignable to type 'IconName'` (typical message) | Icon name not in the union | Add the file and the name to `IconName` |

## Best practice
Use native HTML elements, keep a visible focus outline, and never rely on colour alone to show a state. Source: WAI-ARIA Authoring Practices, No ARIA is better than bad ARIA https://www.w3.org/WAI/ARIA/apg/practices/read-me-first/

## Going further
WCAG 2.2 overview: https://www.w3.org/TR/WCAG22/ and MDN, CSS custom properties: https://developer.mozilla.org/en-US/docs/Web/CSS/--*

## Summary
- You styled the app with custom properties and a dark scheme.
- You drew icons from SVG files with a mask and hid them from assistive tools.
- You added a skip link, a visible focus and an error linked to its fields.

## Next lesson
11. Custom hooks: pull repeated logic out of components and save the books in the browser.
