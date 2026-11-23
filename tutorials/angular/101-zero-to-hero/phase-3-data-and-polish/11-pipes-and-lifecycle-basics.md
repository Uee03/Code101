---
track: angular
level: 101
phase: 3
phase_name: data-and-polish
lesson: 11
title: "Pipes and component lifecycle basics"
time: 65 min
prerequisites: [angular-101.3.10]
versions: { node: "26.13.1", angular: "22.3.0", typescript: "6.0.3", rxjs: "7.8.2" }
verified: not yet run
source: source/angular/101-zero-to-hero/phase-3-data-and-polish/11-pipes-and-lifecycle-basics/
assets: []
---

# 11. Pipes and component lifecycle basics

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- Format values in a template with the built-in `date`, `titlecase` and `json` pipes, with and without arguments.
- Write a small custom pipe.
- Name the lifecycle moments of a component (created, initialised, destroyed) and clean up in `ngOnDestroy`.
- Use the `async` pipe so Angular subscribes and unsubscribes for you.

## Recap
1. Which part of `HttpClient` does nothing until you use it? <details><summary>Answer</summary>The Observable returned by `get`: nothing is sent until `subscribe` (or the `async` pipe).</details>
2. Why is `aria-hidden="true"` set on decorative icons? <details><summary>Answer</summary>So screen readers do not announce an empty image.</details>
3. What state shows while data is on its way? <details><summary>Answer</summary>The `loading` state, with `role="status"`.</details>

## Why it matters
A pipe is a lens on a camera: the scene (your data) does not change, but what you see through the lens does. A date stored as `2026-12-01` is right for the computer and wrong for a person who expects "Dec 1, 2026". And a component is like a rented room: you move in (it is created), you use it, and you must hand back the key (clean up timers and subscriptions) when you leave, or the next tenant pays for it. Pipes and lifecycle hooks are the two small tools for those jobs.

## What you will build
Tasks get optional due dates shown as "Due Dec 1, 2026"; long titles are shortened by your own `shorten` pipe; the detail page shows a full date, a title-cased status and the raw data in a collapsible block; and the Home page gets a "Two clocks" box that shows both a hand-cleaned timer and an `async`-pipe timer.

## Before you start
- Lesson 10 done. Time: about 65 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/angular/101-zero-to-hero/phase-3-data-and-polish/11-pipes-and-lifecycle-basics/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).

## Steps

### Step 1. Add the due date to the data
**File: `src/app/task.ts`** (new optional field `due`)
```ts
export type Filter = 'all' | 'todo' | 'done';

export interface Task {
  id: number;
  title: string;
  done: boolean;
  due?: string;
}
```

`due?: string` means "may be missing". The value is a date text `yyyy-MM-dd`.

**File: `public/api/tasks.json`**
```json
[
  { "id": 1, "title": "Install Node", "done": true },
  { "id": 2, "title": "Create the app", "done": true },
  { "id": 3, "title": "Learn control flow", "done": false, "due": "2026-12-01" },
  { "id": 4, "title": "Call an API and show the answer in the page", "done": false, "due": "2026-12-15" }
]
```

### Step 2. Write a custom pipe
A **pipe** takes a value, optionally some arguments, and returns a new value to display. In a template you chain it with `|`: `{{ title | shorten: 25 }}` means "pass `title` through the `shorten` pipe with the argument 25".

**File: `src/app/shorten.ts`**
```ts
import { Pipe, PipeTransform } from '@angular/core';

@Pipe({ name: 'shorten' })
export class Shorten implements PipeTransform {
  transform(value: string, max = 30): string {
    return value.length > max ? value.slice(0, max - 3) + '...' : value;
  }
}
```

- `@Pipe({ name: 'shorten' })` registers the pipe under the name used in templates.
- `implements PipeTransform` makes TypeScript check that the class has a `transform` method with the right shape.
- `transform(value, max = 30)` is called by Angular. The first parameter is the value on the left of `|`; the others are the arguments after the colons. The result is shown.
- By default a pipe is **pure**: Angular calls it again only when its input values change, not on every redraw. That is why a pipe should depend only on its inputs (no `Date.now()` inside).

