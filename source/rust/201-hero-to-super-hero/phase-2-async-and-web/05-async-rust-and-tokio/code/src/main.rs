use anyhow::Result;
use async_jobs::{deadline_expires, label, pair};

#[tokio::main]
async fn main() -> Result<()> {
    let (left, right) = pair().await;
    println!("{left} | {right}");
    let owned = String::from("owned");
    let handle = tokio::spawn(async move { label(&owned).await });
    println!("{}", handle.await?);
    println!("deadline expired: {}", deadline_expires().await);
    Ok(())
}
