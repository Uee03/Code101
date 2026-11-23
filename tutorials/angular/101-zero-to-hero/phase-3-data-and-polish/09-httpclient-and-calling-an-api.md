---
track: angular
level: 101
phase: 3
phase_name: data-and-polish
lesson: 09
title: "HttpClient and calling an API"
time: 70 min
prerequisites: [angular-101.2.08, web-101.3.11]
versions: { node: "26.13.1", angular: "22.3.0", typescript: "6.0.3", rxjs: "7.8.2" }
verified: not yet run
source: source/angular/101-zero-to-hero/phase-3-data-and-polish/09-httpclient-and-calling-an-api/
assets: []
---

# 09. HttpClient and calling an API

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- Switch on `HttpClient` with `provideHttpClient(withFetch())`.
- Load typed JSON with `http.get<T>()` and `subscribe`, and explain what an Observable is at this level.
- Show three states (loading, ready, error) in the page and a "Try again" button.
- Tell a network failure (status 0) from an HTTP error (status 404, 500).

## Recap
1. Where does shared state live, and how does a component get it? <details><summary>Answer</summary>In a service provided in the root injector; a component gets it with `inject(TaskStore)`.</details>
2. What does `providers` in `app.config.ts` do? <details><summary>Answer</summary>It lists the services and settings the root injector can hand out.</details>
3. In Web 101 lesson 11 you used `fetch`. Which two steps did you need to read JSON? <details><summary>Answer</summary>`await fetch(url)` and then `await response.json()`; also checking `response.ok`.</details>

## Why it matters
Ordering a pizza by phone has the same shape as calling an API: you ask, you wait (is it coming?), and then it either arrives, or the shop says "sorry, we are closed". Your page must handle all three moments. In Web 101 you did this with `fetch`. Angular's `HttpClient` does the same job with built-in typing, and later features (interceptors, testing, caching) hook into it.

## What you will build
The task store now loads its tasks from a JSON file served by the development server (`/api/tasks.json`) instead of a list in the code. The Tasks page shows "Loading tasks...", then the list; if loading fails, a message and a **Try again** button. A practice button loads from an address where nothing listens, so you can see the error state.

## Before you start
- Lesson 08 done. Time: about 70 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/angular/101-zero-to-hero/phase-3-data-and-polish/09-httpclient-and-calling-an-api/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- **Clean-up:** delete `src/app/task-data.ts`; nothing uses it any more. Stop and restart `npm start` after changing `app.config.ts` and adding files in `public/`, if the page does not pick them up.

## Steps

### Step 1. Create the "API": a JSON file
Files in the `public/` folder are copied to the root of the site unchanged (`angular.json` says so, lesson 01). So `public/api/tasks.json` will be served at the address `/api/tasks.json`. It stands in for a real server endpoint.

**File: `public/api/tasks.json`**
```json
[
  { "id": 1, "title": "Install Node", "done": true },
  { "id": 2, "title": "Create the app", "done": true },
  { "id": 3, "title": "Learn control flow", "done": false },
  { "id": 4, "title": "Call an API", "done": false }
]
```

### Step 2. Switch on HttpClient
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

`provideHttpClient(withFetch())` registers the `HttpClient` service and tells it to use the browser's `fetch` underneath (the same function you used in Web 101). Without this line, `inject(HttpClient)` fails.

### Step 3. Load the data in the store
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

New ideas, in order:
- `inject(HttpClient)` gets the HTTP service, like `inject(TaskStore)` in lesson 08.
- `LoadStatus` is a union of the three states. `state` is the writable signal; `status` is its read-only face for components. `problem` and `message` work the same way for the error text.
- The constructor calls `load()` once, so the data starts loading as soon as the store is first used.
- `this.http.get<Task[]>(url)` builds the request. The text in `<Task[]>` tells TypeScript what the JSON will be. **It is a promise to the compiler, not a check:** nothing verifies that the server really sends tasks. (Level 201 shows how a generated client reduces that risk.)
- The result of `get` is an **Observable**: think of it as an order slip. It describes the request, but **nothing is sent until you `subscribe`**. Subscribing gives it two callbacks: `next` runs with the data when the answer arrives, `error` runs if the request fails.
- In `error`, `error.status === 0` means the request never got an HTTP answer (server down, no network, wrong host). Any other number is the HTTP status code the server sent (404 not found, 500 server error).
- `load(url = '/api/tasks.json')` has a **default parameter**, so `store.load()` loads the real file and `store.load(someOtherUrl)` can try another address.

### Step 4. Show the three states
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

`brokenUrl` points at port 9 on your own computer, where nothing listens (and which browsers refuse to talk to), so the request fails without a HTTP answer.

**File: `src/app/pages/tasks/tasks.html`**
```html
<h1>Tasks</h1>

@switch (store.status()) {
  @case ('loading') {
    <p role="status">Loading tasks...</p>
  }
  @case ('error') {
    <div class="problem" role="alert">
      <p>{{ store.message() }}</p>
      <button type="button" (click)="store.load()">Try again</button>
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

`@switch` shows one of three blocks. `role="status"` (a polite announcement) is for the harmless "Loading..." text; `role="alert"` (announced at once) is for the error. The form and the list only appear in the `ready` state.

**File: `src/app/pages/tasks/tasks.css`**
```css
h1 {
  color: #1d6fb8;
}