### Step 3. Use built-in and custom pipes
**File: `src/app/task-item/task-item.ts`** (imports the pipes it uses; a template can only use pipes listed in `imports`)
```ts
import { DatePipe } from '@angular/common';
import { Component, input, output } from '@angular/core';
import { RouterLink } from '@angular/router';
import { Shorten } from '../shorten';
import { Task } from '../task';

@Component({
  selector: 'li[app-task-item]',
  imports: [DatePipe, RouterLink, Shorten],
  templateUrl: './task-item.html',
  styleUrl: './task-item.css',
  host: {
    '[class.done]': 'task().done'
  }
})
export class TaskItem {
  readonly task = input.required<Task>();
  readonly position = input(1);
  readonly toggled = output<number>();
  readonly removed = output<number>();

  protected toggle(): void {
    this.toggled.emit(this.task().id);
  }

  protected remove(): void {
    this.removed.emit(this.task().id);
  }
}
```

**File: `src/app/task-item/task-item.html`**
```html
<span class="title">
  <input type="checkbox" [checked]="task().done" [attr.aria-label]="'Done: ' + task().title" (change)="toggle()">
  {{ position() }}. <a [routerLink]="['/tasks', task().id]">{{ task().title | shorten: 25 }}</a>
  @if (task().due) {
    <small class="due">Due {{ task().due | date: 'mediumDate' }}</small>
  }
</span>
<button type="button" class="remove" [attr.aria-label]="'Remove ' + task().title" (click)="remove()">
  <span class="icon icon-x" aria-hidden="true"></span>
</button>
```

`date: 'mediumDate'` formats a date with a named format; for English (US) it gives `Dec 1, 2026`. `@if (task().due)` shows the due date only when the field exists. Both `string` dates like `2026-12-01` and `Date` objects work.

**File: `src/app/task-item/task-item.css`**
```css
:host {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.5rem 0;
  border-bottom: 1px solid var(--color-border);
}

:host(.done) .title {
  color: var(--color-muted);
  text-decoration: line-through;
}

input[type='checkbox'] {
  width: 1.25rem;
  height: 1.25rem;
  margin-right: 0.5rem;
  vertical-align: middle;
}

.due {
  margin-left: 0.5rem;
  color: var(--color-muted);
}

.remove {
  min-width: 2.25rem;
  justify-content: center;
}
```

**File: `src/app/pages/task-detail/task-detail.ts`**
```ts
import { DatePipe, JsonPipe, TitleCasePipe } from '@angular/common';
import { Component, computed, inject, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TaskStore } from '../../task-store';

@Component({
  selector: 'app-task-detail-page',
  imports: [DatePipe, JsonPipe, RouterLink, TitleCasePipe],
  templateUrl: './task-detail.html'
})
export class TaskDetailPage {
  protected readonly store = inject(TaskStore);

  readonly id = input.required<string>();
  protected readonly task = computed(() => this.store.byId(Number(this.id())));
}
```

**File: `src/app/pages/task-detail/task-detail.html`**
```html
@if (store.status() === 'loading') {
  <p role="status">Loading the task...</p>
} @else {
  @if (task(); as found) {
    <h1>{{ found.title }}</h1>
    <p>Task number {{ found.id }}. Status: {{ (found.done ? 'done' : 'to do') | titlecase }}.</p>
    @if (found.due) {
      <p>Due: {{ found.due | date: 'fullDate' }}</p>
    }
    <details>
      <summary>Raw data</summary>
      <pre>{{ found | json }}</pre>
    </details>
  } @else {
    <h1>Task not found</h1>
    <p>There is no task with the number "{{ id() }}".</p>
  }
}
<p><a routerLink="/tasks">Back to the list</a></p>
```

- `(found.done ? 'done' : 'to do') | titlecase` capitalises each word: "Done" or "To Do". **Parentheses are needed**: the pipe operator binds more loosely than `?:`, so without them it would apply to the wrong part.
- `date: 'fullDate'` gives `Tuesday, December 1, 2026` for the first dated task.
- `json` shows an object as indented JSON text: a handy tool when you debug what the template really receives.
- `<details>` and `<summary>` are native HTML for a disclosure widget: keyboard accessible without code.

### Step 4. A component with a lifecycle
Create `src/app/clock/clock.ts`, `clock.html` and `clock.css`.

