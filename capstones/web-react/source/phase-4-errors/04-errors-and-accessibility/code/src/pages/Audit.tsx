import { useSearchParams } from 'react-router';
import { useAudit, type AuditFilter } from '../hooks/audit';
import { Page } from '../shared/Page';
import { Banner } from '../shared/Banner';
import { Field } from '../shared/WriteForm';
import { LoadMore } from '../shared/LoadMore';
export function Component() {
  const [params, setParams] = useSearchParams();
  const filters: AuditFilter = { entityType: (params.get('entityType') || undefined) as AuditFilter['entityType'],
    actorId: params.get('actorId') || undefined, from: params.get('from') || undefined, to: params.get('to') || undefined };
  const audit = useAudit(filters);
  return <Page title="Audit log"><form onSubmit={event => {
    event.preventDefault(); const next = new URLSearchParams();
    new FormData(event.currentTarget).forEach((value, key) => {
      if (value) next.set(key, key === 'from' || key === 'to' ? new Date(String(value)).toISOString() : String(value));
    }); setParams(next);
  }}><label>Entity type<select name="entityType" defaultValue={filters.entityType ?? ''}><option value="">All</option>{['team','member','project','task','comment'].map(type => <option key={type}>{type}</option>)}</select></label>
    <Field name="actorId" label="Actor UUID" value={params.get('actorId') ?? ''} maxLength={36} />
    <Field name="from" label="From (local time)" type="datetime-local" /><Field name="to" label="To (local time)" type="datetime-local" /><button>Apply filters</button>
    </form><Banner error={audit.error} retry={() => audit.refetch()} />
    <div className="table-wrap"><table><caption>Audit entries</caption><thead><tr><th scope="col">When</th><th scope="col">Action</th><th scope="col">Entity</th><th scope="col">Actor</th></tr></thead>
      <tbody>{audit.data?.pages.flatMap(page => page.items).map(entry => <tr key={entry.id}>
        <td>{new Intl.DateTimeFormat(undefined, { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(entry.occurredAt))}</td>
        <td>{entry.action}</td><td>{entry.entityType} {entry.entityId}</td><td>{entry.actorId ?? 'System'}</td>
      </tr>)}</tbody></table></div><LoadMore query={audit} />
  </Page>;
}
