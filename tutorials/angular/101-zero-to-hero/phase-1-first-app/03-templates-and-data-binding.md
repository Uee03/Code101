---
track: angular
level: 101
phase: 1
phase_name: first-app
lesson: 03
title: "Templates and data binding"
time: 60 min
prerequisites: [angular-101.1.02]
versions: { node: "26.13.1", angular: "22.3.0", typescript: "6.0.3" }
verified: not yet run
source: source/angular/101-zero-to-hero/phase-1-first-app/03-templates-and-data-binding/
assets: []
---

# 03. Templates and data binding

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- Show a class value in a template with interpolation `{{ }}`.
- Set an element's property, attribute or CSS class from a value with `[ ]` bindings.
- Run a method when the user clicks or types with `( )` event bindings.
- Use a template reference variable (`#name`) to read an element, and explain the first idea of a signal.

## Recap
1. How does `App` use the `Greeting` component? <details><summary>Answer</summary>The class is imported in `app.ts`, added to the `imports` list, and `<app-greeting />` is written in `app.html`.</details>
2. What does `protected readonly` mean on a class member? <details><summary>Answer</summary>The member can be read in the class and its template but not changed or reached from outside.</details>
3. In Web 101 lesson 09 you handled a click with `addEventListener`. What did you need to find first? <details><summary>Answer</summary>The element, with `querySelector`. Angular templates attach the handler right where the element is written.</details>

## Why it matters
Picture a name tag at a conference: a printed frame with a blank space, and each person's name is written into the space. A **template** is the frame, **data binding** is how values from your class get written into it, and also how clicks and typing flow back. In Web 101 you used `querySelector` and `textContent` for this; Angular lets you describe the connection once, in the HTML, and keeps the page in step with the data.

## What you will build
Two small sections on the page. "One task" shows a title, a status you can toggle with a button, and a link. "Events" has a click counter, a text box that echoes what you type, and a button that clears it.

## Before you start
- Lesson 02 done and `npm start` running in `tasks-first`. Time: about 60 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/angular/101-zero-to-hero/phase-1-first-app/03-templates-and-data-binding/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).

## Steps

### Step 1. Know the four kinds of binding
| Syntax | Direction | Example in this lesson | Meaning |
|--------|-----------|------------------------|---------|
| `{{ expression }}` | class to page | `{{ taskTitle }}` | Insert the value as text |
| `[property]="expression"` | class to page | `[href]="docsUrl"` | Set a DOM **property** of the element |
| `[attr.name]="expression"` | class to page | `[attr.aria-pressed]="done()"` | Set an HTML **attribute** (for names that are not properties, like `aria-*`) |
| `[class.name]="condition"` | class to page | `[class.done]="done()"` | Add the CSS class only while the condition is true |
| `(event)="statement"` | page to class | `(click)="toggleDone()"` | Run a method when the event happens |

An **expression** is a small piece of code that produces a value (`done() ? 'done' : 'to do'` or `taskTitle.length`). Templates allow simple expressions, not loops or assignments: complicated logic belongs in the class.

### Step 2. Meet signals in one minute
Look at `done = signal(false)` in the next file. A **signal** is a box that holds a value and tells Angular when the value changes, so Angular knows exactly what to redraw. You make one with `signal(startValue)`, **read** it by calling it like a function, `done()`, and **change** it with `.set(newValue)` or `.update((old) => newValue)`. Lesson 04 goes deeper; for now remember: **read with parentheses, change with set or update**.

### Step 3. Write the class
**File: `src/app/app.ts`**
```ts
import { Component, signal } from '@angular/core';
import { Greeting } from './greeting/greeting';

@Component({
  selector: 'app-root',
  imports: [Greeting],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  protected readonly title = 'Tasks First';
  protected readonly taskTitle = 'Write the Angular lesson';
  protected readonly docsUrl = 'https://angular.dev';
  protected readonly done = signal(false);
  protected readonly clicks = signal(0);
  protected readonly note = signal('');

  protected toggleDone(): void {
    this.done.update((value) => !value);
  }

  protected countClick(): void {
    this.clicks.update((count) => count + 1);
  }

  protected updateNote(value: string): void {
    this.note.set(value);
  }
}
```

- `taskTitle` and `docsUrl` never change, so they are plain `readonly` values.
- `done`, `clicks` and `note` change while the page is used, so they are signals.
- `toggleDone()` flips the boolean: `update` receives the old value and returns the new one.
- `countClick()` adds one to the counter. `updateNote()` stores new text with `set`.
- Methods are `protected` for the same reason as properties: the template may use them.

