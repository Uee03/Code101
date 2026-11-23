import { ChangeDetectionStrategy, Component, inject, viewChild } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { TaskPriority, TaskStatus, TaskUpdate } from '../../api/models';
import { TASK_PRIORITY } from '../../api/models/task-priority-array';
import { TASK_STATUS } from '../../api/models/task-status-array';
import { AuthService } from '../../auth/auth.service';
import { Actions } from '../../core/actions';
import { Connectivity } from '../../core/connectivity';
import { ConfirmDialog } from '../../shared/confirm-dialog';
import { Icon } from '../../shared/icon';
import { TaskDetailStore } from './task-detail.store';
@Component({ selector: 'app-task-detail', imports: [ReactiveFormsModule, RouterLink, ConfirmDialog, Icon], changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<h1 tabindex="-1">Task detail</h1>@if (store.task(); as entry) {
    <h2>{{ entry.value.title }}</h2><p>{{ entry.value.description }}</p><p>{{ entry.value.status }} / {{ entry.value.priority }}</p>
    <p>Completed at: {{ date(entry.value.completedAt) }}</p><a [routerLink]="['/projects', entry.value.projectId]">Back to Tasks</a>
    <form [formGroup]="form" (ngSubmit)="save()">
      <label for="edit-title">Title</label><input id="edit-title" formControlName="title" required maxlength="200">
      <label for="edit-description">Description</label><textarea id="edit-description" formControlName="description" maxlength="10000"></textarea>
      <label for="edit-status">Status</label><select id="edit-status" formControlName="status">@for (status of statuses; track status) { <option [value]="status">{{ status }}</option> }</select>
      <label for="edit-priority">Priority</label><select id="edit-priority" formControlName="priority">@for (priority of priorities; track priority) { <option [value]="priority">{{ priority }}</option> }</select>
      <label for="edit-due">Due date (empty clears it)</label><input id="edit-due" type="date" formControlName="dueDate">
      <button [disabled]="form.invalid || store.saving() || !connection.online()">Save changed fields</button></form>
    <button [disabled]="!connection.online() || store.saving() || entry.value.status === 'done'" (click)="complete()"><app-icon name="ui/check-circle" />Complete task</button>
    @if (auth.isLead(store.teamId())) {
      <form [formGroup]="assignment" (ngSubmit)="reassign()"><label for="reassign">Assignee</label><select id="reassign" formControlName="assigneeId"><option value="">Unassigned</option>
        @for (member of store.members.state().items; track member.userId) { <option [value]="member.userId">{{ member.displayName }}</option> }</select>
        <button [disabled]="!connection.online()">Reassign task</button></form><button [disabled]="!store.members.state().nextCursor" (click)="moreMembers()">Load more assignees</button>
      <button [disabled]="!connection.online()" (click)="remove()">Delete task</button>
    }
    <h2>Comments</h2><ol>@for (comment of store.comments.state().items; track comment.id) {
      <li><p>{{ comment.body }}</p><p>By {{ comment.author.displayName }} at {{ date(comment.createdAt) }}</p>
      @if (comment.author.id === auth.user()?.id || auth.isLead(store.teamId())) { <button [disabled]="!connection.online()" (click)="removeComment(comment.id)">Delete comment</button> }</li>
    }</ol><button [disabled]="!store.comments.state().nextCursor" (click)="moreComments()">Load more comments</button>
    <form [formGroup]="commentForm" (ngSubmit)="comment()"><label for="comment">New comment</label><textarea id="comment" formControlName="body" required maxlength="2000"></textarea>
      <button [disabled]="commentForm.invalid || !connection.online()">Add comment</button></form>
  }<app-confirm-dialog />` })
export class TaskDetail {
  protected readonly store = inject(TaskDetailStore);
  protected readonly auth = inject(AuthService);
  protected readonly connection = inject(Connectivity);
  private readonly actions = inject(Actions);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);
  private readonly confirm = viewChild.required(ConfirmDialog);
  private readonly fb = inject(FormBuilder).nonNullable;
  protected readonly statuses = TASK_STATUS;
  protected readonly priorities = TASK_PRIORITY;
  protected readonly form = this.fb.group({ title: ['', Validators.required], description: '', status: this.fb.control<TaskStatus>('todo'), priority: this.fb.control<TaskPriority>('medium'), dueDate: '' });
  protected readonly assignment = this.fb.group({ assigneeId: '' });
  protected readonly commentForm = this.fb.group({ body: ['', Validators.required] });
  constructor() { this.route.paramMap.pipe(takeUntilDestroyed()).subscribe(params => {
    void this.actions.run(async () => { await this.store.load(params.get('taskId')!); this.resetDraft(); });
  }); }
  protected resetDraft(): void {
    const value = this.store.task()!.value;
    this.form.reset({ title: value.title, description: value.description, status: value.status, priority: value.priority, dueDate: value.dueDate ?? '' });
    this.assignment.reset({ assigneeId: value.assigneeId ?? '' });
  }
  protected async save(): Promise<void> {
    if (this.form.invalid) return;
    const values = this.form.getRawValue();
    const body: TaskUpdate = {};
    for (const key of ['title', 'description', 'status', 'priority', 'dueDate'] as const) {
      if (this.form.controls[key].dirty) Object.assign(body, { [key]: key === 'dueDate' ? values[key] || null : values[key] });
    }
    if (Object.keys(body).length && await this.actions.run(() => this.store.save(body), true)) this.resetDraft();
  }
  protected async complete(): Promise<void> { if (await this.actions.run(() => this.store.complete(), true)) this.resetDraft(); }
  protected async reassign(): Promise<void> { if (await this.actions.run(() => this.store.reassign(this.assignment.getRawValue().assigneeId || null), true)) this.resetDraft(); }
  protected async remove(): Promise<void> { const projectId = this.store.task()!.value.projectId; if (await this.confirm().ask() && await this.actions.run(() => this.store.remove(), true)) await this.router.navigate(['/projects', projectId]); }
  protected async comment(): Promise<void> { if (this.commentForm.valid && await this.actions.run(() => this.store.comment(this.commentForm.getRawValue().body), true)) this.commentForm.reset(); }
  protected async removeComment(id: string): Promise<void> { if (await this.confirm().ask()) await this.actions.run(() => this.store.removeComment(id), true); }
  protected moreComments(): void { void this.actions.run(() => this.store.comments.more()); }
  protected moreMembers(): void { void this.actions.run(() => this.store.members.more()); }
  protected date(value: string | null): string { return value ? new Intl.DateTimeFormat(undefined, { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(value)) : 'Not completed'; }
}
