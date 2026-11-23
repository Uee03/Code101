---
track: angular
level: 101
phase: 3
phase_name: data-and-polish
lesson: 10
title: "Styling and accessibility"
time: 70 min
prerequisites: [angular-101.3.09, web-101.1.04, web-101.2.07]
versions: { node: "26.13.1", angular: "22.3.0", typescript: "6.0.3" }
verified: not yet run
source: source/angular/101-zero-to-hero/phase-3-data-and-polish/10-styling-and-accessibility/
assets: [ui/plus, ui/x, ui/alert-triangle, arrows/refresh-cw]
---

# 10. Styling and accessibility

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- Share colours and sizes through CSS custom properties in the global stylesheet, and style a component with scoped CSS and `:host`.
- Add visible keyboard focus, a skip link and focus management after navigation.
- Use SVG icons from files with a CSS mask, hide decorative icons from assistive technology and name icon-only buttons.
- Check the basics yourself: keyboard-only use, text contrast and touch target size.

## Recap
1. Why does a component's CSS not affect other components? <details><summary>Answer</summary>Angular scopes component styles to that component's elements (emulated encapsulation).</details>
2. Which role announces a message immediately, `status` or `alert`? <details><summary>Answer</summary>`alert` announces at once; `status` is polite.</details>
3. How is a CSS custom property defined and used (Web 101)? <details><summary>Answer</summary>`--name: value;` on `:root`, and `var(--name)` where you want it.</details>

## Why it matters
A building needs a ramp next to the stairs, clear signs and a door that opens for everyone: you do not add them at the end, they decide whether people can enter at all. Many people use assistive technology, a keyboard instead of a mouse, a zoomed screen or a screen reader, and many others are simply on a bright phone outdoors. Good styling and basic accessibility (often written a11y) is how your app stays usable for all of them, and it is much cheaper to build in now.

## What you will build
The task app with a shared look (colour tokens, buttons, focus ring), small icons (plus, cross, refresh, warning), a **Skip to content** link, focus that moves to the page content after you navigate, and a layout that wraps on a narrow phone screen.

## Before you start
- Lesson 09 done. Time: about 70 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/angular/101-zero-to-hero/phase-3-data-and-polish/10-styling-and-accessibility/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Icons come from the course's CC0 art library (`assets/art/icons`), which is free to use without attribution. The four SVG files are shown below, so you can type them in.

## Steps

### Step 1. Put the icons in `public`
Create the folders `public/icons/ui` and `public/icons/arrows` and add four files. Each one is a 24 by 24 drawing made of lines, with `stroke="currentColor"`.

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

**File: `public/icons/ui/alert-triangle.svg`**
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" role="img" aria-label="Alert Triangle">
  <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/>
</svg>
```

**File: `public/icons/arrows/refresh-cw.svg`**
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" role="img" aria-label="Refresh Cw">
  <polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/>
</svg>
```

(`role="img"` and `aria-label` inside the file matter only when the file is used directly as an image. We will use the files as a CSS mask, which ignores them.)

### Step 2. Write the global stylesheet
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

What is in it, and why:
- **Tokens.** `:root { --color-brand: ... }` names the colours once. Change one value and the whole app changes. Component CSS files read them with `var(--color-brand)`; custom properties pass through component scoping.
- **Contrast.** Text must be readable: WCAG asks for a contrast ratio of at least 4.5 to 1 for normal text. By the WCAG formula the brand blue on white is about 5.2 to 1, the muted grey about 7.6 to 1 and the danger red about 6.6 to 1 (calculated, not measured: confirm any colour you add with a contrast checker).
- **Buttons.** One rule styles every button; `min-height: 2.25rem` (36 px) keeps targets large enough to hit (WCAG 2.2 asks for at least 24 by 24 px). `:disabled` shows a lower opacity and a "not allowed" cursor.
- **Focus.** `:focus-visible` draws a thick outline when the focus came from the keyboard. **Never remove the outline without a replacement**: a keyboard user would not see where they are.
- **Skip link.** It sits off-screen until it receives focus; it is the first thing a keyboard user reaches, so they can jump over the navigation.
- **Icons.** `.icon` is a small square coloured with `currentColor` (the text colour of its parent) and cut into the SVG shape by `mask`. So an icon follows the text colour, hover colour and error colour for free. `-webkit-mask` is for older Safari versions.
- **Small screens and motion.** The `max-width` query reduces the page margin; `prefers-reduced-motion: reduce` switches transitions off for people who asked their system for less movement.

