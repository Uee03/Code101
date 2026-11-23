---
track: angular
level: 101
phase: 1
phase_name: first-app
lesson: 04
title: "Control flow (@if, @for, @switch) and signals basics"
time: 70 min
prerequisites: [angular-101.1.03]
versions: { node: "26.13.1", angular: "22.3.0", typescript: "6.0.3" }
verified: not yet run
source: source/angular/101-zero-to-hero/phase-1-first-app/04-control-flow-and-signals-basics/
assets: []
---

# 04. Control flow (@if, @for, @switch) and signals basics

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- Show or hide parts of a template with `@if`, `@else if` and `@else`.
- Repeat markup for each item of a list with `@for`, including `track` and `@empty`.
- Choose between cases with `@switch`.
- Keep state in a signal holding an array, derive values with `computed`, and change the array without mutating it.

## Recap
1. Which syntax calls a method when a button is clicked? <details><summary>Answer</summary>`(click)="method()"`.</details>
2. How do you read a signal and how do you change it? <details><summary>Answer</summary>Read by calling it, `done()`; change with `.set(value)` or `.update((old) => new)`.</details>
3. What does `[class.done]="done()"` do? <details><summary>Answer</summary>It adds the CSS class `done` while the signal's value is true.</details>

## Why it matters
A restaurant menu changes by the hour: dishes appear, sell out, or the whole page says "closed". Your page needs the same powers: show something only sometimes, print one line per item, pick one message out of several. Angular calls these **control flow** blocks. With them you describe the page for *any* data, instead of editing the page by hand each time the data changes.

## What you will build
A small task list: a status line ("2 tasks left."), three filter buttons (all, todo, done), a list of tasks with checkboxes, a message when the list is empty and a hint that depends on the filter. The task data lives in one signal.

## Before you start
- Lesson 03 done and `npm start` running in `tasks-first`. Time: about 70 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/angular/101-zero-to-hero/phase-1-first-app/04-control-flow-and-signals-basics/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- The `greeting` component from lesson 02 is removed in this lesson to keep the page focused: delete the folder `src/app/greeting`. Nothing else uses it.

## Steps

### Step 1. Describe a task with a type
In Web 101 you wrote TypeScript `interface`s. Put the shape of a task and the three filter names in their own file.

**File: `src/app/task.ts`**
```ts
export type Filter = 'all' | 'todo' | 'done';

export interface Task {
  id: number;
  title: string;
  done: boolean;
}
```

`Filter` is a **union type**: a value of that type can only be one of the three strings. A misspelled filter becomes a compile error, not a silent bug.

### Step 2. Write the class
**File: `src/app/app.ts`**
```ts
import { Component, computed, signal } from '@angular/core';
import { Filter, Task } from './task';

@Component({
  selector: 'app-root',
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  protected readonly title = 'Tasks First';
  protected readonly filters: readonly Filter[] = ['all', 'todo', 'done'];
  protected readonly tasks = signal<Task[]>([
    { id: 1, title: 'Install Node', done: true },
    { id: 2, title: 'Create the app', done: true },
    { id: 3, title: 'Learn control flow', done: false }
  ]);
  protected readonly filter = signal<Filter>('all');

  protected readonly remaining = computed(() => this.tasks().filter((task) => !task.done).length);
  protected readonly visibleTasks = computed(() => {
    const current = this.filter();
    return this.tasks().filter((task) => current === 'all' || (current === 'done' ? task.done : !task.done));
  });

  protected toggle(id: number): void {
    this.tasks.update((list) => list.map((task) => (task.id === id ? { ...task, done: !task.done } : task)));
  }

  protected setFilter(value: Filter): void {
    this.filter.set(value);
  }
}
```

- `signal<Task[]>([...])` creates a signal that holds an array of tasks. The text in angle brackets is the type of the value inside.
- `filter = signal<Filter>('all')` holds the current filter.
- `computed(() => ...)` creates a **computed signal**: a read-only value calculated from other signals. Angular remembers the result and recalculates it **only when a signal it read changes**. `remaining` counts the open tasks; `visibleTasks` applies the filter to the list.
- `toggle(id)` uses `update` with `map` to build a **new** array in which one task is a **new object** (`{ ...task, done: !task.done }`: copy the fields, replace `done`). We never change the old array or object. Signals notice a change when the value is a different object, so mutating the array in place (`push`, `task.done = true`) would not update the page.