### Step 4. Write the template
**File: `src/app/app.html`**
```html
<main class="page">
  <h1>{{ title }}</h1>
  <app-greeting />

  <section aria-labelledby="task-heading">
    <h2 id="task-heading">One task</h2>
    <p class="task" [class.done]="done()">{{ taskTitle }} ({{ taskTitle.length }} characters)</p>
    <p>Status: {{ done() ? 'done' : 'to do' }}</p>
    <button type="button" [attr.aria-pressed]="done()" (click)="toggleDone()">
      {{ done() ? 'Mark as to do' : 'Mark as done' }}
    </button>
    <p><a [href]="docsUrl">Open the Angular docs</a></p>
  </section>

  <section aria-labelledby="events-heading">
    <h2 id="events-heading">Events</h2>
    <button type="button" (click)="countClick()">Clicked {{ clicks() }} times</button>
    <p>
      <label for="note">Note</label>
      <input id="note" #noteBox type="text" [value]="note()" (input)="updateNote(noteBox.value)">
    </p>
    <p>You typed: {{ note() }}</p>
    <button type="button" [disabled]="note() === ''" (click)="updateNote('')">Clear note</button>
  </section>
</main>
```

Walk through it:
- `{{ taskTitle.length }}` runs `.length` on the string, so the page says "(24 characters)" (you can count them).
- `[class.done]="done()"` adds the class `done` while the signal is `true`; the CSS file styles it with a line through.
- `{{ done() ? 'done' : 'to do' }}` is the conditional (ternary) operator from JavaScript.
- `[attr.aria-pressed]="done()"` tells screen readers whether the toggle is on. It is an **attribute** binding because `aria-pressed` has no matching DOM property in the standard list.
- `[href]="docsUrl"` binds the **property** `href`. Angular sanitizes URL bindings: a value such as `javascript:...` is made harmless instead of being run.
- `(click)="toggleDone()"` runs the method on each click.
- `#noteBox` creates a **template reference variable**: a name for the element itself, valid in this template. `noteBox.value` reads what the user typed. `(input)` fires on every keystroke.
- `[value]="note()"` pushes the signal's value into the box; together with `(input)` the box and the signal stay in step. (Lesson 06 shows a shorter way, `ngModel`.)
- `[disabled]="note() === ''"` disables the button while the note is empty.

### Step 5. Style it
**File: `src/app/app.css`**
```css
.page {
  max-width: 40rem;
  margin: 0 auto;
}

h1 {
  color: #1d6fb8;
}

section {
  margin-top: 1.5rem;
}

.task {
  font-weight: 600;
}

.task.done {
  text-decoration: line-through;
  color: #4b5563;
}

input {
  margin-left: 0.5rem;
}
```

## Run it
Save all files with `npm start` running and open http://localhost:4200/.

**Predict before you click:** what does the status line say now? What does the button label say? After the first click, which two things change besides the label?

Expected behaviour (described from the code, not yet seen in a browser):
1. First view: "Status: to do", button "Mark as done", counter button "Clicked 0 times", an empty note box, "You typed: " with nothing after it, and a disabled "Clear note" button.
2. Click "Mark as done": the status says "done", the button label changes to "Mark as to do", the title gets a line through it and turns grey.
3. Click the counter three times: "Clicked 3 times".
4. Type "hi" in the box: "You typed: hi" updates as you type and "Clear note" becomes enabled. Click it: the box and the line empty out.

## How it works
1. Angular compiles each template to code that knows which signals it reads. When `done.update(...)` runs, only the parts of the page that read `done()` are redrawn.
2. Event bindings call your method; the method changes a signal; the changed signal redraws the places that read it. That chain (event, state, view) is the heartbeat of every Angular app.
3. **Property or attribute?** An HTML attribute is the text written in the tag (it sets the *initial* value); a DOM property is the live value on the element object. `[value]` and `[href]` set properties; `[attr.aria-pressed]` sets an attribute.

**Misconception:** "`{{ done }}` shows the signal's value." It does not: without the parentheses you refer to the signal object itself. Always call it: `{{ done() }}`.

## Try it
Starter files are in `exercise/starter/src/app/` (`app.ts` and `app.html`).
1. **Guided:** finish the four TODOs: a `priority` signal, a `togglePriority()` method, a "Priority:" line with a button, and the `urgent` class binding. (Add a `.task.urgent` rule to `app.css` with a colour that stands out.)
2. **Change:** add a second signal `likes` and a button "Like (n)" that adds one each time. Predict the label after three clicks.
3. **Stretch (optional):** make the note box show "n characters left" out of 40. Where should the number 40 live: in the template or in the class?

<details><summary>Solution for rung 1</summary>

**File: `exercise/solution/src/app/app.ts`**
```ts
import { Component, signal } from '@angular/core';
import { Greeting } from './greeting/greeting';

@Component({
  selector: 'app-root',
  imports: [Greeting],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  protected readonly title = 'Tasks First';
  protected readonly taskTitle = 'Write the Angular lesson';
  protected readonly docsUrl = 'https://angular.dev';
  protected readonly done = signal(false);
  protected readonly clicks = signal(0);
  protected readonly note = signal('');
  protected readonly priority = signal('normal');

  protected toggleDone(): void {
    this.done.update((value) => !value);
  }

  protected countClick(): void {
    this.clicks.update((count) => count + 1);
  }

  protected updateNote(value: string): void {
    this.note.set(value);
  }

  protected togglePriority(): void {
    this.priority.update((value) => (value === 'normal' ? 'high' : 'normal'));
  }
}
```

