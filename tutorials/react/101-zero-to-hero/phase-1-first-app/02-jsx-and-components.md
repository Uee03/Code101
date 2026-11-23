---
track: react
level: 101
phase: 1
phase_name: first-app
lesson: 02
title: "JSX and components"
time: 60 min
prerequisites: [react.101.1.01]
versions: { node: "26.13.1", npm: "11.20.0", react: "19.3.1", vite: "8.3.8", typescript: "5.9.3" }
verified: not yet run
source: source/react/101-zero-to-hero/phase-1-first-app/02-jsx-and-components/
assets: []
---

# 02. JSX and components

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- write JSX with the five rules that trip up beginners;
- split a page into small components, each in its own file;
- put a value or a small calculation into JSX with curly braces;
- explain why a component name starts with a capital letter.

## Recap
1. Which file loads your code in the browser, and which command starts the server? <details><summary>Answer</summary><code>index.html</code> loads <code>src/main.tsx</code>; <code>npm run dev</code> starts Vite.</details>
2. What does `export default function App()` give to `main.tsx`? <details><summary>Answer</summary>The component that <code>main.tsx</code> imports as <code>App</code> and asks React to draw.</details>

## Why it matters
Think of LEGO. A big model is built from small standard bricks that you can reuse. A component is a brick: a header, a footer, a book card. When you can name the bricks of a page, the page becomes easy to change.

## What you will build
The same `react-app` project, now a page made of three bricks: `Header`, a welcome area inside `App`, and `Footer`.

## Before you start
- Time: 60 minutes. The project `react-app` from lesson 01 with `npm install` already done.
- Open `react-app` in VS Code, open a terminal whose prompt ends in `react-app` and run `npm run dev` (leave it running; open `http://localhost:5173/`).
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/react/101-zero-to-hero/phase-1-first-app/02-jsx-and-components/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Unchanged from lesson 01: `package.json`, `vite.config.ts`, the three `tsconfig` files, `index.html`, `.gitignore` and `src/main.tsx`. Do not touch them.

## Steps

### Step 1. Make the folder for components
In the Explorer hover over `src`, click **New Folder** and name it `components`. Components are normal TypeScript functions; a folder only keeps them tidy.

### Step 2. Write the Header component
Create `src/components/Header.tsx` and save it.

**File: `src/components/Header.tsx`**
```tsx
export default function Header() {
  return (
    <header>
      <h1>Reading list</h1>
    </header>
  );
}
```
Expected result: the file exists. The page does not change yet, because nothing uses `Header`.

### Step 3. Write the Footer component
**File: `src/components/Footer.tsx`**
```tsx
export default function Footer() {
  return (
    <footer>
      <p>Made with React</p>
    </footer>
  );
}
```

### Step 4. Use the components in App
Replace the whole content of `src/App.tsx`.

**File: `src/App.tsx`**
```tsx
import Header from './components/Header';
import Footer from './components/Footer';

export default function App() {
  const owner = 'Ada';
  const goal = 12;
  return (
    <>
      <Header />
      <main>
        <h2>Welcome, {owner}</h2>
        <p>
          Your goal is {goal} books this year. That is {goal / 12} a month.
        </p>
        <p className="note">Everything on this page is drawn by components.</p>
        {/* This comment is not shown on the page. */}
      </main>
      <Footer />
    </>
  );
}
```
Expected result: the page shows "Reading list" as a heading, "Welcome, Ada", the goal sentence, the note and "Made with React", still without colours (the styles come next).

### Step 5. Replace the stylesheet
Replace the whole content of `src/styles.css`.

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

.note {
  color: #3b4a5a;
  font-style: italic;
}
```
Expected result (browser, saved files):
```text
[light blue bar]  Reading list
Welcome, Ada
Your goal is 12 books this year. That is 1 a month.
Everything on this page is drawn by components.   (shown in italics)
[light blue bar]  Made with React
```

## Run it
**Folder: `react-app`**
```powershell
npm run dev
```
Open `http://localhost:5173/`. Expected: the page above. If the server still runs from lesson 01 you only need to save the files and look at the browser.

