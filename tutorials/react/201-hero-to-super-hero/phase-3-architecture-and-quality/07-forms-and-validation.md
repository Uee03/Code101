---
track: react
level: 201
phase: 3
phase_name: architecture-and-quality
lesson: 07
title: "Forms and validation"
time: 75 min
prerequisites: [react.201.2.06]
versions: { node: "26.13.1", npm: "11.20.0", react: "19.3.1", vite: "8.3.8", typescript: "5.9.3" }
verified: not yet run
source: source/react/201-hero-to-super-hero/phase-3-architecture-and-quality/07-forms-and-validation/
assets: []
---

# 07. Forms and validation

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- read a form with `FormData` instead of one state variable per field, and say when that is the right choice;
- validate on the client with a pure function and show an **error summary** plus per-field messages;
- map the server's 422 `errors[].pointer` values to fields;
- send one `Idempotency-Key` per submit attempt and reuse it only when the outcome is uncertain.

## Recap
1. What does `errors[].pointer` contain in a 422 problem? <details><summary>Answer</summary>A JSON Pointer such as <code>/title</code> naming the invalid field of the request body.</details>
2. Which statuses are `retryable` in `describeError`? <details><summary>Answer</summary>429, 5xx and network failures.</details>

## Why it matters
Forms are where users give you information, and where they give up. The three rules that matter: a person must be able to **fix** a mistake without retyping everything (WCAG 3.3.7), must be **told** what is wrong in words and in text, not only colour (3.3.1, 3.3.3), and a double click or a lost answer must not create **two** tasks. The capstone's forms follow all three.

## What you will build
Project `forms-lab`: a "New task" form (title, description, priority, due date) with client validation, an error summary that takes focus, field errors tied with `aria-describedby`, and a fake server that answers 422, 500 and a "lost answer" so you can see each path.

## Before you start
- Time: 75 minutes. New folder `code101/forms-lab`. No backend needed.
- Unchanged: `vite.config.ts`, the three `tsconfig` files, `.gitignore`, `src/main.tsx` (lesson 01); `src/api/problem.ts`, `src/api/describe.ts` and `src/shared/ProblemPanel.tsx` (lesson 05).
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/react/201-hero-to-super-hero/phase-3-architecture-and-quality/07-forms-and-validation/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Tests are not part of this track; the pure functions below are written so a later test would be easy.

## Steps

### Step 1. Decide the approach
| Approach | Good for | Cost |
|---|---|---|
| Controlled inputs (one `useState` per field) | Live feedback while typing, fields that depend on each other | More code, a redraw per keystroke |
| **Uncontrolled inputs read with `FormData` on submit** | Most forms: values are read once | No live preview |
| React Hook Form, Formik, TanStack Form | Large forms, dynamic arrays, schema validation | A new library to learn (valid alternative) |
| Browser validation bubbles only (`required`) | Quick prototypes | Messages you cannot style or word, inconsistent for assistive technology |

The capstone uses the second row: native fields with `name` attributes and the same validation function on the client. `noValidate` on the `<form>` switches off the browser's bubbles so **our** messages show.

### Step 2. package.json and index.html
**File: `package.json`**
```json
{
  "name": "forms-lab",
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
    "react-dom": "19.3.1"
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
    <title>Forms lab</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```
Run `npm install`. Expected result: `node_modules` and `package-lock.json` appear.

### Step 3. Validation as pure functions
These functions have no React in them: they take plain values and return plain errors. The rules mirror the platform's `TaskCreate` schema (title 1 to 200 characters, description up to 10000, priority one of four values, due date `yyyy-MM-dd`). The server stays the authority: it validates again.