**File: `src/app/clock/clock.ts`**
```ts
import { AsyncPipe, DatePipe } from '@angular/common';
import { Component, OnDestroy, OnInit, signal } from '@angular/core';
import { map, timer } from 'rxjs';

@Component({
  selector: 'app-clock',
  imports: [AsyncPipe, DatePipe],
  templateUrl: './clock.html',
  styleUrl: './clock.css'
})
export class Clock implements OnInit, OnDestroy {
  protected readonly manual = signal(new Date());
  protected readonly automatic = timer(0, 1000).pipe(map(() => new Date()));
  private timerId: ReturnType<typeof setInterval> | undefined;

  ngOnInit(): void {
    this.timerId = setInterval(() => this.manual.set(new Date()), 1000);
  }

  ngOnDestroy(): void {
    clearInterval(this.timerId);
  }
}
```

**File: `src/app/clock/clock.html`**
```html
<section aria-labelledby="clock-heading">
  <h2 id="clock-heading">Two clocks</h2>
  <p>Manual (starts in ngOnInit, stops in ngOnDestroy): {{ manual() | date: 'mediumTime' }}</p>
  <p>Automatic (the async pipe subscribes and unsubscribes): {{ automatic | async | date: 'mediumTime' }}</p>
</section>
```

**File: `src/app/clock/clock.css`**
```css
section {
  margin-top: 1.5rem;
  padding: 0.75rem 1rem;
  border: 1px solid var(--color-border);
  border-radius: var(--radius);
}

p {
  margin: 0.25rem 0;
  font-variant-numeric: tabular-nums;
}
```

The component's life, in order:

| Moment | What runs | Use it for |
|--------|-----------|------------|
| Created | constructor and field initialisers | Setting up fields, `inject()` |
| Initialised | `ngOnInit()`, once, after the inputs are first set | Starting work that needs the inputs (timers, loading) |
| Rendered | `afterNextRender(...)`, after the first draw in the browser | Code that must touch the real DOM elements |
| Destroyed | `ngOnDestroy()`, when the page or block is removed | **Cleaning up**: timers, event listeners, subscriptions |

You opt into a hook by implementing its interface (`OnInit`, `OnDestroy`) and writing the method.

Here, `ngOnInit` starts a timer that updates the `manual` signal each second and `ngOnDestroy` stops it. If you forgot `clearInterval`, the timer would keep running after you leave the Home page and a new one would start each time you come back: a **leak**.

The second line uses an Observable `timer(0, 1000)` (start at once, then every second) mapped to a `Date`, shown with `| async`. The **`async` pipe** subscribes when the component appears and unsubscribes when it is destroyed, so you cannot forget the cleanup. Use it for Observables in templates.

### Step 5. Use the clock on the Home page
**File: `src/app/pages/home/home.ts`**
```ts
import { Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { Clock } from '../../clock/clock';
import { TaskStore } from '../../task-store';

@Component({
  selector: 'app-home',
  imports: [Clock, RouterLink],
  template: `
    <h1>Welcome</h1>
    @if (store.status() === 'ready') {
      <p>Open tasks: {{ store.remaining() }}. Go to the <a routerLink="/tasks">task list</a>.</p>
    } @else {
      <p>Loading your tasks...</p>
    }
    <app-clock />
  `
})
export class Home {
  protected readonly store = inject(TaskStore);
}
```

## Run it
Save everything and open http://localhost:4200/.

**Predict:** on the Tasks page, how does the fourth task's title appear, and what does the detail page for task 3 show as its due date?

Expected behaviour (described from the code, not yet seen in a browser; the clock times depend on your computer):
1. Home: "Open tasks: 2." and a "Two clocks" box where both lines show the current time (for example "3:07:41 PM") and tick every second.
2. Tasks: the third task shows "Due Dec 1, 2026"; the fourth title is cut to "Call an API and show t..." followed by "Due Dec 15, 2026".
3. Open the third task: "Task number 3. Status: To Do.", "Due: Tuesday, December 1, 2026" and a "Raw data" disclosure that expands to `{ "id": 3, "title": "Learn control flow", "done": false, "due": "2026-12-01" }` printed as indented JSON.
4. Go Home, then Tasks, then Home again several times: only one set of clocks ticks. (To see what a leak would look like, comment out the `clearInterval` line, add a `console.log` to the interval and watch the console grow after each visit. Put it back afterwards.)

