import { inject, Injectable } from '@angular/core';
import { Api } from '../../api/api';
import { listAuditLog } from '../../api/functions';
import { AuditEntry } from '../../api/models';
import { ListAuditLog$Params } from '../../api/fn/audit/list-audit-log';
import { CursorList } from '../../core/state';
@Injectable({ providedIn: 'root' })
export class AuditStore extends CursorList<AuditEntry> {
  private readonly api = inject(Api);
  loadAudit(filter: ListAuditLog$Params): Promise<void> { return this.load(cursor => this.api.invoke(listAuditLog, { ...filter, limit: 25, cursor })); }
}
