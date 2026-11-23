use std::{
    collections::HashSet,
    sync::{Arc, Mutex},
    time::Duration,
};

use sqlx::{PgPool, Postgres, Transaction, postgres::PgPoolOptions};
use uuid::Uuid;

use crate::error::AppError;

pub mod audit;
pub mod comments;
pub mod idempotency;
pub mod page;
pub mod projects;
pub mod tasks;
pub mod teams;
pub mod users;

pub type Tx = Transaction<'static, Postgres>;

/// The data layer: every SQL statement of the API lives in this module tree.
#[derive(Clone)]
pub struct Store {
    pool: PgPool,
    known_users: Arc<Mutex<HashSet<Uuid>>>,
}

impl Store {
    pub async fn connect(database_url: &str) -> Result<Self, sqlx::Error> {
        let pool = PgPoolOptions::new()
            .max_connections(10)
            .acquire_timeout(Duration::from_secs(5))
            .connect(database_url)
            .await?;
        Ok(Self { pool, known_users: Arc::default() })
    }

    pub async fn ping(&self) -> bool {
        sqlx::query("SELECT 1").execute(&self.pool).await.is_ok()
    }

    /// Starts a write transaction and tells the audit trigger who is acting (`set_config(..., true)` is local to it).
    async fn begin_as(&self, actor: Uuid) -> Result<Tx, sqlx::Error> {
        let mut tx = self.pool.begin().await?;
        sqlx::query("SELECT set_config('app.current_user_id', $1, true)")
            .bind(actor.to_string())
            .execute(&mut *tx)
            .await?;
        Ok(tx)
    }
}

/// Maps database failures to problem types. The custom SQLSTATE codes are raised by the stored functions
/// in `db/schema.sql`: TS404 not found, TS409 rule violated, TS412 stale version, TS422 invalid input.
impl From<sqlx::Error> for AppError {
    fn from(err: sqlx::Error) -> Self {
        if let Some(db) = err.as_database_error() {
            let message = db.message().to_owned();
            match db.code().as_deref() {
                Some("TS404") => return Self::NotFound(message),
                Some("TS409") => return Self::conflict(message),
                Some("TS412") => return Self::PreconditionFailed(message),
                Some("TS422") => return Self::Unprocessable(message),
                Some("23505") => return Self::conflict("A record with the same name or key already exists."),
                Some("23503") => return Self::Unprocessable("A referenced record does not exist.".to_owned()),
                Some("23514") => return Self::Unprocessable("A value breaks a rule of the data model.".to_owned()),
                _ => {}
            }
        }
        if matches!(err, sqlx::Error::RowNotFound) {
            return Self::NotFound("The record does not exist.".to_owned());
        }
        Self::Internal(err.to_string())
    }
}