## How it works
1. Angular creates a component when its place in the template becomes active (here, when the router shows the page), runs the hooks in the order above, and destroys it when it is removed.
2. A pure pipe is a function Angular remembers: same inputs, same result, no recalculation. That makes pipes cheap compared with calling a method in the template.
3. The `async` pipe turns an Observable into plain values for the template and ties the subscription to the component's life.
4. In signal-based code you often need fewer hooks: `computed` replaces most `ngOnChanges` work, and `inject(DestroyRef).onDestroy(() => ...)` lets any code register a cleanup without implementing an interface.

**Misconception:** "the constructor is the place to start work." Keep the constructor for setting fields and injecting; start timers and requests in `ngOnInit` or in a service, so inputs are available and tests can control timing.

## Try it
Starter file: `exercise/starter/src/app/plural.ts`.
1. **Guided:** finish the `plural` pipe (TODO 1), add it to the Home component's `imports`, and show `{{ store.remaining() | plural: 'open task' }}` in place of "Open tasks: N".
2. **Change:** add a `done` count pipe use: write "N tasks left" in the Tasks page using your pipe; check that `1` gives "1 open task" and `2` "2 open tasks".
3. **Stretch (optional):** write a `dueIn` pipe that takes a date text and returns "overdue", "today" or "in N days". It reads the current date, so it is **impure**: what changes in the decorator, and why is that expensive?

<details><summary>Solution for rung 1</summary>

**File: `exercise/solution/src/app/plural.ts`**
```ts
import { Pipe, PipeTransform } from '@angular/core';

@Pipe({ name: 'plural' })
export class Plural implements PipeTransform {
  transform(count: number, word: string): string {
    return String(count) + ' ' + word + (count === 1 ? '' : 's');
  }
}
```

In `home.ts`, import `Plural` from `'../../plural'`, add it to `imports` and write `<p>{{ store.remaining() | plural: 'open task' }}. Go to the <a routerLink="/tasks">task list</a>.</p>`.

</details>

## Check yourself
1. In `{{ value | date: 'mediumDate' }}`, which part is the argument? <details><summary>Answer</summary>`'mediumDate'`, after the colon.</details>
2. Why must `(cond ? 'a' : 'b') | titlecase` have parentheses? <details><summary>Answer</summary>The pipe operator has lower precedence than the conditional operator, so without parentheses it applies only to `'b'`.</details>
3. What goes wrong if `ngOnDestroy` does not clear the interval? <details><summary>Answer</summary>The timer keeps running after the component is gone, and each new visit starts another one: a leak.</details>
4. How does the `async` pipe prevent that leak? <details><summary>Answer</summary>It unsubscribes automatically when the component is destroyed.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| Typical message: `NG8004: No pipe found with name 'shorten'` | The pipe class is not in the component's `imports` | Add `Shorten` to `imports` |
| Typical message: `NG02100: InvalidPipeArgument` | A pipe received a value of the wrong kind (for example `date` with random text) | Pass a valid date string, number or `Date` |
| Status shows `done` in lower case on the detail page | `titlecase` is not applied or the parentheses are missing | Check the expression |
| Clock does not start | `OnInit` is not implemented or the method name is misspelled | Use `ngOnInit` exactly |
| `Raw data` shows `[object Object]` | `json` pipe is missing | Add `\| json` and import `JsonPipe` |
| Date shows in the wrong language | The default locale is English (US) | Locale setup is a topic of level 201 lesson 09 |

## Best practice
Make every pipe pure, keep it small, and clean up in `ngOnDestroy` (or use `async` or `DestroyRef`). Source: Angular, Pipes https://angular.dev/guide/templates/pipes and Component lifecycle https://angular.dev/guide/components/lifecycle

## Going further
- Built-in pipes list: https://angular.dev/guide/templates/pipes
- Lifecycle hooks: https://angular.dev/guide/components/lifecycle
- RxJS basics, `async` and signal interop: level 201 lesson 02.

## Summary
- You formatted dates and text with built-in pipes and wrote your own pure pipe.
- You named the lifecycle moments and cleaned up a timer in `ngOnDestroy`.
- You used the `async` pipe to let Angular manage a subscription.

## Next lesson
12. Project: a task list app: put everything together in one new project.

<details>
<summary>Files that did not change in this lesson (listed so this page is complete)</summary>

**File: `public/icons/arrows/refresh-cw.svg`**

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" role="img" aria-label="Refresh Cw">
  <polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/>
</svg>
```

**File: `public/icons/ui/alert-triangle.svg`**

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" role="img" aria-label="Alert Triangle">
  <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/>
</svg>
```

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

