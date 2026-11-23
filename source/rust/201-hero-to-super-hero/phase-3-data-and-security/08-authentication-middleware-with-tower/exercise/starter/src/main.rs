use anyhow::{Context, Result};
use jwt_middleware::Auth;

#[tokio::main]
async fn main() -> Result<()> {
    if std::env::args().any(|arg| arg == "--self-check") {
        let auth = Auth::new(b"self-check-only-not-a-server-secret")?;
        return jwt_middleware::self_check(auth).await;
    }
    let secret = std::env::var("JWT_SECRET").context("set a private JWT_SECRET of at least 32 random bytes")?;
    let auth = Auth::new(secret.as_bytes())?;
    let listener = tokio::net::TcpListener::bind("127.0.0.1:3108").await?;
    println!("listening on http://127.0.0.1:3108");
    axum::serve(listener, jwt_middleware::app(auth)).await?;
    Ok(())
}
