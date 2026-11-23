import { ConfirmDialog } from '../../shared/confirm-dialog';
import { FieldErrors } from '../../shared/field-errors';
import { ChangeDetectionStrategy, Component, inject, viewChild } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { combineLatest } from 'rxjs';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { AuthService } from '../../auth/auth.service';
import { Actions } from '../../core/actions';
import { Connectivity } from '../../core/connectivity';
import { ProjectsStore } from './projects.store';
@Component({ selector: 'app-projects', imports: [FieldErrors, ReactiveFormsModule, RouterLink, ConfirmDialog], changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<h1 tabindex="-1">Projects</h1><button (click)="toggle()">{{ archived ? 'Show active' : 'Show archived' }}</button>
    @if (auth.isLead(teamId)) { <h2>Create project</h2><form appFieldErrors [formGroup]="form" (ngSubmit)="create()">
      <label for="project-key">Key (2-10 uppercase letters or digits, first a letter)</label><input id="project-key" formControlName="key" required pattern="[A-Z][A-Z0-9]{1,9}" aria-describedby="key-help">
      <p id="key-help">Example: PLAT. Keys are unique within the team.</p><label for="project-name">Name</label><input id="project-name" formControlName="name" required maxlength="120">
      <label for="project-description">Description</label><textarea id="project-description" formControlName="description" maxlength="2000"></textarea>
      <button [disabled]="form.invalid || !connection.online()">Create project</button></form> }
    <ul>@for (project of store.state().items; track project.id) { <li><a [routerLink]="['/projects', project.id]">{{ project.key }}: {{ project.name }}</a>
      @if (auth.isLead(teamId)) { <button [disabled]="!connection.online()" (click)="archive(project.id, !project.archived)">{{ project.archived ? 'Restore' : 'Archive' }}</button><button [disabled]="!connection.online()" (click)="remove(project.id)">Delete project</button> }</li> }</ul>
    <button [disabled]="!store.state().nextCursor" (click)="more()">Load more projects</button><app-confirm-dialog />` })
export class Projects {
  protected readonly store = inject(ProjectsStore);
  protected readonly auth = inject(AuthService);
  protected readonly connection = inject(Connectivity);
  private readonly actions = inject(Actions);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly confirm = viewChild.required(ConfirmDialog);
  protected teamId = '';
  protected archived = false;
  protected readonly form = inject(FormBuilder).nonNullable.group({ key: ['', [Validators.required, Validators.pattern(/^[A-Z][A-Z0-9]{1,9}$/)]], name: ['', Validators.required], description: '' });
  constructor() { combineLatest([this.route.paramMap, this.route.queryParamMap]).pipe(takeUntilDestroyed()).subscribe(([path, query]) => {
    this.teamId = path.get('teamId')!; this.archived = query.get('archived') === 'true'; this.reload();
  }); }
  private reload(): void { void this.actions.run(() => this.store.loadProjects(this.teamId, this.archived)); }
  protected toggle(): void { void this.router.navigate([], { relativeTo: this.route, queryParams: { archived: !this.archived } }); }
  protected async create(): Promise<void> { if (this.form.valid && await this.actions.run(() => this.store.create(this.teamId, this.form.getRawValue()), true)) { this.form.reset(); this.reload(); } }
  protected async archive(id: string, value: boolean): Promise<void> { if (await this.actions.run(() => this.store.archive(id, value), true)) this.reload(); }
  protected async remove(id: string): Promise<void> { if (await this.confirm().ask() && await this.actions.run(() => this.store.remove(id), true)) this.reload(); }
  protected more(): void { void this.actions.run(() => this.store.more()); }
}