**File: `src/app/app-title.ts`**

```ts
import { InjectionToken } from '@angular/core';

export const APP_TITLE = new InjectionToken<string>('APP_TITLE');
```

**File: `src/app/app.config.ts`**

```ts
import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideHttpClient, withFetch } from '@angular/common/http';
import { provideRouter, withComponentInputBinding } from '@angular/router';

import { APP_TITLE } from './app-title';
import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideHttpClient(withFetch()),
    provideRouter(routes, withComponentInputBinding()),
    { provide: APP_TITLE, useValue: 'Tasks First' }
  ]
};
```

**File: `src/app/app.css`**

```css
.site-header {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.75rem 1.5rem;
  max-width: 40rem;
  margin: 0 auto 1.5rem;
  padding-bottom: 0.75rem;
  border-bottom: 1px solid var(--color-border);
}

.brand {
  font-size: 1.25rem;
  font-weight: 700;
  text-decoration: none;
}

nav {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
}

nav a.active {
  font-weight: 700;
  text-decoration: none;
}

.page {
  max-width: 40rem;
  margin: 0 auto;
}

.page:focus {
  outline: none;
}
```

**File: `src/app/app.html`**

```html
<a class="skip-link" href="#main">Skip to content</a>

<header class="site-header">
  <a class="brand" routerLink="/">{{ appTitle }}</a>
  <nav aria-label="Main">
    <a routerLink="/" routerLinkActive="active" ariaCurrentWhenActive="page" [routerLinkActiveOptions]="{ exact: true }">Home</a>
    <a routerLink="/tasks" routerLinkActive="active" ariaCurrentWhenActive="page">Tasks ({{ store.remaining() }} open)</a>
    <a routerLink="/about" routerLinkActive="active" ariaCurrentWhenActive="page">About</a>
  </nav>
</header>

<main id="main" #main class="page" tabindex="-1">
  <router-outlet (activate)="pageChanged()" />
</main>
```

**File: `src/app/app.routes.ts`**

```ts
import { Routes } from '@angular/router';
import { About } from './pages/about/about';
import { Home } from './pages/home/home';
import { NotFound } from './pages/not-found/not-found';
import { TaskDetailPage } from './pages/task-detail/task-detail';
import { TasksPage } from './pages/tasks/tasks';

export const routes: Routes = [
  { path: '', component: Home, title: 'Home' },
  { path: 'tasks', component: TasksPage, title: 'Tasks' },
  { path: 'tasks/:id', component: TaskDetailPage, title: 'Task details' },
  { path: 'about', component: About, title: 'About' },
  { path: '**', component: NotFound, title: 'Page not found' }
];
```

**File: `src/app/app.ts`**

```ts
import { Component, ElementRef, inject, viewChild } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { APP_TITLE } from './app-title';
import { TaskStore } from './task-store';

@Component({
  selector: 'app-root',
  imports: [RouterLink, RouterLinkActive, RouterOutlet],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  protected readonly appTitle = inject(APP_TITLE);
  protected readonly store = inject(TaskStore);
  private readonly main = viewChild.required<ElementRef<HTMLElement>>('main');
  private firstPage = true;

  protected pageChanged(): void {
    if (this.firstPage) {
      this.firstPage = false;
      return;
    }
    this.main().nativeElement.focus();
  }
}
```

**File: `src/app/new-task-reactive/new-task-reactive.css`**

```css
form {
  margin: 1rem 0;
}

label {
  display: block;
  font-weight: 600;
}

input {
  min-height: 2.25rem;
  margin-right: 0.5rem;
  padding: 0 0.5rem;
  border: 1px solid var(--color-muted);
  border-radius: var(--radius);
  font: inherit;
}

.error {
  margin: 0.25rem 0 0;
  color: var(--color-danger);
}
```

**File: `src/app/new-task-reactive/new-task-reactive.html`**

```html
<form [formGroup]="form" (ngSubmit)="submit()" novalidate>
  <label for="title-reactive">New task</label>
  <input
    id="title-reactive"
    type="text"
    formControlName="title"
    [attr.aria-invalid]="title.invalid && title.touched"
    aria-describedby="title-reactive-error">
  <button type="submit">
    <span class="icon icon-plus" aria-hidden="true"></span>
    Add
  </button>
  @if (title.invalid && title.touched) {
    <p id="title-reactive-error" class="error" role="alert">
      @if (title.hasError('required')) {
        Enter a title.
      } @else {
        Use at least 3 characters.
      }
    </p>
  }
</form>
```