### Step 3. The shell: skip link and focus after navigation
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

When the router shows a new page in a single-page app, the browser does not "load a page", so a screen-reader user gets no hint that something changed and keyboard focus stays on the old link. Fix: after each navigation we move focus to the `<main>` element.
- `viewChild.required<ElementRef<HTMLElement>>('main')` reads the element marked `#main` in the template (a **view query**; it returns a signal).
- `pageChanged()` is called when the router outlet activates a page. We ignore the first call (the very first page load) so the skip link stays first in the tab order.

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

- `<a class="skip-link" href="#main">` jumps to the element with `id="main"`.
- `<main id="main" #main tabindex="-1">`: `main` is a **landmark** (screen readers list it). `tabindex="-1"` makes it focusable by code but not part of the tab order.
- `(activate)="pageChanged()"` listens to the router outlet's `activate` event.

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

`flex-wrap: wrap` lets the header and navigation fold onto a second line on narrow screens. `.page:focus { outline: none; }` hides the ring on the content container only, because it is not a control and the user did not ask to "see" it; every control keeps its ring.

### Step 4. Task row, form and page
**File: `src/app/task-item/task-item.html`**
```html
<span class="title">
  <input type="checkbox" [checked]="task().done" [attr.aria-label]="'Done: ' + task().title" (change)="toggle()">
  {{ position() }}. <a [routerLink]="['/tasks', task().id]">{{ task().title }}</a>
</span>
<button type="button" class="remove" [attr.aria-label]="'Remove ' + task().title" (click)="remove()">
  <span class="icon icon-x" aria-hidden="true"></span>
</button>
```

The Remove button contains only an icon, so its name must come from `aria-label` ("Remove Install Node"). The `<span class="icon icon-x" aria-hidden="true">` is **decorative**: `aria-hidden="true"` hides it from screen readers so they do not announce an empty image.

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

