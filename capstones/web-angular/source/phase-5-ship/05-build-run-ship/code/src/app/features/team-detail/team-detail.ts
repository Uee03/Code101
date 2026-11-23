import { FieldErrors } from '../../shared/field-errors';
import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { AuthService } from '../../auth/auth.service';
import { Actions } from '../../core/actions';
import { Connectivity } from '../../core/connectivity';
import { TeamDetailStore } from './team-detail.store';
@Component({ selector: 'app-team-detail', imports: [FieldErrors, ReactiveFormsModule, RouterLink], changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<h1 tabindex="-1">Team detail</h1>@if (store.team(); as entry) {
    <p>{{ entry.value.name }}: {{ entry.value.description }}</p><a [routerLink]="['/teams', id, 'projects']">Projects</a>
    <nav aria-label="Team sections"><button (click)="membersTab = false" [attr.aria-pressed]="!membersTab">Details</button><button (click)="membersTab = true" [attr.aria-pressed]="membersTab">Members</button></nav>
    @if (!membersTab && auth.isLead(id)) { <form appFieldErrors [formGroup]="form" (ngSubmit)="save()">
      <label for="edit-team-name">Name</label><input id="edit-team-name" formControlName="name" required maxlength="80">
      <label for="edit-team-description">Description</label><textarea id="edit-team-description" formControlName="description" maxlength="500"></textarea>
      <button [disabled]="form.invalid || !connection.online()">Save team</button></form> }
    @if (membersTab) { <h2>Members</h2><ul>@for (member of store.members.state().items; track member.userId) {
      <li>{{ member.displayName }} ({{ member.role }})
      @if (auth.isLead(id)) { <button [disabled]="!connection.online()" (click)="change(member.userId, member.role === 'lead' ? 'member' : 'lead')">Change role for {{ member.displayName }}</button>
        <button [disabled]="!connection.online()" (click)="remove(member.userId)">Remove {{ member.displayName }}</button> }</li> }</ul>
      <button [disabled]="!store.members.state().nextCursor" (click)="more()">Load more members</button>
      @if (auth.isLead(id)) { <form appFieldErrors [formGroup]="memberForm" (ngSubmit)="put()">
        <label for="member-id">Existing user UUID</label><input id="member-id" formControlName="userId" required>
        <label for="member-role">Role</label><select id="member-role" formControlName="role"><option>member</option><option>lead</option></select>
        <button [disabled]="memberForm.invalid || !connection.online()">Add or update member</button></form> }
    }
  }` })
export class TeamDetail {
  protected readonly store = inject(TeamDetailStore);
  protected readonly auth = inject(AuthService);
  protected readonly connection = inject(Connectivity);
  private readonly actions = inject(Actions);
  private readonly route = inject(ActivatedRoute);
  private readonly fb = inject(FormBuilder).nonNullable;
  protected id = '';
  protected membersTab = false;
  protected readonly form = this.fb.group({ name: ['', Validators.required], description: '' });
  protected readonly memberForm = this.fb.group({ userId: ['', Validators.required], role: 'member' });
  constructor() { this.route.paramMap.pipe(takeUntilDestroyed()).subscribe(params => {
    this.id = params.get('teamId')!;
    void this.actions.run(async () => { await this.store.load(this.id); this.form.setValue({ name: this.store.team()!.value.name, description: this.store.team()!.value.description }); });
  }); }
  protected save(): void { if (this.form.valid) { const v = this.form.getRawValue(); void this.actions.run(() => this.store.save(v.name, v.description), true); } }
  protected put(): void { if (this.memberForm.valid) { const v = this.memberForm.getRawValue(); this.change(v.userId, v.role === 'lead' ? 'lead' : 'member'); } }
  protected change(id: string, role: 'lead' | 'member'): void { void this.actions.run(() => this.store.put(id, role), true); }
  protected remove(id: string): void { void this.actions.run(() => this.store.remove(id), true); }
  protected more(): void { void this.actions.run(() => this.store.members.more()); }
}
