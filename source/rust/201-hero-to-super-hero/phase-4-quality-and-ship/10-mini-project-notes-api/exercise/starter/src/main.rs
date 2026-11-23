#[tokio::main]
async fn main() -> anyhow::Result<()> {
    if std::env::args().any(|arg| arg == "--self-check") {
        return notes_api::self_check().await;
    }
    tracing_subscriber::fmt().json().with_target(false).init();
    let address = std::env::var("BIND_ADDR").unwrap_or_else(|_| "127.0.0.1:3110".into());
    let listener = tokio::net::TcpListener::bind(&address).await?;
    tracing::info!(%address, "listening");
    axum::serve(listener, notes_api::app())
        .with_graceful_shutdown(async { let _ = tokio::signal::ctrl_c().await; })
        .await?;
    Ok(())
}