**File: `src/forms/validate.ts`**
```typescript
import type { ApiProblem } from '../api/problem';

export type TaskValues = {
  title: string;
  description: string;
  priority: string;
  dueDate: string;
};

export type FieldName = keyof TaskValues;
export type FieldErrors = Partial<Record<FieldName, string>>;

export const priorities = ['low', 'medium', 'high', 'urgent'] as const;

export function readValues(form: HTMLFormElement): TaskValues {
  const data = new FormData(form);
  const text = (name: string) => String(data.get(name) ?? '');
  return {
    title: text('title').trim(),
    description: text('description'),
    priority: text('priority'),
    dueDate: text('dueDate'),
  };
}

export function validate(values: TaskValues): FieldErrors {
  const errors: FieldErrors = {};
  if (values.title === '') {
    errors.title = 'Enter a title.';
  } else if (values.title.length > 200) {
    errors.title = 'Use at most 200 characters.';
  }
  if (values.description.length > 10000) {
    errors.description = 'Use at most 10000 characters.';
  }
  if (!(priorities as readonly string[]).includes(values.priority)) {
    errors.priority = 'Choose a priority.';
  }
  if (values.dueDate !== '' && !/^\d{4}-\d{2}-\d{2}$/.test(values.dueDate)) {
    errors.dueDate = 'Use the format yyyy-mm-dd.';
  }
  return errors;
}

function isFieldName(value: string): value is FieldName {
  return value === 'title' || value === 'description' || value === 'priority' || value === 'dueDate';
}

export function fieldErrorsFromProblem(problem: ApiProblem): FieldErrors {
  const errors: FieldErrors = {};
  for (const item of problem.errors ?? []) {
    const name = item.pointer.replace(/^\//, '');
    if (isFieldName(name)) {
      errors[name] = item.detail;
    }
  }
  return errors;
}
```
`FormData` gives `FormDataEntryValue | null` (a string or a file), so `String(data.get(...) ?? '')` is the safe conversion. `fieldErrorsFromProblem` removes the leading `/` from the pointer (`/title` becomes `title`) and keeps only names this form knows, so an unexpected pointer cannot crash the page.

### Step 4. A fake server with three behaviours
**File: `src/fake-submit.ts`**
```typescript
import { ApiProblem } from './api/problem';
import type { TaskValues } from './forms/validate';

export type CreatedTask = TaskValues & { id: number; replayed: boolean };

const stored = new Map<string, CreatedTask>();
let nextId = 1;

function wait(milliseconds = 300): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

// A stand-in for POST /v1/projects/{projectId}/tasks with an Idempotency-Key header.
export async function submitTask(values: TaskValues, key: string): Promise<CreatedTask> {
  await wait();
  const earlier = stored.get(key);
  if (earlier) {
    return { ...earlier, replayed: true };
  }
  const title = values.title.toLowerCase();
  if (title === 'duplicate') {
    throw new ApiProblem({
      type: 'https://code101.example/problems/validation-error',
      title: 'Validation failed',
      status: 422,
      detail: 'One or more fields are invalid.',
      errors: [{ pointer: '/title', detail: 'A task with this title already exists.' }],
    });
  }
  if (title === 'boom') {
    throw new ApiProblem({
      type: 'https://code101.example/problems/internal',
      title: 'Internal server error',
      status: 500,
      traceId: '4bf92f3577b34da6a3ce929d0e0e4736',
    });
  }
  const task: CreatedTask = { ...values, id: nextId, replayed: false };
  nextId += 1;
  stored.set(key, task);
  if (title === 'flaky') {
    // The server saved the task, but the answer never reached the browser.
    throw new TypeError('Failed to fetch');
  }
  return task;
}
```
The `Map` plays the platform's idempotency store: the same key returns the first result, flagged here with `replayed: true` (the real API sends the response header `Idempotent-Replayed: true`).

### Step 5. A field, an error summary and the form
`Field` ties a label, an optional hint and an optional error message to one control. The control is passed as a **render function** so the field can give it the right `id` and `aria-describedby`.

**File: `src/components/Field.tsx`**
```tsx
import type { ReactNode } from 'react';

type FieldRenderProps = {
  id: string;
  describedBy: string | undefined;
  invalid: boolean;
};

type FieldProps = {
  name: string;
  label: string;
  hint?: string;
  error?: string;
  children: (props: FieldRenderProps) => ReactNode;
};

export default function Field({ name, label, hint, error, children }: FieldProps) {
  const inputId = `field-${name}`;
  const hintId = `${inputId}-hint`;
  const errorId = `${inputId}-error`;
  const describedBy = [hint ? hintId : '', error ? errorId : ''].filter(Boolean).join(' ') || undefined;
  return (
    <div className="field">
      <label htmlFor={inputId}>{label}</label>
      {hint && (
        <p id={hintId} className="hint">
          {hint}
        </p>
      )}
      {children({ id: inputId, describedBy, invalid: Boolean(error) })}
      {error && (
        <p id={errorId} className="error">
          <span className="visually-hidden">Error: </span>
          {error}
        </p>
      )}
    </div>
  );
}
```