### Step 3. Write the template with control flow
**File: `src/app/app.html`**
```html
<main class="page">
  <h1>{{ title }}</h1>

  @if (remaining() === 0) {
    <p class="status">All tasks are done.</p>
  } @else if (remaining() === 1) {
    <p class="status">One task left.</p>
  } @else {
    <p class="status">{{ remaining() }} tasks left.</p>
  }

  <div role="group" aria-label="Filter tasks">
    @for (option of filters; track option) {
      <button type="button" [class.active]="filter() === option" [attr.aria-pressed]="filter() === option" (click)="setFilter(option)">
        {{ option }}
      </button>
    }
  </div>

  <ul class="tasks">
    @for (task of visibleTasks(); track task.id; let i = $index) {
      <li [class.done]="task.done">
        <label>
          <input type="checkbox" [checked]="task.done" (change)="toggle(task.id)">
          {{ i + 1 }}. {{ task.title }}
        </label>
      </li>
    } @empty {
      <li class="empty">No tasks in this view.</li>
    }
  </ul>

  @switch (filter()) {
    @case ('all') {
      <p class="hint">Showing every task.</p>
    }
    @case ('todo') {
      <p class="hint">Showing tasks that still need work.</p>
    }
    @case ('done') {
      <p class="hint">Showing finished tasks.</p>
    }
  }
</main>
```

Reading the blocks:
- `@if (condition) { ... } @else if (condition) { ... } @else { ... }` renders the first block whose condition is true. Here: all done, exactly one left, or a count.
- `@for (task of visibleTasks(); track task.id; let i = $index)` renders the block once per item. **`track` is required**: it tells Angular how to recognise an item between updates (here by its `id`), so it can move or reuse the existing row instead of rebuilding the whole list. Use a unique, stable value (an id), not the index. `$index` is the position (starting at 0); `let i = $index` gives it a name.
- `@empty { ... }` is shown when the list has no items.
- `@switch (filter()) { @case ('all') { ... } ... }` picks one block by comparing the value to each `@case` with `===`.
- `[checked]="task.done"` shows the box state; `(change)="toggle(task.id)"` runs when the user clicks it. The `<label>` around the checkbox makes the text clickable and gives the checkbox its accessible name.
- `[attr.aria-pressed]` tells assistive technology which filter button is on.

### Step 4. Style it
**File: `src/app/app.css`**
```css
.page {
  max-width: 40rem;
  margin: 0 auto;
}

h1 {
  color: #1d6fb8;
}

.status {
  font-weight: 600;
}

button {
  margin-right: 0.5rem;
  padding: 0.375rem 0.75rem;
  text-transform: capitalize;
}

button.active {
  background: #1d6fb8;
  color: #ffffff;
}

.tasks {
  list-style: none;
  padding: 0;
}

.tasks li {
  padding: 0.5rem 0;
}

.tasks li.done {
  color: #4b5563;
  text-decoration: line-through;
}

.empty,
.hint {
  color: #4b5563;
}
```

`text-transform: capitalize` shows "all" as "All" without changing the data.

## Run it
Save everything and open http://localhost:4200/.

**Predict:** how many tasks are listed, what does the status line say, and which filter button is highlighted?

Expected behaviour (described from the code, not yet seen in a browser):
1. First view: "One task left.", the buttons All (highlighted), Todo, Done; three list rows: "1. Install Node" and "2. Create the app" with a line through them and ticked boxes, "3. Learn control flow" unticked; the hint "Showing every task.".
2. Click **Todo**: only "1. Learn control flow" remains and the hint changes.
3. Click **All**, then tick the third task: the status becomes "All tasks are done.". Click **Todo**: the list shows "No tasks in this view." (the `@empty` block).

## How it works
1. `tasks` and `filter` are the only **state**. Everything else is **derived**: `remaining` and `visibleTasks` are `computed`, and the template is a function of them.
2. Ticking a box calls `toggle`, which puts a new array into `tasks`. Angular re-runs the computed signals that read `tasks` and redraws the parts of the page that read them.
3. The old `*ngIf` and `*ngFor` directives still exist in older code. The `@if` and `@for` blocks are the current syntax: no import needed, built into the template compiler, and `track` is enforced.

**Misconception:** "I can just `push` into the array." The signal only changes when you set a *new* value. Copy, then change the copy: `list.map(...)`, `list.filter(...)`, `[...list, item]`.

## Try it
Starter files are in `exercise/starter/src/app/` (`app.ts`, `app.html`).
1. **Guided:** add `doneCount`, `clearDone()` and the "Clear finished" button (TODOs 1 to 3). Predict whether the button is enabled at first.
2. **Change:** add a fourth task "Ship it" to the initial array, and give each task a `priority` of `'normal'` or `'high'` in `task.ts`. Show "(high)" after high-priority titles with an `@if` inside the `@for`.
3. **Stretch (optional):** add an `@switch`-based icon or word in front of each task ("open", "done"). Decide whether that belongs in the template or in a computed signal.

<details><summary>Solution for rung 1</summary>

