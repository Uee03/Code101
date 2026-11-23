use sqlx::{PgPool, Postgres, Transaction};

pub const FIND_NOTE: &str = "SELECT id, title FROM notes WHERE id = $1";

pub fn valid_title(title: &str) -> bool {
    // TODO: also reject control characters in the original title.
    (1..=80).contains(&title.trim().chars().count())
}

pub async fn insert_note(
    tx: &mut Transaction<'_, Postgres>,
    title: &str,
) -> Result<(i64, String), sqlx::Error> {
    sqlx::query_as::<_, (i64, String)>(
        "INSERT INTO notes (title) VALUES ($1) RETURNING id, title",
    ).bind(title).fetch_one(&mut **tx).await
}

pub async fn find_note(pool: &PgPool, id: i64) -> Result<Option<(i64, String)>, sqlx::Error> {
    sqlx::query_as::<_, (i64, String)>(FIND_NOTE)
        .bind(id).fetch_optional(pool).await
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn validates_before_io() {
        assert!(valid_title(" Rust "));
        assert!(!valid_title(" "));
        assert!(!valid_title("two\nlines"));
        assert!(!valid_title("tab\tstop"));
        assert!(!valid_title(&"a".repeat(81)));
    }
}
