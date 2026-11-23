#[tokio::main]
async fn main() -> anyhow::Result<()> {
    if std::env::args().any(|arg| arg == "--self-check") {
        return axum_contract::self_check().await;
    }
    let listener = tokio::net::TcpListener::bind("127.0.0.1:3106").await?;
    println!("listening on http://127.0.0.1:3106");
    axum::serve(listener, axum_contract::app()).await?;
    Ok(())
}
