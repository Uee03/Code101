---
track: angular
level: 101
phase: 2
phase_name: building
lesson: 06
title: "Forms: template-driven first, then a reactive introduction"
time: 75 min
prerequisites: [angular-101.2.05, web-101.1.03]
versions: { node: "26.13.1", angular: "22.3.0", typescript: "6.0.3" }
verified: not yet run
source: source/angular/101-zero-to-hero/phase-2-building/06-forms-template-driven-then-reactive/
assets: []
---

# 06. Forms: template-driven first, then a reactive introduction

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- Build a form with `FormsModule`: `ngModel`, `ngForm`, `ngSubmit` and the `required` and `minlength` rules.
- Show an error message only after the user has touched the field or tried to submit.
- Build the same form with `ReactiveFormsModule`: `FormBuilder`, `FormGroup`, `Validators`, `formControlName`.
- Choose between the two styles and say what each is good at.

## Recap
1. How does a child component tell its parent that something happened? <details><summary>Answer</summary>With an `output()` and `.emit(value)`; the parent listens with `(name)="handler($event)"`.</details>
2. What does a `<label for="x">` do for the input with `id="x"`? <details><summary>Answer</summary>It gives the input its accessible name and makes a click on the text focus the input (Web 101 lesson 03).</details>
3. Why must the parent create a new array when adding a task? <details><summary>Answer</summary>A signal only notices a different value, so you copy the list and add to the copy.</details>

## Why it matters
A paper form has boxes, rules ("use block letters", "required") and a person at the desk who rejects an unfinished form. A web form needs the same three things: **fields** that hold values, **rules** that check them, and **messages** that tell people what to fix. Forms are how users give your app data, so doing them well (and accessibly) is worth two styles of tooling.

## What you will build
The task list from lesson 05 with two forms above it. Both add a task. One is **template-driven** (the rules are attributes in the HTML), one is **reactive** (the rules are objects in the class). A real app would pick one; showing both lets you compare them side by side.

| | Template-driven | Reactive |
|---|---|---|
| Where the rules live | In the HTML (`required`, `minlength`) | In the class (`Validators`) |
| Good for | Small, simple forms | Larger forms, dynamic fields, testing logic without HTML |
| Directives to import | `FormsModule` | `ReactiveFormsModule` |
| Model | `ngModel` | `FormControl` and `FormGroup` objects |

## Before you start
- Lesson 05 done and `npm start` running. Time: about 75 minutes (two sittings are fine: break after Step 3).
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/angular/101-zero-to-hero/phase-2-building/06-forms-template-driven-then-reactive/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- `@angular/forms` is already in `package.json` from lesson 01, so there is nothing to install.

## Steps

### Step 1. The template-driven component: class
Make the folder `src/app/new-task-template`.

**File: `src/app/new-task-template/new-task-template.ts`**
```ts
import { Component, output, signal } from '@angular/core';
import { FormsModule, NgForm } from '@angular/forms';

@Component({
  selector: 'app-new-task-template',
  imports: [FormsModule],
  templateUrl: './new-task-template.html',
  styleUrl: './new-task-template.css'
})
export class NewTaskTemplate {
  readonly added = output<string>();
  protected readonly title = signal('');

  protected submit(form: NgForm): void {
    const value = this.title().trim();
    if (form.invalid || value === '') {
      return;
    }
    this.added.emit(value);
    form.resetForm({ title: '' });
  }
}
```

- `imports: [FormsModule]` makes `ngModel`, `ngForm` and friends available in this template.
- `title = signal('')` holds the text in the box.
- `added = output<string>()` reports the new title to the parent (lesson 05).
- `submit(form: NgForm)` receives the form object (from `#form="ngForm"` in the template). It trims the text, stops when the form is invalid or empty, emits the title and resets the form. We check `value === ''` too, because a title of only spaces passes `required` and `minlength`.
- `form.resetForm({ title: '' })` clears the box **and** the touched/submitted state, so the error message does not flash on the next field.

### Step 2. The template-driven component: template
**File: `src/app/new-task-template/new-task-template.html`**
```html
<form #form="ngForm" (ngSubmit)="submit(form)" novalidate>
  <label for="title-template">New task (template-driven form)</label>
  <input
    id="title-template"
    name="title"
    type="text"
    required
    minlength="3"
    [(ngModel)]="title"
    #field="ngModel"
    [attr.aria-invalid]="field.invalid && (field.touched || form.submitted)"
    aria-describedby="title-template-error">
  <button type="submit">Add</button>
  @if (field.invalid && (field.touched || form.submitted)) {
    <p id="title-template-error" class="error" role="alert">
      @if (field.errors?.['required']) {
        Enter a title.
      } @else {
        Use at least 3 characters.
      }
    </p>
  }
</form>
```