**File: `src/components/ErrorSummary.tsx`**
```tsx
import type { RefObject } from 'react';
import type { FieldErrors } from '../forms/validate';

type ErrorSummaryProps = {
  errors: FieldErrors;
  headingRef: RefObject<HTMLHeadingElement | null>;
};

export default function ErrorSummary({ errors, headingRef }: ErrorSummaryProps) {
  const entries = Object.entries(errors);
  if (entries.length === 0) {
    return null;
  }
  return (
    <section className="summary" aria-labelledby="summary-title">
      <h2 id="summary-title" ref={headingRef} tabIndex={-1}>
        There {entries.length === 1 ? 'is 1 problem' : `are ${entries.length} problems`} with the form
      </h2>
      <ul>
        {entries.map(([name, message]) => (
          <li key={name}>
            <a
              href={`#field-${name}`}
              onClick={(event) => {
                event.preventDefault();
                document.getElementById(`field-${name}`)?.focus();
              }}
            >
              {message}
            </a>
          </li>
        ))}
      </ul>
    </section>
  );
}
```

**File: `src/components/TaskForm.tsx`**
```tsx
import { useEffect, useRef, useState, type FormEvent } from 'react';
import { ApiProblem } from '../api/problem';
import { submitTask, type CreatedTask } from '../fake-submit';
import { fieldErrorsFromProblem, priorities, readValues, validate, type FieldErrors } from '../forms/validate';
import ProblemPanel from '../shared/ProblemPanel';
import ErrorSummary from './ErrorSummary';
import Field from './Field';

type TaskFormProps = {
  onCreated: (task: CreatedTask) => void;
};

export default function TaskForm({ onCreated }: TaskFormProps) {
  const [errors, setErrors] = useState<FieldErrors>({});
  const [formError, setFormError] = useState<unknown>(null);
  const [pending, setPending] = useState(false);
  const summaryRef = useRef<HTMLHeadingElement>(null);
  const keyRef = useRef<string | null>(null);

  useEffect(() => {
    if (Object.keys(errors).length > 0) {
      summaryRef.current?.focus();
    }
  }, [errors]);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const form = event.currentTarget;
    const values = readValues(form);
    const found = validate(values);
    setFormError(null);
    if (Object.keys(found).length > 0) {
      setErrors(found);
      return;
    }
    setErrors({});
    keyRef.current ??= crypto.randomUUID();
    setPending(true);
    try {
      const task = await submitTask(values, keyRef.current);
      keyRef.current = null;
      form.reset();
      onCreated(task);
    } catch (error) {
      const uncertain = error instanceof TypeError || (error instanceof ApiProblem && error.status >= 500);
      if (!uncertain) {
        keyRef.current = null;
      }
      if (error instanceof ApiProblem && error.status === 422) {
        setErrors(fieldErrorsFromProblem(error));
      } else {
        setFormError(error);
      }
    } finally {
      setPending(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} noValidate>
      <h2>New task</h2>
      <ErrorSummary errors={errors} headingRef={summaryRef} />
      {formError !== null && <ProblemPanel error={formError} />}
      <Field name="title" label="Title" hint="Required, up to 200 characters." error={errors.title}>
        {({ id, describedBy, invalid }) => (
          <input id={id} name="title" aria-describedby={describedBy} aria-invalid={invalid} autoComplete="off" />
        )}
      </Field>
      <Field name="description" label="Description" error={errors.description}>
        {({ id, describedBy, invalid }) => (
          <textarea id={id} name="description" rows={3} aria-describedby={describedBy} aria-invalid={invalid} />
        )}
      </Field>
      <Field name="priority" label="Priority" error={errors.priority}>
        {({ id, describedBy, invalid }) => (
          <select id={id} name="priority" defaultValue="medium" aria-describedby={describedBy} aria-invalid={invalid}>
            {priorities.map((value) => (
              <option key={value} value={value}>
                {value}
              </option>
            ))}
          </select>
        )}
      </Field>
      <Field name="dueDate" label="Due date" hint="Optional. Format yyyy-mm-dd." error={errors.dueDate}>
        {({ id, describedBy, invalid }) => (
          <input id={id} name="dueDate" type="date" aria-describedby={describedBy} aria-invalid={invalid} />
        )}
      </Field>
      <button type="submit" disabled={pending}>
        {pending ? 'Saving...' : 'Create task'}
      </button>
    </form>
  );
}
```

### Step 6. The app and the styles
**File: `src/App.tsx`**
```tsx
import { useState } from 'react';
import TaskForm from './components/TaskForm';
import type { CreatedTask } from './fake-submit';

