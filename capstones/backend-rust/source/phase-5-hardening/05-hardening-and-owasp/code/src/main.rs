use std::{error::Error, net::SocketAddr, sync::Arc, time::Duration};

use tasks_api::{app, config::Config, jwks::Authenticator, ratelimit::RateLimiter, state::AppState, store::Store};
use tokio::{
    io::{AsyncReadExt, AsyncWriteExt},
    net::{TcpListener, TcpStream},
    signal,
    time::timeout,
};
use tracing_subscriber::EnvFilter;

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    dotenvy::dotenv().ok();
    let config = Config::from_env()?;
    // `tasks-api healthcheck` is what Docker runs: the image has no shell, curl or wget.
    if std::env::args().nth(1).as_deref() == Some("healthcheck") {
        return healthcheck(&config).await.inspect_err(|err| eprintln!("unhealthy: {err}"));
    }
    tracing_subscriber::fmt()
        .json()
        .with_env_filter(EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")))
        .init();

    let store = Store::connect(&config.database_url).await?;
    let listener = TcpListener::bind(config.bind_addr).await?;
    tracing::info!(address = %config.bind_addr, "listening");
    let state = AppState {
        store,
        auth: Arc::new(Authenticator::new(&config)),
        limiter: Arc::new(RateLimiter::new(Duration::from_secs(config.rate_limit_window_secs))),
        config: Arc::new(config),
    };
    // `ConnectInfo` hands the client address to the rate limiter.
    let service = app::router(state).into_make_service_with_connect_info::<SocketAddr>();
    axum::serve(listener, service).with_graceful_shutdown(shutdown_signal()).await?;
    Ok(())
}

/// Asks the running server on this machine for `GET /health` and succeeds only on a 200.
async fn healthcheck(config: &Config) -> Result<(), Box<dyn Error>> {
    let limit = Duration::from_secs(3);
    let mut stream = timeout(limit, TcpStream::connect(("127.0.0.1", config.bind_addr.port()))).await??;
    stream.write_all(b"GET /health HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n").await?;
    let mut reply = String::new();
    timeout(limit, stream.read_to_string(&mut reply)).await??;
    match reply.lines().next() {
        Some(status) if status.starts_with("HTTP/1.1 200") => Ok(()),
        other => Err(format!("the server answered {}", other.unwrap_or("nothing")).into()),
    }
}

/// Resolves on Ctrl+C (all systems) or SIGTERM (what `docker stop` sends).
async fn shutdown_signal() {
    let ctrl_c = async {
        signal::ctrl_c().await.expect("cannot listen for Ctrl+C");
    };
    #[cfg(unix)]
    let terminate = async {
        signal::unix::signal(signal::unix::SignalKind::terminate()).expect("cannot listen for SIGTERM").recv().await;
    };
    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();
    tokio::select! {
        _ = ctrl_c => {}
        _ = terminate => {}
    }
    tracing::info!("shutting down");
}