Piece by piece:
- `#form="ngForm"`: Angular attaches an `NgForm` object to every `<form>`; this gives it the name `form`. It tracks the whole form (valid, submitted).
- `(ngSubmit)="submit(form)"` runs when the form is submitted (Enter key or the **Add** button). `novalidate` turns off the browser's own pop-up messages so ours are the only ones.
- `name="title"` is **required** for `ngModel` inside a form: it is the control's key.
- `required` and `minlength="3"` are validation rules written as plain attributes.
- `[(ngModel)]="title"` is **two-way binding**, the banana-in-a-box syntax: `[ ]` sends the value from the signal to the box, `( )` sends typing back to the signal. It works with a signal directly.
- `#field="ngModel"` gives the control's state a name: `field.invalid`, `field.touched` (the user has left the box), `field.errors`.
- The error block shows only when the field is invalid **and** (touched or the form was submitted), so a fresh form is not covered in red. `role="alert"` makes screen readers announce it when it appears. `aria-invalid` and `aria-describedby` tie the message to the field.
- `field.errors?.['required']` reads the `required` key if `errors` exists; `?.` stops a crash when `errors` is `null`.

**File: `src/app/new-task-template/new-task-template.css`**
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

### Step 3. The reactive component
Make the folder `src/app/new-task-reactive`. In a reactive form you build the model in the class and the template only connects to it.

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

- `inject(NonNullableFormBuilder)` asks Angular for a helper that builds controls (lesson 08 explains `inject`). The non-nullable version makes `reset()` go back to `''` instead of `null`, so the value type stays `string`.
- `fb.group({ title: ['', [rules]] })` makes a **FormGroup** with one **FormControl** named `title`: the first array item is the start value, the second the list of validators.
- `Validators.required` and `Validators.minLength(3)` are the same two rules as in the other form, now written in TypeScript.
- `this.form.controls.title` is a typed reference to that control, so the template can say `title.invalid`.
- `markAllAsTouched()` makes every error show, which is what we want after a failed submit.

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

`[formGroup]="form"` connects the `<form>` to the group; `formControlName="title"` connects the input to the control of that name. There is no `ngModel` and no `name` attribute. `title.hasError('required')` asks whether a rule failed.

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

### Step 4. Use both forms in the app
**File: `src/app/app.ts`**
```ts
import { Component, computed, signal } from '@angular/core';
import { NewTaskReactive } from './new-task-reactive/new-task-reactive';
import { NewTaskTemplate } from './new-task-template/new-task-template';
import { TaskItem } from './task-item/task-item';
import { Filter, Task } from './task';

@Component({
  selector: 'app-root',
  imports: [NewTaskReactive, NewTaskTemplate, TaskItem],
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

  protected add(title: string): void {
    const id = Math.max(0, ...this.tasks().map((task) => task.id)) + 1;
    this.tasks.update((list) => [...list, { id, title, done: false }]);
  }

  protected toggle(id: number): void {
    this.tasks.update((list) => list.map((task) => (task.id === id ? { ...task, done: !task.done } : task)));
  }

  protected remove(id: number): void {
    this.tasks.update((list) => list.filter((task) => task.id !== id));
  }

  protected setFilter(value: Filter): void {
    this.filter.set(value);
  }
}
```

New: the two imports, the `add(title)` method (the next id is the largest existing id plus one, so removing a task never reuses an id) and the extra items in `imports`.

**File: `src/app/app.html`**
```html
<main class="page">
  <h1>{{ title }}</h1>

  <p class="hint">Two forms do the same job so that you can compare them. A real app would keep one.</p>
  <app-new-task-template (added)="add($event)" />
  <app-new-task-reactive (added)="add($event)" />

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
      <li app-task-item [task]="task" [position]="i + 1" (toggled)="toggle($event)" (removed)="remove($event)"></li>
    } @empty {
      <li class="empty">No tasks in this view.</li>
    }
  </ul>
</main>
```

`(added)="add($event)"` is the output from lesson 05, now used with two different child components.

## Run it
Save everything and open http://localhost:4200/.

**Predict:** you press **Add** on the first (empty) form. Which message appears, and does the second form change?

Expected behaviour (described from the code, not yet seen in a browser):
1. Press **Add** with the template-driven box empty: the message "Enter a title." appears in red under it. The reactive form is untouched.
2. Type `ab` and press Add: "Use at least 3 characters.".
3. Type `Write notes` and press Add: the task appears at the end of the list as number 4, the box empties and no message shows.
4. Do the same in the reactive form: it behaves the same, but its error appears once the field is touched or you press Add.

