---
track: react
level: 201
phase: 1
phase_name: hooks-and-state
lesson: 03
title: "State management options: context versus Zustand"
time: 70 min
prerequisites: [react.201.1.02]
versions: { node: "26.13.1", npm: "11.20.0", react: "19.3.1", vite: "8.3.8", typescript: "5.9.3", tanstack-query: "5.108.3", zustand: "5.1.0" }
verified: not yet run
source: source/react/201-hero-to-super-hero/phase-1-hooks-and-state/03-state-management-options/
assets: []
---

# 03. State management options: context versus Zustand

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- sort state into **server**, **URL**, **local** and **shared UI** state and say where each belongs;
- build a context provider with a stable value and a Zustand store with selectors;
- explain with console output why a context value change redraws every consumer while a selector redraws only its reader;
- justify the capstone's choice **not** to use a global store.

## Recap
1. Who owns server data in this track? <details><summary>Answer</summary>TanStack Query's cache.</details>
2. What did `useMemo` give the `Summary` component in lesson 01? <details><summary>Answer</summary>A stable object reference so <code>memo</code> could skip drawing.</details>

## Why it matters
Most "state management" arguments mix up different kinds of state. If server data lives in Query, the address in the URL, drafts in components, then only a small amount of true **shared UI state** remains (a toast, a theme, a sidebar). That amount is small enough that context or a tiny store both work; knowing the difference tells you which to pick, and when to pick none.

## What you will build
Project `state-lab`: the board from lesson 02 plus a toolbar (view switch and search) and a toast. The view switch uses **context**; the search text and the toast use a **Zustand** store. Console lines show who redraws.

## Before you start
- Time: 70 minutes. New folder `code101/state-lab`.
- Unchanged from lessons 01 and 02: `vite.config.ts`, `tsconfig.json`, `tsconfig.app.json`, `tsconfig.node.json`, `.gitignore`, `src/main.tsx`, `src/tasks.ts`, `src/fake-api.ts` and `src/hooks/tasks.ts` (take them from lesson 02's `query-lab`; their text is in [lesson 02](02-tanstack-query.md)).
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/react/201-hero-to-super-hero/phase-1-hooks-and-state/03-state-management-options/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).

## Steps

### Step 1. Decide before you code
| Kind of state | Example in the capstone | Where it lives |
|---|---|---|
| Server state | tasks, teams, `getMe` | TanStack Query cache |
| URL state | filters, sort, board or list view (`?view=board`) | the address, read with `useSearchParams` |
| Local state | a form draft, an open dialog | `useState` in the component |
| Shared UI state | a toast message, the offline flag | context, or `useSyncExternalStore`, or a store |
| Auth state | the signed-in user | `react-oidc-context` provider |

The capstone puts *view* and *filters* in the URL so they can be shared and survive reload. In this lab the view switch is plain context instead, to show how context works; it is the better teaching shape, not necessarily the better product choice.

### Step 2. package.json and index.html
**File: `package.json`**
```json
{
  "name": "state-lab",
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
    "zustand": "5.1.0"
  },
  "devDependencies": {
    "@types/node": "26.6.6",
    "@types/react": "19.3.0",
    "@types/react-dom": "19.3.0",
    "@vitejs/plugin-react": "6.3.0",
    "typescript": "5.9.3",
    "vite": "8.3.8"
  }
}
```

**File: `index.html`**
```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>State lab</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```
Run `npm install` in the project folder. Expected result: a summary line; `node_modules` and `package-lock.json` appear.

### Step 3. Option A: a context provider
Make the folder `src/ui`.

**File: `src/ui/view-context.tsx`**
```tsx
import { createContext, useContext, useMemo, useState, type ReactNode } from 'react';

export type View = 'board' | 'list';

type ViewValue = {
  view: View;
  setView: (view: View) => void;
};

const ViewContext = createContext<ViewValue | null>(null);

export function ViewProvider({ children }: { children: ReactNode }) {
  const [view, setView] = useState<View>('board');
  const value = useMemo(() => ({ view, setView }), [view]);
  return <ViewContext value={value}>{children}</ViewContext>;
}

export function useView(): ViewValue {
  const value = useContext(ViewContext);
  if (!value) {
    throw new Error('useView must be used inside ViewProvider');
  }
  return value;
}
```
`useMemo` keeps the `value` object identical until `view` changes. Without it, every redraw of `ViewProvider` would create a new object and redraw **every** consumer, even when `view` did not change.

### Step 4. Option B: a Zustand store
**Zustand** is a small library (about 1 kB) for a store that lives outside React. You create it once with `create`, and components read it with a **selector**: `useUiStore(state => state.query)`. A component redraws only when *its selected value* changes.

