use chrono::{DateTime, Utc};
use sqlx::QueryBuilder;
use uuid::Uuid;

use super::{Store, page::PageRequest};
use crate::{
    error::AppError,
    models::{AuditEntry, EntityType, Page},
};

#[derive(Debug, Default)]
pub struct AuditFilter {
    pub entity_type: Option<EntityType>,
    pub entity_id: Option<Uuid>,
    pub actor_id: Option<Uuid>,
    pub from: Option<DateTime<Utc>>,
    pub to: Option<DateTime<Utc>>,
}

impl Store {
    /// Newest first. The `tasks_app` role can read and append to `audit_log`, never change it.
    pub async fn list_audit(&self, filter: &AuditFilter, page: &PageRequest) -> Result<Page<AuditEntry>, AppError> {
        let mut query = QueryBuilder::new(
            "SELECT a.id, a.occurred_at, a.actor_id, a.action, a.entity_type, a.entity_id, a.details \
             FROM audit_log a WHERE TRUE",
        );
        if let Some(entity_type) = filter.entity_type {
            query.push(" AND a.entity_type = ").push_bind(entity_type.as_str());
        }
        if let Some(entity_id) = filter.entity_id {
            query.push(" AND a.entity_id = ").push_bind(entity_id);
        }
        if let Some(actor_id) = filter.actor_id {
            query.push(" AND a.actor_id = ").push_bind(actor_id);
        }
        if let Some(from) = filter.from {
            query.push(" AND a.occurred_at >= ").push_bind(from);
        }
        if let Some(to) = filter.to {
            query.push(" AND a.occurred_at < ").push_bind(to);
        }
        page.keyset::<i64>(&mut query, "a.occurred_at", "a.id", true)?;
        page.fetch(query, &self.pool, |entry: &AuditEntry| (entry.occurred_at, entry.id)).await
    }
}