## How it works
1. In the template-driven form Angular builds the form model **from the template**: each `ngModel` with a `name` becomes a control in the `NgForm`.
2. In the reactive form **you** build the model (`FormGroup`) in the class and the template binds to it. The model exists before the HTML is drawn, which is easier to reason about and to test.
3. Both stop invalid submissions, show messages from the control state, and report the result through the same `added` output.
4. **Touched, dirty, valid** are separate facts: *touched* means the user left the field, *dirty* means the value changed, *invalid* means a rule fails. Messages usually need *invalid and touched*.

**Misconception:** "the browser already validates, so I do not need this." Browser validation is a helpful first layer, but your messages, accessibility wiring and rules are yours; and the server must validate again because anyone can skip the browser.

## Try it
Starter files are in `exercise/starter/src/app/new-task-reactive/`.
1. **Guided:** add `Validators.maxLength(40)` and a matching message (TODOs 1 and 2). Predict the result of typing 41 characters.
2. **Change:** add a `maxlength="40"` rule and message to the template-driven form as well, and compare how much code each form needed.
3. **Stretch (optional):** add a second field `priority` (a `<select>` with `normal` and `high`) to one form and emit an object `{ title, priority }` instead of a string. Which parts of the app must change?

<details><summary>Solution for rung 1</summary>

**File: `exercise/solution/src/app/new-task-reactive/new-task-reactive.ts`**
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
    title: ['', [Validators.required, Validators.minLength(3), Validators.maxLength(40)]]
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

**File: `exercise/solution/src/app/new-task-reactive/new-task-reactive.html`**
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
      } @else if (title.hasError('minlength')) {
        Use at least 3 characters.
      } @else if (title.hasError('maxlength')) {
        Use at most 40 characters.
      }
    </p>
  }
</form>
```

</details>

## Check yourself
1. Which module do you import for `ngModel`, and which for `formControlName`? <details><summary>Answer</summary>`FormsModule` for `ngModel`; `ReactiveFormsModule` for `formControlName` and `[formGroup]`.</details>
2. Why does the error message wait for `touched`? <details><summary>Answer</summary>So an untouched, empty form is not full of errors before the user has had a chance to type.</details>
3. A title of three spaces: does it pass `required` and `minlength(3)`? What does the code do about it? <details><summary>Answer</summary>Yes, both pass; the submit method trims the value and refuses an empty result.</details>
4. The template-driven form never adds the task and the console complains about a missing control name. What is missing? <details><summary>Answer</summary>The `name` attribute on the input with `ngModel` inside the form.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| Typical message: `Can't bind to 'ngModel' since it isn't a known property of 'input'` | `FormsModule` is not in the component's `imports` | Add it |
| Typical message: `Can't bind to 'formGroup' since it isn't a known property of 'form'` | `ReactiveFormsModule` is not imported | Add it |
| Typical message: `If ngModel is used within a form tag, either the name attribute must be set or the form control must be defined as 'standalone'` | The input has no `name` | Add `name="title"` |
| Typical message: `Cannot find control with name: 'titel'` | `formControlName` differs from the group key | Use the same spelling |
| The page reloads on submit | The `<form>` is not handled by Angular (a missing import) | Check the imports above |
| Error text shows immediately on load | The condition does not check `touched` or `submitted` | Use `invalid && touched` |

## Best practice
Validate in the browser to help the user and again on the server to protect the data; always connect the message to the field with `aria-describedby`. Source: Angular, Forms overview https://angular.dev/guide/forms and W3C WAI Forms tutorial https://www.w3.org/WAI/tutorials/forms/

## Going further
- Reactive forms: https://angular.dev/guide/forms/reactive-forms
- Template-driven forms: https://angular.dev/guide/forms/template-driven-forms
- Signal Forms (stable in Angular 22, a third style that this track does not use): https://angular.dev/guide/forms/signals/overview
- Level 201 lesson 07 covers reactive forms with custom and cross-field validation.

## Summary
- You built a template-driven form with `ngModel`, `ngForm` and attribute rules.
- You built a reactive form with `FormBuilder`, `Validators` and `formControlName`.
- You showed errors only when useful and tied them to the field for assistive technology.

## Next lesson
07. Routing: give the app several pages and links between them.

<details>
<summary>Files that did not change in this lesson (listed so this page is complete)</summary>

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

.empty,
.hint {
  color: #4b5563;
}
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

:host(.done) label {
  color: #4b5563;
  text-decoration: line-through;
}

.remove {
  padding: 0.25rem 0.625rem;
}
```

**File: `src/app/task-item/task-item.html`**

```html
<label>
  <input type="checkbox" [checked]="task().done" (change)="toggle()">
  {{ position() }}. {{ task().title }}
</label>
<button type="button" class="remove" [attr.aria-label]="'Remove ' + task().title" (click)="remove()">Remove</button>
```

**File: `src/app/task-item/task-item.ts`**

```ts
import { Component, input, output } from '@angular/core';
import { Task } from '../task';

@Component({
  selector: 'li[app-task-item]',
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