**File: `src/app/new-task-reactive/new-task-reactive.ts`**

```ts
import { Component, inject, output } from '@angular/core';
import { NonNullableFormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';

@Component({
  selector: 'app-new-task-reactive',
  imports: [ReactiveFormsModule],
  templateUrl: './new-task-reactive.html',
  styleUrl: './new-task-reactive.css'
})
export class NewTaskReactive {
  private readonly fb = inject(NonNullableFormBuilder);

  readonly added = output<string>();
  protected readonly form = this.fb.group({
    title: ['', [Validators.required, Validators.minLength(3)]]
  });
  protected readonly title = this.form.controls.title;

  protected submit(): void {
    const value = this.title.value.trim();
    if (this.form.invalid || value === '') {
      this.form.markAllAsTouched();
      return;
    }
    this.added.emit(value);
    this.form.reset();
  }
}
```

**File: `src/app/pages/about/about.ts`**

```ts
import { Component } from '@angular/core';

@Component({
  selector: 'app-about',
  template: `
    <h1>About</h1>
    <p>Tasks First is the practice app of the Code101 Angular 101 track.</p>
  `
})
export class About {}
```

**File: `src/app/pages/not-found/not-found.ts`**

```ts
import { Component } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-not-found',
  imports: [RouterLink],
  template: `
    <h1>Page not found</h1>
    <p>There is nothing at this address. <a routerLink="/">Go to the home page</a>.</p>
  `
})
export class NotFound {}
```

**File: `src/app/pages/tasks/tasks.css`**

```css
h1 {
  color: var(--color-brand);
}

.status {
  font-weight: 600;
}

.filters {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin: 1rem 0;
}

.filters button {
  text-transform: capitalize;
}

.problem {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 1rem;
  border-left: 0.25rem solid var(--color-danger);
  background: #fdecea;
}

.problem p {
  margin: 0;
}

.problem .icon {
  color: var(--color-danger);
}

.tasks {
  list-style: none;
  padding: 0;
}

.empty,
.hint {
  color: var(--color-muted);
}
```

**File: `src/app/pages/tasks/tasks.html`**

```html
<h1>Tasks</h1>

@switch (store.status()) {
  @case ('loading') {
    <p role="status">Loading tasks...</p>
  }
  @case ('error') {
    <div class="problem" role="alert">
      <span class="icon icon-alert" aria-hidden="true"></span>
      <p>{{ store.message() }}</p>
      <button type="button" (click)="store.load()">
        <span class="icon icon-refresh" aria-hidden="true"></span>
        Try again
      </button>
    </div>
  }
  @case ('ready') {
    <app-new-task-reactive (added)="store.add($event)" />

    @if (store.remaining() === 0) {
      <p class="status">All tasks are done.</p>
    } @else if (store.remaining() === 1) {
      <p class="status">One task left.</p>
    } @else {
      <p class="status">{{ store.remaining() }} tasks left.</p>
    }

    <div class="filters" role="group" aria-label="Filter tasks">
      @for (option of filters; track option) {
        <button type="button" [class.active]="filter() === option" [attr.aria-pressed]="filter() === option" (click)="setFilter(option)">
          {{ option }}
        </button>
      }
    </div>

    <ul class="tasks">
      @for (task of visibleTasks(); track task.id; let i = $index) {
        <li app-task-item [task]="task" [position]="i + 1" (toggled)="store.toggle($event)" (removed)="store.remove($event)"></li>
      } @empty {
        <li class="empty">No tasks in this view.</li>
      }
    </ul>
  }
}

<p class="hint">
  The tasks come from <code>/api/tasks.json</code>. Practice the error case:
  <button type="button" (click)="store.load(brokenUrl)">Load from an address where nothing listens</button>
</p>
```

**File: `src/app/pages/tasks/tasks.ts`**

