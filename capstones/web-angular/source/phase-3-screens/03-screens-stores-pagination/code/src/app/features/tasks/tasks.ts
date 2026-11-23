import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { combineLatest } from 'rxjs';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { TASK_STATUS } from '../../api/models/task-status-array';
import { TASK_PRIORITY } from '../../api/models/task-priority-array';
import { TaskPriority, TaskStatus } from '../../api/models';
import { Actions } from '../../core/actions';
import { Connectivity } from '../../core/connectivity';
import { Icon } from '../../shared/icon';
import { TasksStore, TaskFilter } from './tasks.store';
@Component({ selector: 'app-tasks', imports: [ReactiveFormsModule, RouterLink, Icon], changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<h1 tabindex="-1">Tasks</h1><p>{{ store.project()?.name }}</p>
    <details><summary><app-icon name="ui/filter" />Filters</summary><form [formGroup]="filters" (ngSubmit)="filterUrl()">
      <label for="task-search"><app-icon name="ui/search" />Title text</label><input id="task-search" formControlName="q" maxlength="100">
      <label for="filter-status">Status (multiple allowed)</label><select id="filter-status" multiple formControlName="status">@for (status of statuses; track status) { <option [value]="status">{{ status }}</option> }</select>
      <label for="filter-priority">Priority (multiple allowed)</label><select id="filter-priority" multiple formControlName="priority">@for (priority of priorities; track priority) { <option [value]="priority">{{ priority }}</option> }</select>
      <label for="filter-assignee">Assignee</label><select id="filter-assignee" formControlName="assigneeId"><option value="">Anyone</option>@for (member of store.members.state().items; track member.userId) { <option [value]="member.userId">{{ member.displayName }}</option> }</select>
      <label for="due-after">Due on or after</label><input id="due-after" type="date" formControlName="dueAfter">
      <label for="due-before">Due on or before</label><input id="due-before" type="date" formControlName="dueBefore">
      <label for="task-sort">Sort</label><select id="task-sort" formControlName="sort"><option value="-createdAt">Newest</option><option value="createdAt">Oldest</option><option value="dueDate">Due date</option></select><button>Apply filters</button>
    </form></details>
    <button (click)="viewUrl('list')" [attr.aria-pressed]="view === 'list'"><app-icon name="ui/list" />List</button>
    <button (click)="viewUrl('board')" [attr.aria-pressed]="view === 'board'"><app-icon name="ui/columns" />Board</button>
    <h2>Create task</h2><form [formGroup]="form" (ngSubmit)="create()">
      <label for="new-title">Title</label><input id="new-title" formControlName="title" required maxlength="200">
      <label for="new-description">Description</label><textarea id="new-description" formControlName="description" maxlength="10000"></textarea>
      <label for="new-priority">Priority</label><select id="new-priority" formControlName="priority">@for (priority of priorities; track priority) { <option [value]="priority">{{ priority }}</option> }</select>
      <label for="new-assignee">Assignee</label><select id="new-assignee" formControlName="assigneeId"><option value="">Unassigned</option>@for (member of store.members.state().items; track member.userId) { <option [value]="member.userId">{{ member.displayName }}</option> }</select>
      <label for="new-due"><app-icon name="time/calendar-days" />Due date</label><input id="new-due" type="date" formControlName="dueDate">
      <button [disabled]="form.invalid || !connection.online()"><app-icon name="ui/plus" />Create task (retry uses the same key)</button></form>
    <button [disabled]="!store.members.state().nextCursor" (click)="moreMembers()">Load more assignees</button>
    @if (view === 'board') { <div class="board">@for (status of statuses; track status) { <section><h2>{{ status }}</h2>
      @for (task of store.state().items; track task.id) { @if (task.status === status) { <article><a [routerLink]="['/tasks', task.id]">{{ task.title }}</a>
        <label [for]="'move-' + task.id">Move {{ task.title }} to</label><select [id]="'move-' + task.id" [value]="task.status" [disabled]="!connection.online()" (change)="move(task.id, $event)">
        @for (target of statuses; track target) { <option [value]="target">{{ target }}</option> }</select></article> } }
    </section>}</div> } @else { <ul>@for (task of store.state().items; track task.id) { <li><a [routerLink]="['/tasks', task.id]">{{ task.title }}</a> {{ task.status }} / {{ task.priority }}</li> }</ul> }
    @if (store.state().status === 'loading') { <p role="status">Loading tasks</p> }
    <button [disabled]="!store.state().nextCursor || store.state().status === 'loadingMore'" (click)="more()">Load more tasks</button>` })
export class Tasks {
  protected readonly store = inject(TasksStore);
  protected readonly connection = inject(Connectivity);
  private readonly actions = inject(Actions);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly fb = inject(FormBuilder).nonNullable;
  protected readonly statuses = TASK_STATUS;
  protected readonly priorities = TASK_PRIORITY;
  protected id = '';
  protected view = 'list';
  private query: TaskFilter = {};
  protected readonly filters = this.fb.group({ q: '', status: this.fb.control<TaskStatus[]>([]), priority: this.fb.control<TaskPriority[]>([]), assigneeId: '', dueAfter: '', dueBefore: '', sort: '-createdAt' });
  protected readonly form = this.fb.group({ title: ['', Validators.required], description: '', priority: this.fb.control<TaskPriority>('medium'), assigneeId: '', dueDate: '' });
  constructor() { combineLatest([this.route.paramMap, this.route.queryParamMap]).pipe(takeUntilDestroyed()).subscribe(([path, query]) => {
    this.id = path.get('projectId')!; this.view = query.get('view') === 'board' ? 'board' : 'list';
    const raw = { q: (query.get('q') ?? '').trim().slice(0, 100), status: query.getAll('status').filter((s): s is TaskStatus => TASK_STATUS.includes(s as TaskStatus)),
      priority: query.getAll('priority').filter((s): s is TaskPriority => TASK_PRIORITY.includes(s as TaskPriority)), assigneeId: query.get('assigneeId') ?? '', dueAfter: query.get('dueAfter') ?? '', dueBefore: query.get('dueBefore') ?? '', sort: query.get('sort') ?? '-createdAt' };
    this.filters.setValue(raw);
    this.query = { ...raw, q: raw.q || undefined, status: raw.status.length ? raw.status : undefined, priority: raw.priority.length ? raw.priority : undefined,
      assigneeId: raw.assigneeId || undefined, dueAfter: raw.dueAfter || undefined, dueBefore: raw.dueBefore || undefined, sort: raw.sort === 'dueDate' || raw.sort === 'createdAt' ? raw.sort : '-createdAt' };
    this.reload();
  }); }
  private reload(): void { void this.actions.run(() => this.store.loadTasks(this.id, this.query)); }
  protected filterUrl(): void { void this.router.navigate([], { relativeTo: this.route, queryParams: { ...this.filters.getRawValue(), view: this.view } }); }
  protected viewUrl(view: string): void { void this.router.navigate([], { relativeTo: this.route, queryParams: { view }, queryParamsHandling: 'merge' }); }
  protected async create(): Promise<void> { if (this.form.invalid) return; const body = this.form.getRawValue();
    if (await this.actions.run(() => this.store.create(this.id, { ...body, assigneeId: body.assigneeId || null, dueDate: body.dueDate || null }), true)) { this.form.reset(); this.reload(); }
  }
  protected async move(id: string, event: Event): Promise<void> { const status = (event.target as HTMLSelectElement).value as TaskStatus; if (await this.actions.run(() => this.store.move(id, status), true)) this.reload(); }
  protected more(): void { void this.actions.run(() => this.store.more()); }
  protected moreMembers(): void { void this.actions.run(() => this.store.members.more()); }
}
