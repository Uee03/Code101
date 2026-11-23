use chrono::{DateTime, Utc};
use sqlx::{FromRow, QueryBuilder};
use uuid::Uuid;

use super::{
    Store,
    page::{PageRequest, like_escape},
};
use crate::{
    auth::AuthUser,
    error::AppError,
    models::{MeTeam, Page, UserSummary},
};

impl Store {
    /// Creates the user row on the first request of a new Keycloak user. Remembered in memory afterwards.
    pub async fn ensure_user(&self, user: &AuthUser) -> Result<(), AppError> {
        if self.known_users.lock().expect("known_users lock").contains(&user.id) {
            return Ok(());
        }
        sqlx::query(
            "INSERT INTO users (id, username, email, display_name) VALUES ($1, $2, $3, $4) ON CONFLICT DO NOTHING",
        )
        .bind(user.id)
        .bind(&user.username)
        .bind(&user.email)
        .bind(&user.display_name)
        .execute(&self.pool)
        .await?;
        self.known_users.lock().expect("known_users lock").insert(user.id);
        Ok(())
    }

    pub async fn my_teams(&self, user_id: Uuid) -> Result<Vec<MeTeam>, AppError> {
        let teams = sqlx::query_as::<_, MeTeam>(
            "SELECT t.id AS team_id, t.name, m.role FROM team_members m JOIN teams t ON t.id = m.team_id \
             WHERE m.user_id = $1 ORDER BY t.name",
        )
        .bind(user_id)
        .fetch_all(&self.pool)
        .await?;
        Ok(teams)
    }

    pub async fn list_users(&self, q: Option<&str>, page: &PageRequest) -> Result<Page<UserSummary>, AppError> {
        let mut query =
            QueryBuilder::new("SELECT u.id, u.username, u.display_name, u.created_at FROM users u WHERE TRUE");
        if let Some(q) = q {
            let prefix = format!("{}%", like_escape(q));
            query.push(" AND (u.username ILIKE ").push_bind(prefix.clone());
            query.push(" OR u.display_name ILIKE ").push_bind(prefix).push(")");
        }
        page.keyset::<Uuid>(&mut query, "u.created_at", "u.id", false)?;
        let rows = page.fetch(query, &self.pool, |user: &UserRow| (user.created_at, user.id)).await?;
        let items = rows
            .items
            .into_iter()
            .map(|user| UserSummary { id: user.id, username: user.username, display_name: user.display_name })
            .collect();
        Ok(Page { items, page: rows.page })
    }
}

/// The summary plus the column the cursor needs.
#[derive(FromRow)]
struct UserRow {
    id: Uuid,
    username: String,
    display_name: String,
    created_at: DateTime<Utc>,
}
