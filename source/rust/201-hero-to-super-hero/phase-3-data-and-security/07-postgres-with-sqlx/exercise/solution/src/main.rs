use anyhow::{ensure, Context, Result};
use postgres_notes::{find_note, insert_note, valid_title, FIND_NOTE};
use sqlx::postgres::PgPoolOptions;
use std::time::Duration;

#[tokio::main]
async fn main() -> Result<()> {
    if std::env::args().any(|arg| arg == "--describe") {
        println!("runtime SQL: {FIND_NOTE}");
        println!("no database connection opened");
        return Ok(());
    }
    let url = std::env::var("DATABASE_URL").context("set DATABASE_URL in this terminal")?;
    let pool = PgPoolOptions::new().max_connections(5)
        .acquire_timeout(Duration::from_secs(5)).connect(&url).await?;
    sqlx::query(include_str!("../schema.sql")).execute(&pool).await?;
    let title = "Rust";
    ensure!(valid_title(title), "invalid title");
    let mut tx = pool.begin().await?;
    let (id, stored) = insert_note(&mut tx, title).await?;
    let selected: (i64, String) = sqlx::query_as(FIND_NOTE)
        .bind(id).fetch_one(&mut *tx).await?;
    assert_eq!(selected.1, stored);
    println!("stored title: {stored}");
    tx.rollback().await?;
    ensure!(find_note(&pool, id).await?.is_none(), "rollback failed");
    println!("rolled back: true");
    pool.close().await;
    Ok(())
}