export default function App() {
  const [created, setCreated] = useState<CreatedTask[]>([]);
  return (
    <main>
      <h1>Forms lab</h1>
      <p>
        Try the titles <code>duplicate</code> (server says 422), <code>boom</code> (500) and <code>flaky</code> (the answer is lost, then
        you press the button again).
      </p>
      <TaskForm onCreated={(task) => setCreated((current) => [...current, task])} />
      <h2>Created tasks</h2>
      {created.length === 0 ? (
        <p>None yet.</p>
      ) : (
        <ul>
          {created.map((task) => (
            <li key={task.id}>
              #{task.id} {task.title} ({task.priority}
              {task.dueDate ? `, due ${task.dueDate}` : ''}){task.replayed ? ' - replayed answer, no duplicate' : ''}
            </li>
          ))}
        </ul>
      )}
    </main>
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
  max-width: 40rem;
  margin: 0 auto;
  padding: 1rem;
}

.field {
  margin: 1rem 0;
}

.field label {
  display: block;
  font-weight: bold;
}

.field input,
.field textarea,
.field select {
  font: inherit;
  width: 100%;
  box-sizing: border-box;
  padding: 0.4rem;
}

.field [aria-invalid='true'] {
  border: 2px solid #a11a1a;
}

.hint {
  margin: 0.2rem 0;
  font-size: 0.9rem;
}

.error {
  margin: 0.2rem 0;
  color: #a11a1a;
  font-weight: bold;
}

.summary,
.problem {
  border: 2px solid #a11a1a;
  border-radius: 0.5rem;
  padding: 0.5rem 1rem;
  margin: 1rem 0;
}

.visually-hidden {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip-path: inset(50%);
  white-space: nowrap;
}

button {
  font: inherit;
  padding: 0.5rem 1rem;
}

:focus-visible {
  outline: 3px solid #0759aa;
  outline-offset: 2px;
}
```

## Run it
**Folder: `forms-lab`**
```powershell
npm run dev
```
Open `http://localhost:5173/`. Expected, derived from the code:
1. Click **Create task** with an empty title. Expected: a bordered summary appears, keyboard focus moves to its heading "There is 1 problem with the form", with one link "Enter a title."; under the Title field the red text "Error: Enter a title." (the word "Error:" is spoken by screen readers only). The title box has a red border.
2. Click the link in the summary. Expected: focus moves to the Title box. Type `Write docs` and press Create task. Expected: "Saving..." for about 0.3 s, then "#1 Write docs (medium)" under Created tasks and the form is empty again.
3. Type `duplicate` and submit. Expected: the 422 path: the summary shows "A task with this title already exists." and the same text under Title. Change the title and submit again: it works (a new key was used, because a 422 is a definite answer).
4. Type `boom` and submit. Expected: the panel "The server had a problem" with a support code; no field message. Submit again (the same key is reused: a 500 is uncertain).
5. Type `flaky` and submit. Expected: the panel "You may be offline" (the answer was lost). Press Create task again. Expected: "#N flaky ... - replayed answer, no duplicate": the same key made the server return the first result instead of creating a second task.

## How it works
- **Reading values:** the inputs are uncontrolled: the browser keeps their text. On submit, `new FormData(form)` reads every control by its `name`. `event.currentTarget` is the form; it must be read **before** the first `await`, because React clears it afterwards.
- **Validation flow:** client check, then the call, then server answer. A client error stops before any request. A 422 answer is turned into the same `FieldErrors` shape, so the **same** components show both kinds of error. That is why `fieldErrorsFromProblem` exists.
- **Focus management:** after a failed submit the summary heading takes focus (`tabIndex={-1}` makes a heading focusable by script but keeps it out of the tab order). Screen reader users hear the heading and the list; keyboard users can jump to each field with the links.
- **Field wiring:** `label htmlFor` names the control; `aria-describedby` adds the hint and the error to its description; `aria-invalid` marks a bad value. The red border is **not** the only signal: the message has text too.
- **Idempotency key:** `crypto.randomUUID()` makes one key per user action. It is kept while the result is **uncertain** (network failure, 5xx) so a retry cannot create a duplicate, and discarded after a **definite** answer (success or 4xx), because a different body with the same key would be rejected by the platform.
- **Draft kept:** after errors the form is not reset, so the user does not retype (WCAG 3.3.7, redundant entry).

