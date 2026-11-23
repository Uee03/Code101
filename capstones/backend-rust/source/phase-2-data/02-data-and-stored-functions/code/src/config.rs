use std::{env, net::SocketAddr};

#[derive(Clone)]
pub struct Config {
    pub bind_addr: SocketAddr,
    pub database_url: String,
    pub public_base_url: String,
}

impl Config {
    pub fn from_env() -> Result<Self, String> {
        let bind_addr = var_or("BIND_ADDR", "127.0.0.1:8000")
            .parse()
            .map_err(|err| format!("BIND_ADDR is not a socket address: {err}"))?;
        let database_url = env::var("DATABASE_URL").map_err(|_| "DATABASE_URL is not set".to_owned())?;
        let public_base_url = var_or("PUBLIC_BASE_URL", "http://localhost:8000").trim_end_matches('/').to_owned();
        Ok(Self { bind_addr, database_url, public_base_url })
    }
}

fn var_or(name: &str, default: &str) -> String {
    env::var(name).unwrap_or_else(|_| default.to_owned())
}