**File: `src/ui/ui-store.ts`**
```typescript
import { create } from 'zustand';

type UiState = {
  query: string;
  toast: string | null;
  setQuery: (query: string) => void;
  showToast: (message: string) => void;
  clearToast: () => void;
};

export const useUiStore = create<UiState>()((set) => ({
  query: '',
  toast: null,
  setQuery: (query) => set({ query }),
  showToast: (message) => set({ toast: message }),
  clearToast: () => set({ toast: null }),
}));
```
`create<UiState>()(...)` (with the extra `()`) is the form Zustand documents for TypeScript. `set` merges the object you give it into the state, so you only list what changes.

### Step 5. The toolbar and the toast
**File: `src/components/Toolbar.tsx`**
```tsx
import { useUiStore } from '../ui/ui-store';
import { useView } from '../ui/view-context';

function ViewToggle() {
  const { view, setView } = useView();
  console.log('render ViewToggle');
  return (
    <button type="button" onClick={() => setView(view === 'board' ? 'list' : 'board')}>
      Show {view === 'board' ? 'list' : 'board'}
    </button>
  );
}

function SearchBox() {
  const query = useUiStore((state) => state.query);
  const setQuery = useUiStore((state) => state.setQuery);
  console.log('render SearchBox');
  return (
    <label>
      Search <input value={query} onChange={(event) => setQuery(event.target.value)} />
    </label>
  );
}

export default function Toolbar() {
  return (
    <div className="toolbar">
      <ViewToggle />
      <SearchBox />
    </div>
  );
}
```

**File: `src/components/Toast.tsx`**
```tsx
import { useEffect } from 'react';
import { useUiStore } from '../ui/ui-store';

export default function Toast() {
  const toast = useUiStore((state) => state.toast);
  const clearToast = useUiStore((state) => state.clearToast);

  useEffect(() => {
    if (toast === null) {
      return;
    }
    const timer = setTimeout(clearToast, 3000);
    return () => clearTimeout(timer);
  }, [toast, clearToast]);

  console.log('render Toast');
  return (
    <p role="status" className="toast">
      {toast ?? ''}
    </p>
  );
}
```
The `<p role="status">` is always in the page and only its text changes: screen readers announce changes inside an existing live region more reliably than a region that appears together with its text.

### Step 6. Use both in the board
**File: `src/components/Board.tsx`**
```tsx
import { useState, type FormEvent } from 'react';
import { useCreateTask, useMoveTask, useRemoveTask, useTasks } from '../hooks/tasks';
import { isStatus, statuses, type Task } from '../tasks';
import { useUiStore } from '../ui/ui-store';
import { useView } from '../ui/view-context';

type TaskItemProps = {
  task: Task;
  onMove: (task: Task, next: string) => void;
  onRemove: (task: Task) => void;
};

function TaskItem({ task, onMove, onRemove }: TaskItemProps) {
  return (
    <li>
      {task.title} <small>({task.status})</small>
      <br />
      <select aria-label={`Move ${task.title}`} value={task.status} onChange={(event) => onMove(task, event.target.value)}>
        {statuses.map((value) => (
          <option key={value} value={value}>
            {value}
          </option>
        ))}
      </select>{' '}
      <button type="button" onClick={() => onRemove(task)}>
        Remove
      </button>
    </li>
  );
}

export default function Board() {
  const tasks = useTasks();
  const create = useCreateTask();
  const move = useMoveTask();
  const remove = useRemoveTask();
  const { view } = useView();
  const query = useUiStore((state) => state.query);
  const showToast = useUiStore((state) => state.showToast);
  const [title, setTitle] = useState('');

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const trimmed = title.trim();
    if (trimmed === '') {
      return;
    }
    create.mutate(trimmed, {
      onSuccess: () => {
        setTitle('');
        showToast('Task added');
      },
    });
  }

  function handleMove(task: Task, next: string) {
    if (isStatus(next)) {
      move.mutate({ id: task.id, status: next }, { onSuccess: () => showToast('Task moved') });
    }
  }

  function handleRemove(task: Task) {
    remove.mutate(task.id, { onSuccess: () => showToast('Task removed') });
  }

  if (tasks.isPending) {
    return <p role="status">Loading tasks...</p>;
  }
  if (tasks.isError) {
    return (
      <div role="alert">
        <p>{tasks.error.message}</p>
        <button type="button" onClick={() => void tasks.refetch()}>
          Try again
        </button>
      </div>
    );
  }

  const needle = query.trim().toLowerCase();
  const visible = tasks.data.filter((task) => task.title.toLowerCase().includes(needle));

  return (
    <>
      <form onSubmit={handleSubmit}>
        <label>
          New task <input value={title} onChange={(event) => setTitle(event.target.value)} />
        </label>{' '}
        <button type="submit" disabled={create.isPending}>
          Add
        </button>
      </form>
      {visible.length === 0 && <p>No tasks match.</p>}
      {view === 'board' ? (
        <div className="board">
          {statuses.map((status) => (
            <section key={status}>
              <h2>{status}</h2>
              <ul>
                {visible
                  .filter((task) => task.status === status)
                  .map((task) => (
                    <TaskItem key={task.id} task={task} onMove={handleMove} onRemove={handleRemove} />
                  ))}
              </ul>
            </section>
          ))}
        </div>
      ) : (
        <ul>
          {visible.map((task) => (
            <TaskItem key={task.id} task={task} onMove={handleMove} onRemove={handleRemove} />
          ))}
        </ul>
      )}
    </>
  );
}
```