**File: `exercise/solution/src/app/app.ts`**
```ts
import { Component, computed, signal } from '@angular/core';
import { Filter, Task } from './task';

@Component({
  selector: 'app-root',
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  protected readonly title = 'Tasks First';
  protected readonly filters: readonly Filter[] = ['all', 'todo', 'done'];
  protected readonly tasks = signal<Task[]>([
    { id: 1, title: 'Install Node', done: true },
    { id: 2, title: 'Create the app', done: true },
    { id: 3, title: 'Learn control flow', done: false }
  ]);
  protected readonly filter = signal<Filter>('all');

  protected readonly remaining = computed(() => this.tasks().filter((task) => !task.done).length);
  protected readonly visibleTasks = computed(() => {
    const current = this.filter();
    return this.tasks().filter((task) => current === 'all' || (current === 'done' ? task.done : !task.done));
  });
  protected readonly doneCount = computed(() => this.tasks().filter((task) => task.done).length);

  protected toggle(id: number): void {
    this.tasks.update((list) => list.map((task) => (task.id === id ? { ...task, done: !task.done } : task)));
  }

  protected setFilter(value: Filter): void {
    this.filter.set(value);
  }

  protected clearDone(): void {
    this.tasks.update((list) => list.filter((task) => !task.done));
  }
}
```

**File: `exercise/solution/src/app/app.html`**
```html
<main class="page">
  <h1>{{ title }}</h1>

  @if (remaining() === 0) {
    <p class="status">All tasks are done.</p>
  } @else if (remaining() === 1) {
    <p class="status">One task left.</p>
  } @else {
    <p class="status">{{ remaining() }} tasks left.</p>
  }

  <div role="group" aria-label="Filter tasks">
    @for (option of filters; track option) {
      <button type="button" [class.active]="filter() === option" [attr.aria-pressed]="filter() === option" (click)="setFilter(option)">
        {{ option }}
      </button>
    }
  </div>

  <ul class="tasks">
    @for (task of visibleTasks(); track task.id; let i = $index) {
      <li [class.done]="task.done">
        <label>
          <input type="checkbox" [checked]="task.done" (change)="toggle(task.id)">
          {{ i + 1 }}. {{ task.title }}
        </label>
      </li>
    } @empty {
      <li class="empty">No tasks in this view.</li>
    }
  </ul>

  <button type="button" [disabled]="doneCount() === 0" (click)="clearDone()">Clear finished</button>

  @switch (filter()) {
    @case ('all') {
      <p class="hint">Showing every task.</p>
    }
    @case ('todo') {
      <p class="hint">Showing tasks that still need work.</p>
    }
    @case ('done') {
      <p class="hint">Showing finished tasks.</p>
    }
  }
</main>
```

</details>

## Check yourself
1. Why does `@for` need `track`? <details><summary>Answer</summary>So Angular can identify each item across updates and reuse its row instead of recreating the list.</details>
2. What does `computed` give you that a method called from the template does not? <details><summary>Answer</summary>The value is cached and recalculated only when a signal it read changes.</details>
3. The checkbox is ticked but the page does not update. The handler is `list[0].done = true`. What is wrong? <details><summary>Answer</summary>It mutates the existing array and object; a signal needs a new value. Use `update` with `map` and a copied object.</details>
4. Predict: with the filter on Done and no finished tasks, which line is shown in the list? <details><summary>Answer</summary>"No tasks in this view." from `@empty`.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| Typical message: `@for` loop requires a `track` expression | `track` is missing | Add `track task.id` |
| Typical message: `Property 'doneCount' does not exist on type 'App'` | The template uses a name the class does not have (TODO 1 forgotten) | Add the member or fix the spelling |
| The list does not update after a click | The array was changed in place | Return a new array from `update` |
| Text shows the function instead of a number | `remaining` used without `()` | Write `remaining()` |
| Typical message: a block is not closed (`Unexpected closing block`) | A `}` is missing or extra in the template | Match every `{` of `@if`, `@for`, `@switch` with a `}` |

## Best practice
Keep the smallest possible state and derive the rest with `computed`; never store the same fact twice. Source: Angular, Signals guide https://angular.dev/guide/signals

## Going further
- Control flow guide: https://angular.dev/guide/templates/control-flow
- `@defer` (load parts of a page later): https://angular.dev/guide/templates/defer

## Summary
- You showed and hid markup with `@if`, repeated it with `@for` and `@empty`, and switched with `@switch`.
- You kept a list in one signal and changed it by creating new arrays and objects.
- You derived `remaining` and `visibleTasks` with `computed`.

## Next lesson
05. Component inputs and outputs: split the list into a reusable task item that talks to its parent.

<details>
<summary>Files that did not change in this lesson (listed so this page is complete)</summary>

**File: `src/styles.css`**

```css
body {
  font-family: system-ui, sans-serif;
  line-height: 1.5;
  margin: 2rem;
}
```

</details>
