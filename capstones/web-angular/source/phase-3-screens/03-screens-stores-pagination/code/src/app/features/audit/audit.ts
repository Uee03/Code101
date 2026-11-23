import { ChangeDetectionStrategy, Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { AUDIT_ENTITY_TYPE } from '../../api/models/audit-entity-type-array';
import { Actions } from '../../core/actions';
import { AuditStore } from './audit.store';
@Component({ selector: 'app-audit', imports: [ReactiveFormsModule], changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<h1 tabindex="-1">Audit log</h1><form [formGroup]="form" (ngSubmit)="filterUrl()">
    <label for="audit-entity">Entity type</label><select id="audit-entity" formControlName="entityType"><option value="">All</option>@for (entity of entities; track entity) { <option [value]="entity">{{ entity }}</option> }</select>
    <label for="audit-actor">Actor UUID</label><input id="audit-actor" formControlName="actorId">
    <label for="audit-from">From (inclusive UTC)</label><input id="audit-from" type="datetime-local" formControlName="from">
    <label for="audit-to">To (exclusive UTC)</label><input id="audit-to" type="datetime-local" formControlName="to"><button>Apply filters</button></form>
    <div class="table-scroll"><table><caption>Changes recorded by the API</caption><thead><tr><th scope="col">When</th><th scope="col">Actor</th><th scope="col">Action</th><th scope="col">Entity</th></tr></thead><tbody>
      @for (entry of store.state().items; track entry.id) { <tr><td>{{ date(entry.occurredAt) }}</td><td>{{ entry.actorId ?? 'System' }}</td><td>{{ entry.action }}</td><td>{{ entry.entityType }} {{ entry.entityId }}</td></tr> }
    </tbody></table></div><button [disabled]="!store.state().nextCursor" (click)="more()">Load more audit entries</button>` })
export class Audit {
  protected readonly store = inject(AuditStore);
  protected readonly entities = AUDIT_ENTITY_TYPE;
  private readonly actions = inject(Actions);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  protected readonly form = inject(FormBuilder).nonNullable.group({ entityType: '', actorId: '', from: '', to: '' });
  constructor() { this.route.queryParamMap.pipe(takeUntilDestroyed()).subscribe(params => {
    const entityType = AUDIT_ENTITY_TYPE.find(value => value === params.get('entityType'));
    const actorId = params.get('actorId') || undefined;
    const from = params.get('from') || undefined; const to = params.get('to') || undefined;
    this.form.setValue({ entityType: entityType ?? '', actorId: actorId ?? '', from: from?.replace(/Z$/, '') ?? '', to: to?.replace(/Z$/, '') ?? '' });
    void this.actions.run(() => this.store.loadAudit({ entityType, actorId, from, to }));
  }); }
  protected filterUrl(): void { const values = this.form.getRawValue(); void this.router.navigate([], { relativeTo: this.route, queryParams: { ...values, from: values.from ? values.from + 'Z' : null, to: values.to ? values.to + 'Z' : null } }); }
  protected more(): void { void this.actions.run(() => this.store.more()); }
  protected date(value: string): string { return new Intl.DateTimeFormat(undefined, { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(value)); }
}
