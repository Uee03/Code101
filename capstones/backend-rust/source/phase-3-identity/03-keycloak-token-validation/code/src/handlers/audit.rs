use axum::{Json, extract::State};

use crate::{
    auth::{self, AuthUser},
    error::AppError,
    extract::Params,
    models::{AuditEntry, Page},
    state::AppState,
    store::audit::AuditFilter,
};

/// Admin role and `tasks:admin` scope: both are needed, either one alone gives 403.
pub async fn list_audit(
    State(app): State<AppState>,
    user: AuthUser,
    params: Params,
) -> Result<Json<Page<AuditEntry>>, AppError> {
    user.require_scope(auth::ADMIN)?;
    user.require_admin()?;
    let filter = AuditFilter {
        entity_type: params.parse("entityType")?,
        entity_id: params.parse("entityId")?,
        actor_id: params.parse("actorId")?,
        from: params.parse("from")?,
        to: params.parse("to")?,
    };
    Ok(Json(app.store.list_audit(&filter, &params.page()?).await?))
}