.remove {
  min-width: 2.25rem;
  justify-content: center;
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

Here the icon sits next to the visible word "Add", so the text is the name and the icon is decoration.

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

Because the global stylesheet now styles buttons and tokens, the button rules left this file.

## Run it
Save everything, restart `npm start` if the new icon files are not found, and open http://localhost:4200/.

**Predict:** you press the **Tab** key once on a fresh page load. What do you expect to be focused, and what should the page show?

Expected behaviour (described from the code, not yet seen in a browser):
1. First **Tab**: the "Skip to content" link slides into view in the top left corner with a blue background. Press **Enter**: focus jumps to the main content.
2. Keep pressing **Tab**: the focus ring (a blue outline) is visible on every link, button and field. The checkbox is larger.
3. Click **Tasks** with the keyboard (Enter): the page changes and focus moves to the content area, so the next Tab goes into the page, not back to the navigation.
4. Remove buttons show a cross; the Add button a plus; the error state (use the practice button) shows a warning triangle and a refresh icon. All icons take the colour of their text.
5. Make the browser window about 350 pixels wide (or use the device toolbar of the developer tools): the header wraps instead of overflowing.

**Your own 3-minute accessibility check:** (a) do the whole task with only Tab, Shift+Tab, Enter and Space, without touching the mouse; (b) zoom the page to 200 percent and see whether anything is cut off; (c) look at every icon-only button and ask "what would a screen reader say?".

## How it works
1. `styles.css` is loaded once for the whole app (it is listed in `angular.json`). Custom properties defined on `:root` are inherited everywhere, including inside component-scoped CSS, so tokens are the clean way to share a design.
2. Component CSS is still scoped. The global classes `.icon` and `.skip-link` work inside components because they are defined globally.
3. A mask turns a file into a shape: the browser draws the element's `background-color` only where the SVG has ink. That is why one SVG gives any colour.
4. Accessibility is mostly **using the right element** (`button`, `a`, `label`, `main`, `nav`, headings), giving things **names**, keeping **focus** visible and logical, and not relying on colour alone. ARIA attributes (`aria-label`, `aria-pressed`, `aria-current`) fill gaps; the first rule of ARIA is to prefer a real HTML element when one exists.

**Misconception:** "accessibility is for blind users." It covers motor (keyboard, tremor), low vision (zoom, contrast), hearing (captions), cognitive (clear text, no time limits) and situational needs (sunlight, one hand).

## Try it
Starter file: `exercise/starter/src/app/task-item/task-item.css`.
1. **Guided:** complete the two TODO rules: a hover background for the row and a `:focus-within` outline.
2. **Change:** add a dark colour scheme: in `styles.css` add `@media (prefers-color-scheme: dark)` redefining the tokens (`--color-text`, `--color-surface`, `--color-muted`, `--color-border`). Predict what must change besides the tokens (hint: look for hard-coded colours).
3. **Stretch (optional):** add a visible "Loading" skeleton or spinner for the loading state, respecting reduced motion. Decide whether it needs a text alternative.

<details><summary>Solution for rung 1</summary>

**File: `exercise/solution/src/app/task-item/task-item.css`**
```css
:host {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.5rem 0;
  border-bottom: 1px solid var(--color-border);
}

:host(:hover) {
  background: #f3f4f6;
}

:host(:focus-within) {
  outline: 2px solid var(--color-brand);
  outline-offset: -2px;
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

.remove {
  min-width: 2.25rem;
  justify-content: center;
}
```

</details>

## Check yourself
1. Why is `aria-label` needed on the Remove button? <details><summary>Answer</summary>It contains only an icon, so without a label a screen reader would have no name to announce.</details>
2. Why do we hide the icon with `aria-hidden="true"` next to the visible word "Add"? <details><summary>Answer</summary>The word already names the button, and the icon is decoration.</details>
3. What happens for a keyboard user if you write `outline: none` on all buttons with no replacement? <details><summary>Answer</summary>They cannot see which control has focus.</details>
4. Predict: after you follow a link with the keyboard, where is focus, and why did we add code for that? <details><summary>Answer</summary>On the `<main>` element: the router changes the page without a page load, so focus would otherwise stay on the old link.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| Icons do not appear | The path in `url('/icons/...')` does not match the file under `public/icons`, or `npm start` was not restarted | Check the folders and restart |
| Icons are black or the wrong colour | `background-color: currentColor` is missing or the mask is not applied | Compare with the `.icon` rule |
| The skip link is always visible | `left: -999px` is missing | Restore the rule |
| Typical message: `Cannot find name 'viewChild'` (or `ElementRef`) | The import from `@angular/core` is missing | Add the names to the import line |
| Focus jumps to the content on first load | The first-call guard in `pageChanged()` was removed | Restore `firstPage` |
| Tokens do not apply in a component | A typo in the name, or `:root` is missing | Names are case sensitive: `--color-brand` |

## Best practice
Use native elements first, name every control, keep focus visible, and test with the keyboard before every release. Source: Angular, Accessibility https://angular.dev/best-practices/a11y and W3C WCAG 2.2 quick reference https://www.w3.org/WAI/WCAG22/quickref/

## Going further
- WCAG 2.2 overview: https://www.w3.org/WAI/standards-guidelines/wcag/
- Angular CDK `a11y` (focus trap, live announcer), used in larger apps: https://material.angular.dev/cdk/a11y/overview
- Level 201 lesson 09 and the Angular web capstone deepen focus, live regions and a WCAG checklist.

## Summary
- You shared a design through CSS tokens and a global stylesheet.
- You added visible focus, a skip link and focus after navigation.
- You used SVG files as masked icons, hid decoration and named icon-only buttons.

## Next lesson
11. Pipes and lifecycle basics: format dates and text in the template and run code when a component starts and stops.

<details>
<summary>Files that did not change in this lesson (listed so this page is complete)</summary>

**File: `public/api/tasks.json`**

```json
[
  { "id": 1, "title": "Install Node", "done": true },
  { "id": 2, "title": "Create the app", "done": true },
  { "id": 3, "title": "Learn control flow", "done": false },
  { "id": 4, "title": "Call an API", "done": false }
]
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

**File: `src/app/task.ts`**

```ts
export type Filter = 'all' | 'todo' | 'done';

export interface Task {
  id: number;
  title: string;
  done: boolean;
}
```

</details>