### Why this, not that
| Choice | Reason |
|---|---|
| Validate in a pure function | Same function for the client rules and (later) tests; no React needed |
| Error summary + inline messages | Summary for orientation and focus, inline for the exact place |
| `noValidate` + own messages | Consistent wording and styling; the native bubbles vary by browser |
| Re-validate on the server | Client checks are a courtesy; only the server can enforce rules |
| New key per attempt, same key per retry | Prevents duplicates without blocking a corrected resubmit |

**Common misconception:** "client validation protects the data." It protects the user's time. A client can be bypassed with one line of code; the API must check everything.

## Try it
Starter: `exercise/starter/src/forms/validate.ts` (one TODO).
1. **Guided.** Add the rule: a due date earlier than today is an error ("Pick today or a later date."). Expected: choose yesterday in the date picker and submit; the summary and the field show the message.
2. **Change.** Show the character count for the title in the hint ("12 of 200 characters"). You will need state; decide whether to make only this field controlled and explain the trade-off.
3. **Stretch (optional).** Make the 422 summary also list errors whose pointer is unknown to the form (for example `/assigneeId`) instead of dropping them. Decide where they should be shown.

<details><summary>Solution</summary>

**File: `exercise/solution/src/forms/validate.ts`** (the part that changes; the rest of the file is as in Step 3)
```typescript
  if (values.dueDate !== '' && !/^\d{4}-\d{2}-\d{2}$/.test(values.dueDate)) {
    errors.dueDate = 'Use the format yyyy-mm-dd.';
  } else if (values.dueDate !== '' && values.dueDate < new Date().toISOString().slice(0, 10)) {
    errors.dueDate = 'Pick today or a later date.';
  }
```
Text in `yyyy-mm-dd` form sorts like dates, so `<` works. `toISOString()` uses UTC, so near midnight the "today" can differ by one day from the local date; for a real product compare with the user's local date.

</details>

## Check yourself
1. Why read `event.currentTarget` before the first `await`? <details><summary>Answer</summary>After an await it may be null; keep the form element in a variable first.</details>
2. A request fails with a network error. Do you keep or drop the idempotency key? <details><summary>Answer</summary>Keep it: the server may have saved the task, and a retry with the same key returns that result.</details>
3. Predict: the server answers 422 with pointer `/color`. What does `fieldErrorsFromProblem` return? <details><summary>Answer</summary>An empty object: unknown names are ignored.</details>
4. Why is "Error: " hidden visually but present? <details><summary>Answer</summary>So that screen reader users hear that the text is an error, without cluttering the layout.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Cannot read properties of null (reading 'reset')` (typical message) | `event.currentTarget` read after `await` | Store the form in a variable first |
| The browser bubble appears instead of your message | `noValidate` missing | Add `noValidate` to the form |
| The summary never gets focus | The heading lacks `tabIndex={-1}`, or the ref is not attached | Check `ref={headingRef}` and `tabIndex={-1}` |
| Duplicate tasks after a retry | A new key per click | Keep the key while the outcome is uncertain |
| The field message is not read | No `aria-describedby`, or an id mismatch | Use `Field` for every control |
| `Type 'string' is not assignable to type 'Status'` (typical message) | Raw form text used as a union type | Validate with a type guard before using the value |

## Best practice
Show errors in an error summary that takes focus and next to each field, tie them with `aria-describedby`, never rely on colour alone, and keep what the user typed. Source: W3C WAI Forms Tutorial, Validating input https://www.w3.org/WAI/tutorials/forms/validation/

## Going further
- Where the same pattern runs against the real API: [web-react chapter 4](../../../../capstones/web-react/tutorials/phase-4-errors/04-errors-and-accessibility.md).
- Constraint validation API on MDN: https://developer.mozilla.org/en-US/docs/Web/HTML/Constraint_validation

## Summary
- You read a form with `FormData` and validated with pure functions.
- You built an error summary with focus management and fields tied by `aria-describedby`.
- You mapped 422 pointers to fields and used an idempotency key correctly.

## Next lesson
08. Performance: `memo`, code splitting and Suspense, and how to measure before you optimise.
