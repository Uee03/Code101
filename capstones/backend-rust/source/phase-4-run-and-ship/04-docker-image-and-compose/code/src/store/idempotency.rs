use serde_json::Value;
use uuid::Uuid;

use super::Store;
use crate::error::AppError;

pub enum Claim {
    /// The key is new: the caller owns it and must run the request.
    Fresh,
    /// The same request already finished: send the stored response again.
    Replay(Value),
    /// The same key arrived with another request body.
    Mismatch,
    /// The first request with this key has not finished yet.
    InProgress,
}

impl Store {
    pub async fn claim_key(&self, user_id: Uuid, key: &str, request_hash: &str) -> Result<Claim, AppError> {
        sqlx::query("DELETE FROM idempotency_keys WHERE user_id = $1 AND key = $2 AND expires_at < now()")
            .bind(user_id)
            .bind(key)
            .execute(&self.pool)
            .await?;
        let inserted = sqlx::query(
            "INSERT INTO idempotency_keys (user_id, key, request_hash) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING",
        )
        .bind(user_id)
        .bind(key)
        .bind(request_hash)
        .execute(&self.pool)
        .await?;
        if inserted.rows_affected() == 1 {
            return Ok(Claim::Fresh);
        }
        let (stored_hash, response): (String, Option<Value>) =
            sqlx::query_as("SELECT request_hash, response_body FROM idempotency_keys WHERE user_id = $1 AND key = $2")
                .bind(user_id)
                .bind(key)
                .fetch_one(&self.pool)
                .await?;
        Ok(match response {
            _ if stored_hash != request_hash => Claim::Mismatch,
            Some(body) => Claim::Replay(body),
            None => Claim::InProgress,
        })
    }

    pub async fn finish_key(&self, user_id: Uuid, key: &str, response: &Value) -> Result<(), AppError> {
        sqlx::query(
            "UPDATE idempotency_keys SET status_code = 201, response_body = $3 WHERE user_id = $1 AND key = $2",
        )
        .bind(user_id)
        .bind(key)
        .bind(response)
        .execute(&self.pool)
        .await?;
        Ok(())
    }

    /// A failed request must not keep its key, otherwise the client could never retry it.
    pub async fn release_key(&self, user_id: Uuid, key: &str) -> Result<(), AppError> {
        sqlx::query("DELETE FROM idempotency_keys WHERE user_id = $1 AND key = $2")
            .bind(user_id)
            .bind(key)
            .execute(&self.pool)
            .await?;
        Ok(())
    }
}