**File: `src/App.tsx`**
```tsx
import Board from './components/Board';
import Toast from './components/Toast';
import Toolbar from './components/Toolbar';
import { ViewProvider } from './ui/view-context';

export default function App() {
  return (
    <ViewProvider>
      <main>
        <h1>State lab</h1>
        <Toolbar />
        <Toast />
        <Board />
      </main>
    </ViewProvider>
  );
}
```

**File: `src/styles.css`**
```css
:root {
  color-scheme: light dark;
  font-family: system-ui, sans-serif;
}

main {
  max-width: 56rem;
  margin: 0 auto;
  padding: 1rem;
}

.toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
  align-items: center;
  margin-bottom: 0.5rem;
}

.toast {
  min-height: 1.5rem;
  font-weight: bold;
}

.board {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(14rem, 1fr));
  gap: 1rem;
}

.board section {
  border: 1px solid #66788a;
  border-radius: 0.5rem;
  padding: 0.5rem 1rem;
}

.board ul {
  list-style: none;
  padding: 0;
}

li {
  margin: 0.75rem 0;
}

input,
select,
button {
  font: inherit;
  padding: 0.3rem 0.5rem;
}

:focus-visible {
  outline: 3px solid #0759aa;
  outline-offset: 2px;
}
```

## Run it
**Folder: `state-lab`**
```powershell
npm run dev
```
Open `http://localhost:5173/` with the console open. (In development `StrictMode` may double lines.) Expected:
1. Load. Console: `render ViewToggle`, `render SearchBox`, `render Toast`.
2. Type `rev` in Search. Expected console: only `render SearchBox` per keystroke. The `Board` redraws too (it reads `query` to filter) but it prints nothing. `ViewToggle` and `Toast` stay silent: they do not select `query`. The board now shows only "Review the code".
3. Click "Show list". Expected console: `render ViewToggle` only. The board becomes one list.
4. Add a task. Expected: the toast text "Task added" for about three seconds; console shows `render Toast` when it appears and when it clears.

## How it works
- **Context** has no selectors. `useContext(ViewContext)` re-draws the consumer whenever the provider's `value` is a *different object*. That is fine for a value that changes rarely (a view mode, a theme, the signed-in user). It is a poor fit for something that changes on every keystroke, because every consumer redraws, even those that need only part of the value.
- **Zustand's selector** (`state => state.query`) tells the library what a component needs; it compares the selected value with `Object.is` and redraws only on a change. Selecting a **new object** each time (`state => ({ a: state.a })`) would redraw every time (and in Zustand 5 can even loop); select single values, or use `useShallow` from `zustand/react/shallow` when you need several.
- The store lives **outside** React, so you can call `useUiStore.getState().showToast('...')` from non-component code such as an API error handler. Context cannot do that.
- **Costs:** Zustand is one more dependency and one more pattern. Context is built in. Neither is a place for server data: a copy of server data in a store drifts from the server and loses Query's refetching.

### Why this, not that
| Need | Choose |
|---|---|
| A value that rarely changes and many components read (theme, user) | Context (with a memoised value) |
| A value that changes often and few components read it | A store with selectors (Zustand), or keep it local and lift only as far as needed |
| Anything from a server | TanStack Query |
| Anything the user may want to share or bookmark | The URL |
| Redux Toolkit | Large teams that want strict conventions, middleware and dev tools; heavier than this app needs |
| **Nothing** | Most of the capstone: it uses Query, the URL, local state and a few small contexts, with no global store |

**Common misconception:** "context is slow." Context is not slow; unneeded redraws are. A context with a stable value and rare changes costs nothing noticeable.