## How it works
- **Component:** a function whose name starts with a capital letter and that returns JSX. `Header()` is called by React when it meets `<Header />`.
- **JSX** looks like HTML but is TypeScript syntax. Vite turns `<h1>Reading list</h1>` into plain function calls before the browser sees it.
- **The five rules:**
  1. A component returns **one parent**. When you need siblings and no extra element, wrap them in an empty tag `<>...</>` called a **fragment** (`App` does this).
  2. Every tag must be **closed**: `<Header />`, `<br />`, `<img ... />`.
  3. Attributes are **camelCase** and a few differ from HTML: `class` is `className` (because `class` is a JavaScript word).
  4. **Curly braces** open a window back into TypeScript: `{owner}` shows a value, `{goal / 12}` shows a result. Only expressions fit inside, not `if` statements.
  5. A comment inside JSX is `{/* ... */}`.
- **Capital letter rule:** `<header>` (lower case) is a normal HTML element; `<Header />` (capital) is your component. That is how React tells them apart.
- `import Header from './components/Header'` matches `export default` in the other file: one default export per file, you choose the import name.

**Common misconception:** "JSX is HTML in a file." It looks like it, but `class` and `for` become `className` and `htmlFor`, and braces run TypeScript.

## Try it
Starter: `exercise/starter/src/components/Tip.tsx` and `exercise/starter/src/App.tsx` (copy both over your files; they contain TODO comments).
1. **Guided.** Make `Tip` return a paragraph with class `tip` that says `Tip: read a little every day.` Import it in `App.tsx` and show it once. Expected: the sentence appears below the goal.
2. **Change.** Show `Tip` twice. Expected: the sentence appears twice, because one component can be used many times.
3. **Stretch (optional).** Decide whether `Tip` should live in its own file or inside `App.tsx`. Write one sentence why. There is no single answer.

<details><summary>Solution</summary>

**File: `exercise/solution/src/components/Tip.tsx`**
```tsx
export default function Tip() {
  return <p className="tip">Tip: read a little every day.</p>;
}
```

**File: `exercise/solution/src/App.tsx`**
```tsx
import Header from './components/Header';
import Footer from './components/Footer';
import Tip from './components/Tip';

export default function App() {
  const owner = 'Ada';
  const goal = 12;
  return (
    <>
      <Header />
      <main>
        <h2>Welcome, {owner}</h2>
        <p>
          Your goal is {goal} books this year. That is {goal / 12} a month.
        </p>
        <Tip />
        <Tip />
      </main>
      <Footer />
    </>
  );
}
```
The single-line `return <p ...>...</p>;` needs no parentheses; parentheses are only needed to spread JSX over several lines.

</details>

## Check yourself
1. Why must a component name start with a capital letter? <details><summary>Answer</summary>React treats lower-case tags as HTML elements and capitalised ones as your components.</details>
2. What does `{goal / 12}` show when `goal` is `24`? <details><summary>Answer</summary><code>2</code>: the braces run the calculation.</details>
3. Find the bug: `return (<h1>One</h1><p>Two</p>);` <details><summary>Answer</summary>Two sibling elements need one parent; wrap them in a fragment <code>&lt;&gt;...&lt;/&gt;</code>.</details>
4. Which attribute sets a CSS class in JSX? <details><summary>Answer</summary><code>className</code>.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `JSX expressions must have one parent element.` (TypeScript 2657) | Two sibling elements returned without a parent | Wrap them in `<>...</>` or one element |
| `Property 'class' does not exist on type ...` (typical message; suggests `className`) | HTML habit | Write `className` |
| `Property 'tip' does not exist on type 'JSX.IntrinsicElements'` (typical message) | Component name starts with a lower-case letter | Capitalise: `Tip`, in the file and in the import |
| Browser overlay with `Unterminated JSX contents` (typical message) | A tag is not closed | Close every tag; `<Header />` needs `/` |
| `Cannot find module './components/Header'` (typical message) | Wrong file name, folder or capital letters | Match the path exactly, including capital H |
| Page does not change | File not saved, or dev server stopped | Save (no dot on the tab); run `npm run dev` |

## Best practice
Keep each component small and named after what it shows; when a file passes about 100 lines or you give a part of it a name in your head, split it. Source: Thinking in React https://react.dev/learn/thinking-in-react

## Going further
Writing Markup with JSX: https://react.dev/learn/writing-markup-with-jsx and Your First Component: https://react.dev/learn/your-first-component

## Summary
- You wrote JSX and used the five rules.
- You split a page into `Header`, `Footer` and `App`, each as a function.
- You showed values with `{ }` and explained the capital-letter rule.

## Next lesson
03. Props and rendering lists: send data into a component and draw one card per book.