.status {
  font-weight: 600;
}

button {
  margin-right: 0.5rem;
  padding: 0.375rem 0.75rem;
}

button.active {
  background: #1d6fb8;
  color: #ffffff;
}

.filters button {
  text-transform: capitalize;
}

.problem {
  padding: 0.75rem 1rem;
  border-left: 0.25rem solid #b42318;
  background: #fdecea;
}

.tasks {
  list-style: none;
  padding: 0;
}

.empty,
.hint {
  color: #4b5563;
}
```

### Step 5. Handle loading in the other pages
A visitor can open `/tasks/3` directly, before the data has arrived. Without a loading case the page would flash "Task not found".

**File: `src/app/pages/task-detail/task-detail.ts`**
```ts
import { Component, computed, inject, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TaskStore } from '../../task-store';

@Component({
  selector: 'app-task-detail-page',
  imports: [RouterLink],
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
    <p>Task number {{ found.id }}. Status: {{ found.done ? 'done' : 'to do' }}.</p>
  } @else {
    <h1>Task not found</h1>
    <p>There is no task with the number "{{ id() }}".</p>
  }
}
<p><a routerLink="/tasks">Back to the list</a></p>
```

**File: `src/app/pages/home/home.ts`**
```ts
import { Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { TaskStore } from '../../task-store';

@Component({
  selector: 'app-home',
  imports: [RouterLink],
  template: `
    <h1>Welcome</h1>
    @if (store.status() === 'ready') {
      <p>Open tasks: {{ store.remaining() }}. Go to the <a routerLink="/tasks">task list</a>.</p>
    } @else {
      <p>Loading your tasks...</p>
    }
  `
})
export class Home {
  protected readonly store = inject(TaskStore);
}
```

## Run it
Restart `npm start` if needed and open http://localhost:4200/tasks.

**Predict:** what appears for a split second when the page opens, and how many tasks are in the list afterwards?

Expected behaviour (described from the code, not yet seen in a browser):
1. A very short "Loading tasks..." and then the form, "2 tasks left." and **four** tasks (the file has a fourth task, "Call an API").
2. Press **Load from an address where nothing listens**: "Loading tasks..." and then a red box "Cannot reach the server." with **Try again**.
3. Press **Try again**: the list returns.
4. Open http://localhost:4200/tasks/4 directly (type it in the address bar): the page shows "Task number 4". Open the browser's developer tools, tab Network, and find the request for `tasks.json`.

## How it works
1. The store is created the first time anything injects it (here the navigation bar); its constructor starts the request.
2. `HttpClient` sends a GET request through `fetch`. When the response arrives, the `next` callback sets the signals, and every template that reads them redraws.
3. If the browser cannot get an answer, `error` runs with status 0. If the server answers 404 or 500, `error` runs with that status. A **successful** answer (status 200 to 299) goes to `next`.
4. After loading, the list lives in the store again, so adding, ticking and removing work as in lesson 08. They only change the list in memory; sending the changes back to a server needs `http.post`, `http.put` and `http.delete` and a server that accepts them (level 201 does that against a real API).

**Misconception:** "`http.get(...)` already sent the request." No: it only builds it. Forget `subscribe` (or an `async` pipe, lesson 11, or `toSignal`, level 201) and nothing happens.

**Same origin.** The page (`localhost:4200`) and the JSON file come from the same server, so the browser allows the request. A request to another address needs that server to allow your page with **CORS** headers (Web 101 lesson 11 and level 201).

## Try it
Starter file: `exercise/starter/src/app/task-store.ts`.
1. **Guided:** finish the two TODOs: remember when the tasks were last loaded (`lastLoaded`), then show "Loaded at HH:MM:SS" on the Tasks page using `store.lastLoaded()?.toLocaleTimeString()`.
2. **Change:** make a second file `public/api/tasks-empty.json` that contains `[]` and add a button that loads it. What do you see in the list?
3. **Stretch (optional):** make `load` ignore a second click while the first request is still running. Where do you check, and what do you show?

<details><summary>Solution for rung 1 (the store)</summary>

**File: `exercise/solution/src/app/task-store.ts`**
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
  private readonly loaded = signal<Date | null>(null);

  readonly tasks = this.items.asReadonly();
  readonly status = this.state.asReadonly();
  readonly message = this.problem.asReadonly();
  readonly lastLoaded = this.loaded.asReadonly();
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
        this.loaded.set(new Date());
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

On the page, add for example `@if (store.lastLoaded(); as time) { <p class="hint">Loaded at {{ time.toLocaleTimeString() }}</p> }` inside the `ready` case.

</details>

## Check yourself
1. What happens if you call `http.get(...)` and never subscribe? <details><summary>Answer</summary>No request is sent.</details>
2. What does `error.status === 0` mean? <details><summary>Answer</summary>The browser got no HTTP answer: the server is unreachable, offline, blocked, or the address is wrong.</details>
3. The type in `get<Task[]>` says the server sends tasks. Who checks that it does? <details><summary>Answer</summary>Nobody: it is only a promise to the compiler.</details>
4. Why does the detail page have a loading case? <details><summary>Answer</summary>A direct visit can render before the data arrives, which would wrongly show "Task not found".</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| Typical message: `NullInjectorError: No provider found for HttpClient` | `provideHttpClient(...)` is missing in `app.config.ts` | Add it to `providers` |
| Nothing loads and there is no error | No `subscribe` | Subscribe, or use `toSignal` (level 201) |
| The page shows the tasks from the old list | The browser still has the old build, or `task-data.ts` is still imported | Save, restart `npm start`, remove the import |
| Typical message in the console: JSON parse error such as `Unexpected token '<'` | The URL returned an HTML page (a wrong address gets `index.html`) | Check the address and the file under `public/api/` |
| 404 for `tasks.json` | The file is not in `public/api/` or `npm start` was not restarted after creating `public/api` | Move the file and restart |
| `Try again` does nothing visible | The request failed again quickly | Check the terminal and the Network tab |

## Best practice
Always model **loading, success and error** as explicit states, and never leave a request without an error path. Source: Angular, HTTP guide https://angular.dev/guide/http

## Going further
- Making requests: https://angular.dev/guide/http/making-requests
- `httpResource` (a signal-based way to load data, stable in Angular 22): https://angular.dev/guide/http/http-resource
- Level 201 lessons 04 and 05 cover interceptors, error handling and a typed client generated from OpenAPI.

## Summary
- You enabled `HttpClient` and loaded typed JSON with `get` and `subscribe`.
- You modelled loading, ready and error states and a retry.
- You separated "no answer" (status 0) from "an HTTP error" (status 404, 500).

## Next lesson
10. Styling and accessibility: a shared look, focus styles, a skip link and icons.

<details>
<summary>Files that did not change in this lesson (listed so this page is complete)</summary>

**File: `src/app/app-title.ts`**

```ts
import { InjectionToken } from '@angular/core';

export const APP_TITLE = new InjectionToken<string>('APP_TITLE');
```

**File: `src/app/app.css`**

```css
.site-header {
  display: flex;
  align-items: center;
  gap: 1.5rem;
  max-width: 40rem;
  margin: 0 auto 1.5rem;
  padding-bottom: 0.75rem;
  border-bottom: 1px solid #d1d5db;
}

.brand {
  color: #1d6fb8;
  font-size: 1.25rem;
  font-weight: 700;
  text-decoration: none;
}

nav {
  display: flex;
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
```

**File: `src/app/app.html`**

```html
<header class="site-header">
  <a class="brand" routerLink="/">{{ appTitle }}</a>
  <nav aria-label="Main">
    <a routerLink="/" routerLinkActive="active" ariaCurrentWhenActive="page" [routerLinkActiveOptions]="{ exact: true }">Home</a>
    <a routerLink="/tasks" routerLinkActive="active" ariaCurrentWhenActive="page">Tasks ({{ store.remaining() }} open)</a>
    <a routerLink="/about" routerLinkActive="active" ariaCurrentWhenActive="page">About</a>
  </nav>
</header>

<main class="page">
  <router-outlet />
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
import { Component, inject } from '@angular/core';
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
  margin-right: 0.5rem;
  padding: 0.375rem;
}

.error {
  margin: 0.25rem 0 0;
  color: #b42318;
}
```

**File: `src/app/new-task-reactive/new-task-reactive.html`**

```html
<form [formGroup]="form" (ngSubmit)="submit()" novalidate>
  <label for="title-reactive">New task (reactive form)</label>
  <input
    id="title-reactive"
    type="text"
    formControlName="title"
    [attr.aria-invalid]="title.invalid && title.touched"
    aria-describedby="title-reactive-error">
  <button type="submit">Add</button>
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

**File: `src/app/task-item/task-item.css`**

```css
:host {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.5rem 0;
  border-bottom: 1px solid #d1d5db;
}

:host(.done) .title {
  color: #4b5563;
  text-decoration: line-through;
}

.remove {
  padding: 0.25rem 0.625rem;
}
```

**File: `src/app/task-item/task-item.html`**

```html
<span class="title">
  <input type="checkbox" [checked]="task().done" [attr.aria-label]="'Done: ' + task().title" (change)="toggle()">
  {{ position() }}. <a [routerLink]="['/tasks', task().id]">{{ task().title }}</a>
</span>
<button type="button" class="remove" [attr.aria-label]="'Remove ' + task().title" (click)="remove()">Remove</button>
```

**File: `src/app/task-item/task-item.ts`**

```ts
import { Component, input, output } from '@angular/core';
import { RouterLink } from '@angular/router';
import { Task } from '../task';

@Component({
  selector: 'li[app-task-item]',
  imports: [RouterLink],
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

**File: `src/app/task.ts`**

```ts
export type Filter = 'all' | 'todo' | 'done';

export interface Task {
  id: number;
  title: string;
  done: boolean;
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
