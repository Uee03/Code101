import { FieldErrors } from '../../shared/field-errors';
import { ChangeDetectionStrategy, Component, inject, OnInit, viewChild } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { AuthService } from '../../auth/auth.service';
import { Actions } from '../../core/actions';
import { Connectivity } from '../../core/connectivity';
import { Icon } from '../../shared/icon';
import { ConfirmDialog } from '../../shared/confirm-dialog';
import { TeamsStore } from './teams.store';
@Component({ selector: 'app-teams', imports: [FieldErrors, ReactiveFormsModule, RouterLink, Icon, ConfirmDialog], changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<h1 tabindex="-1">Teams</h1>
    <form appFieldErrors [formGroup]="filter" (ngSubmit)="filterUrl()"><label for="team-search"><app-icon name="ui/search" />Search teams</label>
      <input id="team-search" formControlName="q" maxlength="100"><label for="team-sort">Sort</label>
      <select id="team-sort" formControlName="sort"><option value="-createdAt">Newest</option><option value="createdAt">Oldest</option></select><button>Search</button></form>
    @if (auth.isAdmin()) { <h2>Create team</h2><form appFieldErrors [formGroup]="form" (ngSubmit)="create()">
      <label for="team-name">Name</label><input id="team-name" formControlName="name" required maxlength="80">
      <label for="team-description">Description</label><textarea id="team-description" formControlName="description" maxlength="500"></textarea>
      <button [disabled]="form.invalid || !connection.online()"><app-icon name="ui/plus" />Create team</button></form> }
    <ul>@for (team of store.state().items; track team.id) { <li><a [routerLink]="['/teams', team.id]">{{ team.name }}</a>
      @if (auth.isAdmin()) { <button [disabled]="!connection.online()" (click)="remove(team.id)">Delete {{ team.name }}</button> }</li> }</ul>
    @if (store.state().status === 'loading') { <p role="status">Loading teams</p> }
    <button [disabled]="!store.state().nextCursor || store.state().status === 'loadingMore'" (click)="more()">Load more teams</button><app-confirm-dialog />` })
export class Teams implements OnInit {
  protected readonly auth = inject(AuthService);
  protected readonly store = inject(TeamsStore);
  protected readonly connection = inject(Connectivity);
  private readonly actions = inject(Actions);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly confirm = viewChild.required(ConfirmDialog);
  private readonly fb = inject(FormBuilder).nonNullable;
  protected readonly filter = this.fb.group({ q: '', sort: '-createdAt' });
  protected readonly form = this.fb.group({ name: ['', [Validators.required, Validators.maxLength(80)]], description: '' });
  constructor() {
    this.route.queryParamMap.pipe(takeUntilDestroyed()).subscribe(params => {
      this.filter.setValue({ q: params.get('q') ?? '', sort: params.get('sort') === 'createdAt' ? 'createdAt' : '-createdAt' });
      this.reload();
    });
  }
  ngOnInit(): void { }
  private reload(): void { const { q, sort } = this.filter.getRawValue(); void this.actions.run(() => this.store.loadTeams(q, sort === 'createdAt' ? sort : '-createdAt')); }
  protected filterUrl(): void { void this.router.navigate([], { relativeTo: this.route, queryParams: this.filter.getRawValue() }); }
  protected async create(): Promise<void> { if (this.form.invalid) return; const { name, description } = this.form.getRawValue(); if (await this.actions.run(() => this.store.create(name, description), true)) { this.form.reset(); this.reload(); } }
  protected async remove(id: string): Promise<void> { if (!this.auth.hasScope('tasks:admin')) { await this.auth.signIn(this.router.url, true, true); return; } if (await this.confirm().ask() && await this.actions.run(() => this.store.remove(id), true)) this.reload(); }
  protected more(): void { void this.actions.run(() => this.store.more()); }
}