**File: `exercise/solution/src/app/app.html`**
```html
<main class="page">
  <h1>{{ title }}</h1>
  <app-greeting />

  <section aria-labelledby="task-heading">
    <h2 id="task-heading">One task</h2>
    <p class="task" [class.done]="done()" [class.urgent]="priority() === 'high'">{{ taskTitle }} ({{ taskTitle.length }} characters)</p>
    <p>Status: {{ done() ? 'done' : 'to do' }}</p>
    <button type="button" [attr.aria-pressed]="done()" (click)="toggleDone()">
      {{ done() ? 'Mark as to do' : 'Mark as done' }}
    </button>
    <p><a [href]="docsUrl">Open the Angular docs</a></p>
    <p>Priority: {{ priority() }} <button type="button" (click)="togglePriority()">Switch priority</button></p>
  </section>

  <section aria-labelledby="events-heading">
    <h2 id="events-heading">Events</h2>
    <button type="button" (click)="countClick()">Clicked {{ clicks() }} times</button>
    <p>
      <label for="note">Note</label>
      <input id="note" #noteBox type="text" [value]="note()" (input)="updateNote(noteBox.value)">
    </p>
    <p>You typed: {{ note() }}</p>
    <button type="button" [disabled]="note() === ''" (click)="updateNote('')">Clear note</button>
  </section>
</main>
```

**File: `exercise/solution/src/app/app.css`**
```css
.page {
  max-width: 40rem;
  margin: 0 auto;
}

h1 {
  color: #1d6fb8;
}

section {
  margin-top: 1.5rem;
}

.task {
  font-weight: 600;
}

.task.done {
  text-decoration: line-through;
  color: #4b5563;
}

.task.urgent {
  color: #b42318;
}

input {
  margin-left: 0.5rem;
}
```

</details>

## Check yourself
1. Which binding sets the CSS class `done` only while a condition is true? <details><summary>Answer</summary>`[class.done]="condition"`.</details>
2. The page shows `[object Object]` or a function text instead of `false`. What is the likely mistake? <details><summary>Answer</summary>A signal was written without parentheses (`{{ done }}` instead of `{{ done() }}`).</details>
3. Which statement changes the signal `clicks` by adding one? <details><summary>Answer</summary>`this.clicks.update((count) => count + 1)`.</details>
4. Predict: with the note box empty, is the "Clear note" button enabled? <details><summary>Answer</summary>No: `[disabled]="note() === ''"` is true while the note is empty.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| Typical message: `Property 'taskTitel' does not exist on type 'App'` | A typo in a template name; `strictTemplates` checks every name | Fix the spelling |
| Text shows `() => ...` or an object | A signal was used without `()` | Add `()` |
| The click does nothing | The handler is written `(click)="toggleDone"` without parentheses | Write `(click)="toggleDone()"` |
| Typical message: `Can't bind to 'hrf' since it isn't a known property of 'a'` | A misspelled property in a `[ ]` binding | Check the DOM property name (`href`) |

## Best practice
Keep templates simple: one short expression per binding, and move anything longer into a method or (lesson 04) a computed value. Source: Angular, Template syntax https://angular.dev/guide/templates

## Going further
- Binding overview: https://angular.dev/guide/templates/binding
- Event listeners: https://angular.dev/guide/templates/event-listeners

## Summary
- You inserted values with `{{ }}` and set properties, attributes and classes with `[ ]`.
- You handled clicks and typing with `( )` and a template reference variable.
- You made and read your first signals with `signal()`, `()`, `set` and `update`.

## Next lesson
04. Control flow and signals basics: show and hide parts of the page, repeat items with `@for`, and compute values.

<details>
<summary>Files that did not change in this lesson (listed so this page is complete)</summary>

**File: `src/app/greeting/greeting.css`**

```css
.greeting {
  background: #e8f1fb;
  border-left: 0.25rem solid #1d6fb8;
  padding: 0.75rem 1rem;
}
```

**File: `src/app/greeting/greeting.html`**

```html
<p class="greeting">{{ message }}</p>
```

**File: `src/app/greeting/greeting.ts`**

```ts
import { Component } from '@angular/core';

@Component({
  selector: 'app-greeting',
  templateUrl: './greeting.html',
  styleUrl: './greeting.css'
})
export class Greeting {
  protected readonly message = 'Welcome to your task list.';
}
```

**File: `src/styles.css`**

```css
body {
  font-family: system-ui, sans-serif;
  line-height: 1.5;
  margin: 2rem;
}
```

</details>