```ts
import { Component, computed, inject, signal } from '@angular/core';
import { NewTaskReactive } from '../../new-task-reactive/new-task-reactive';
import { TaskItem } from '../../task-item/task-item';
import { Filter } from '../../task';
import { TaskStore } from '../../task-store';

@Component({
  selector: 'app-tasks-page',
  imports: [NewTaskReactive, TaskItem],
  templateUrl: './tasks.html',
  styleUrl: './tasks.css'
})
export class TasksPage {
  protected readonly store = inject(TaskStore);
  protected readonly filters: readonly Filter[] = ['all', 'todo', 'done'];
  protected readonly filter = signal<Filter>('all');
  protected readonly brokenUrl = 'http://localhost:9/api/tasks.json';

  protected readonly visibleTasks = computed(() => {
    const current = this.filter();
    return this.store.tasks().filter((task) => current === 'all' || (current === 'done' ? task.done : !task.done));
  });

  protected setFilter(value: Filter): void {
    this.filter.set(value);
  }
}
```

**File: `src/app/task-store.ts`**

```ts
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { computed, inject, Injectable, signal } from '@angular/core';
import { Task } from './task';

export type LoadStatus = 'loading' | 'ready' | 'error';

@Injectable({ providedIn: 'root' })
export class TaskStore {
  private readonly http = inject(HttpClient);
  private readonly items = signal<Task[]>([]);
  private readonly state = signal<LoadStatus>('loading');
  private readonly problem = signal('');

  readonly tasks = this.items.asReadonly();
  readonly status = this.state.asReadonly();
  readonly message = this.problem.asReadonly();
  readonly remaining = computed(() => this.items().filter((task) => !task.done).length);

  constructor() {
    this.load();
  }

  load(url = '/api/tasks.json'): void {
    this.state.set('loading');
    this.http.get<Task[]>(url).subscribe({
      next: (tasks) => {
        this.items.set(tasks);
        this.state.set('ready');
      },
      error: (error: HttpErrorResponse) => {
        this.problem.set(error.status === 0 ? 'Cannot reach the server.' : `The server answered with status ${error.status}.`);
        this.state.set('error');
      }
    });
  }

  byId(id: number): Task | undefined {
    return this.items().find((task) => task.id === id);
  }

  add(title: string): void {
    const id = Math.max(0, ...this.items().map((task) => task.id)) + 1;
    this.items.update((list) => [...list, { id, title, done: false }]);
  }

  toggle(id: number): void {
    this.items.update((list) => list.map((task) => (task.id === id ? { ...task, done: !task.done } : task)));
  }

  remove(id: number): void {
    this.items.update((list) => list.filter((task) => task.id !== id));
  }
}
```

**File: `src/styles.css`**

```css
:root {
  --color-text: #1f2937;
  --color-muted: #4b5563;
  --color-brand: #1d6fb8;
  --color-danger: #b42318;
  --color-border: #d1d5db;
  --color-surface: #ffffff;
  --radius: 0.375rem;
}

body {
  margin: 2rem;
  background: var(--color-surface);
  color: var(--color-text);
  font-family: system-ui, sans-serif;
  line-height: 1.5;
}

a {
  color: var(--color-brand);
}

button {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  min-height: 2.25rem;
  padding: 0.375rem 0.75rem;
  border: 1px solid var(--color-brand);
  border-radius: var(--radius);
  background: var(--color-surface);
  color: var(--color-brand);
  font: inherit;
  cursor: pointer;
  transition: background-color 0.15s;
}

button:hover:not(:disabled) {
  background: #e8f1fb;
}

button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

button.active {
  background: var(--color-brand);
  color: #ffffff;
}

:focus-visible {
  outline: 3px solid var(--color-brand);
  outline-offset: 2px;
}

.skip-link {
  position: absolute;
  top: 0.5rem;
  left: -999px;
  z-index: 10;
  padding: 0.5rem 1rem;
  background: var(--color-brand);
  color: #ffffff;
}

.skip-link:focus {
  left: 0.5rem;
}

.icon {
  display: inline-block;
  width: 1.125rem;
  height: 1.125rem;
  background-color: currentColor;
  -webkit-mask: var(--icon) center / contain no-repeat;
  mask: var(--icon) center / contain no-repeat;
}

.icon-plus {
  --icon: url('/icons/ui/plus.svg');
}

.icon-x {
  --icon: url('/icons/ui/x.svg');
}

.icon-refresh {
  --icon: url('/icons/arrows/refresh-cw.svg');
}

.icon-alert {
  --icon: url('/icons/ui/alert-triangle.svg');
}

@media (max-width: 30rem) {
  body {
    margin: 1rem;
  }
}

@media (prefers-reduced-motion: reduce) {
  * {
    transition: none !important;
    animation: none !important;
  }
}
```

</details>
