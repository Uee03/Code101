use base64::{Engine, engine::general_purpose::URL_SAFE_NO_PAD};
use serde::{Serialize, de::DeserializeOwned};
use sqlx::{Encode, FromRow, PgPool, Postgres, QueryBuilder, Type, postgres::PgRow};

use crate::{
    error::AppError,
    models::{Page, PageInfo},
};

/// The opaque cursor is the sort key and id of the last item, as JSON, in base64url.
pub fn encode_cursor<T: Serialize>(key: &T) -> String {
    URL_SAFE_NO_PAD.encode(serde_json::to_vec(key).unwrap_or_default())
}

pub fn decode_cursor<T: DeserializeOwned>(cursor: &str) -> Result<T, AppError> {
    URL_SAFE_NO_PAD
        .decode(cursor)
        .ok()
        .and_then(|bytes| serde_json::from_slice(&bytes).ok())
        .ok_or_else(|| AppError::BadRequest("The cursor is not valid.".to_owned()))
}

/// Escapes `%`, `_` and `\` so user text is matched literally by LIKE and ILIKE.
pub fn like_escape(text: &str) -> String {
    text.replace('\\', "\\\\").replace('%', "\\%").replace('_', "\\_")
}

pub struct PageRequest {
    pub limit: i64,
    pub cursor: Option<String>,
}

impl PageRequest {
    /// Appends the keyset condition for a cursor, then ORDER BY and LIMIT. `I` is the type of the id column.
    pub fn keyset<I>(
        &self,
        query: &mut QueryBuilder<Postgres>,
        at: &str,
        id: &str,
        descending: bool,
    ) -> Result<(), AppError>
    where
        I: DeserializeOwned + for<'q> Encode<'q, Postgres> + Type<Postgres> + Send,
    {
        if let Some(cursor) = &self.cursor {
            let (last_at, last_id): (chrono::DateTime<chrono::Utc>, I) = decode_cursor(cursor)?;
            let comparison = if descending { "<" } else { ">" };
            query.push(format!(" AND ({at}, {id}) {comparison} ("));
            query.push_bind(last_at).push(", ").push_bind(last_id).push(")");
        }
        let direction = if descending { "DESC" } else { "ASC" };
        self.order_and_limit(query, &format!("{at} {direction}, {id} {direction}"));
        Ok(())
    }

    /// One more row than asked for tells us whether there is a next page.
    pub fn order_and_limit(&self, query: &mut QueryBuilder<Postgres>, order_by: &str) {
        query.push(format!(" ORDER BY {order_by} LIMIT "));
        query.push_bind(self.limit + 1);
    }

    pub async fn fetch<R, K>(
        &self,
        mut query: QueryBuilder<Postgres>,
        pool: &PgPool,
        next_key: impl Fn(&R) -> K,
    ) -> Result<Page<R>, AppError>
    where
        R: for<'r> FromRow<'r, PgRow> + Send + Unpin,
        K: Serialize,
    {
        let mut items: Vec<R> = query.build_query_as::<R>().fetch_all(pool).await?;
        let more = items.len() as i64 > self.limit;
        items.truncate(self.limit as usize);
        let next_cursor = match items.last() {
            Some(last) if more => Some(encode_cursor(&next_key(last))),
            _ => None,
        };
        Ok(Page { items, page: PageInfo { limit: self.limit, next_cursor } })
    }
}
