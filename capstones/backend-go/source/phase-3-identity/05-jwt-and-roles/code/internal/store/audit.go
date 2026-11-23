package store

import (
	"context"
	"strconv"
	"time"
)

// AuditEntry is one row of the audit trail. Details is the JSON the trigger wrote.
type AuditEntry struct {
	ID         int64
	OccurredAt time.Time
	ActorID    *string
	Action     string
	EntityType string
	EntityID   string
	Details    []byte
}

// AuditFilter holds the optional filters of the audit list.
type AuditFilter struct {
	EntityType string
	EntityID   string
	ActorID    string
	From       *time.Time // inclusive
	To         *time.Time // exclusive
	Page       PageParams
}

// ListAudit returns audit entries, newest first.
func (s *Store) ListAudit(ctx context.Context, f AuditFilter) (Page[AuditEntry], error) {
	cursor, err := decodeCursor(f.Page.Cursor, "audit", numberID)
	if err != nil {
		return Page[AuditEntry]{}, err
	}
	var b builder
	if f.EntityType != "" {
		b.where("a.entity_type = " + b.arg(f.EntityType))
	}
	if f.EntityID != "" {
		b.where("a.entity_id = " + b.arg(f.EntityID))
	}
	if f.ActorID != "" {
		b.where("a.actor_id = " + b.arg(f.ActorID))
	}
	if f.From != nil {
		b.where("a.occurred_at >= " + b.arg(*f.From))
	}
	if f.To != nil {
		b.where("a.occurred_at < " + b.arg(*f.To))
	}
	b.afterTime("a.occurred_at", "a.id", true, cursor)
	sql := "SELECT a.id, a.occurred_at, a.actor_id, a.action, a.entity_type, a.entity_id, a.details FROM audit_log a" +
		b.whereSQL() + orderBy("a.occurred_at", "a.id", true) + " LIMIT " + b.arg(f.Page.Limit+1)
	items, err := collect[AuditEntry](ctx, s.pool, sql, b.args...)
	if err != nil {
		return Page[AuditEntry]{}, err
	}
	return finishPage(items, f.Page.Limit, func(e AuditEntry) Cursor {
		return Cursor{Sort: "audit", Time: e.OccurredAt, ID: strconv.FormatInt(e.ID, 10)}
	}), nil
}