## Try it
Starter: `exercise/starter/src/ui/ui-store.ts` and `exercise/starter/src/components/Toolbar.tsx` (four TODOs).
1. **Guided.** Add `compact` and `toggleCompact` to the store and a `CompactToggle` checkbox in the toolbar. Expected: ticking it prints `render CompactToggle` only; typing in Search does not.
2. **Change.** Experiment: move `query` and `setQuery` into `ViewContext` (put them in the provider's state and value) and read them with `useView` in `SearchBox` and `Board`. Type in Search and watch the console. Expected: `render ViewToggle` now appears on every keystroke. Undo the experiment afterwards.
3. **Stretch (optional).** Decide which of the toolbar's state belongs in the URL (`?q=` and `?view=`) and write down the trade-off (shareable and back button friendly, but each keystroke adds a history entry unless you use `replace`).

<details><summary>Solution</summary>

**File: `exercise/solution/src/ui/ui-store.ts`**
```typescript
import { create } from 'zustand';

type UiState = {
  query: string;
  toast: string | null;
  compact: boolean;
  setQuery: (query: string) => void;
  showToast: (message: string) => void;
  clearToast: () => void;
  toggleCompact: () => void;
};

export const useUiStore = create<UiState>()((set) => ({
  query: '',
  toast: null,
  compact: false,
  setQuery: (query) => set({ query }),
  showToast: (message) => set({ toast: message }),
  clearToast: () => set({ toast: null }),
  toggleCompact: () => set((state) => ({ compact: !state.compact })),
}));
```

**File: `exercise/solution/src/components/Toolbar.tsx`**
```tsx
import { useUiStore } from '../ui/ui-store';
import { useView } from '../ui/view-context';

function ViewToggle() {
  const { view, setView } = useView();
  console.log('render ViewToggle');
  return (
    <button type="button" onClick={() => setView(view === 'board' ? 'list' : 'board')}>
      Show {view === 'board' ? 'list' : 'board'}
    </button>
  );
}

function SearchBox() {
  const query = useUiStore((state) => state.query);
  const setQuery = useUiStore((state) => state.setQuery);
  console.log('render SearchBox');
  return (
    <label>
      Search <input value={query} onChange={(event) => setQuery(event.target.value)} />
    </label>
  );
}

function CompactToggle() {
  const compact = useUiStore((state) => state.compact);
  const toggleCompact = useUiStore((state) => state.toggleCompact);
  console.log('render CompactToggle');
  return (
    <label>
      <input type="checkbox" checked={compact} onChange={toggleCompact} /> Compact
      <span> (Compact mode is {compact ? 'on' : 'off'})</span>
    </label>
  );
}

export default function Toolbar() {
  return (
    <div className="toolbar">
      <ViewToggle />
      <SearchBox />
      <CompactToggle />
    </div>
  );
}
```

</details>

## Check yourself
1. Why wrap the context `value` in `useMemo`? <details><summary>Answer</summary>A new object each draw would redraw every consumer; the memo keeps the same object until <code>view</code> changes.</details>
2. Which console line appears when you type in Search? <details><summary>Answer</summary>Only <code>render SearchBox</code>.</details>
3. Where would you keep a list of teams loaded from the API? <details><summary>Answer</summary>In the TanStack Query cache, not in a store or context.</details>
4. Find the bug: `const { query, toast } = useUiStore((state) => ({ query: state.query, toast: state.toast }));` <details><summary>Answer</summary>The selector returns a new object each time, so the component redraws on every store change; select one value per call or use <code>useShallow</code>.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Cannot find module 'zustand'` (typical message) | Not installed | Check `package.json`, run `npm install` |
| `useView must be used inside ViewProvider` | A consumer outside the provider | Wrap in `App.tsx` |
| Every component redraws on a store change | `useUiStore()` called without a selector | Always pass a selector |
| Toast never disappears | Effect cleanup missing, or `clearToast` not used | Keep the timer effect |
| TypeScript error on `create<UiState>((set) => ...)` (typical message) | Missing the extra `()` for TypeScript | Write `create<UiState>()((set) => ...)` |

## Best practice
Sort state into server, URL, local and shared UI before choosing a tool; use the smallest tool that fits each kind. Source: React, Choosing the State Structure https://react.dev/learn/choosing-the-state-structure and Zustand docs https://zustand.docs.pmnd.rs/

## Going further
- You Might Not Need an Effect: https://react.dev/learn/you-might-not-need-an-effect
- Where the capstone keeps its state: [web-react TDD, section 4.1](../../../../capstones/web-react/TDD.md#41-client-state-model).

## Summary
- You classified state into server, URL, local and shared UI.
- You built a memoised context and a Zustand store with selectors and compared their redraws in the console.
- You explained why the capstone has no global store.

## Next lesson
04. A typed API client: generate TypeScript types from the platform's OpenAPI contract and call the API safely.
