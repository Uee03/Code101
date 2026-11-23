use std::{env, net::SocketAddr, str::FromStr};

#[derive(Clone)]
pub struct Config {
    pub bind_addr: SocketAddr,
    pub database_url: String,
    pub public_base_url: String,
    pub token_issuer: String,
    pub token_audience: String,
    pub jwks_url: String,
    pub cors_origins: Vec<String>,
    pub rate_limit_user: u32,
    pub rate_limit_anon: u32,
    pub rate_limit_window_secs: u64,
}

impl Config {
    pub fn from_env() -> Result<Self, String> {
        let bind_addr = var_or("BIND_ADDR", "127.0.0.1:8000")
            .parse()
            .map_err(|err| format!("BIND_ADDR is not a socket address: {err}"))?;
        let database_url = env::var("DATABASE_URL").map_err(|_| "DATABASE_URL is not set".to_owned())?;
        let public_base_url = var_or("PUBLIC_BASE_URL", "http://localhost:8000").trim_end_matches('/').to_owned();
        // The issuer is compared with the `iss` claim as plain text; the JWKS URL is where the keys are fetched.
        // They differ inside Docker: tokens say localhost:8180, the API reaches Keycloak as keycloak:8080.
        let token_issuer = var_or("TOKEN_ISSUER", "http://localhost:8180/realms/tasksteams");
        let token_audience = var_or("TOKEN_AUDIENCE", "tasks-api");
        let jwks_url = var_or("JWKS_URL", "http://127.0.0.1:8180/realms/tasksteams/protocol/openid-connect/certs");
        let cors_origins = var_or("CORS_ORIGINS", "http://localhost:4200,http://localhost:5173")
            .split(',')
            .map(|origin| origin.trim().to_owned())
            .filter(|origin| !origin.is_empty())
            .collect();
        Ok(Self {
            bind_addr,
            database_url,
            public_base_url,
            token_issuer,
            token_audience,
            jwks_url,
            cors_origins,
            rate_limit_user: number("RATE_LIMIT_USER", 100)?,
            rate_limit_anon: number("RATE_LIMIT_ANON", 30)?,
            rate_limit_window_secs: number("RATE_LIMIT_WINDOW_SECS", 60)?,
        })
    }
}

fn var_or(name: &str, default: &str) -> String {
    env::var(name).unwrap_or_else(|_| default.to_owned())
}

fn number<T: FromStr>(name: &str, default: T) -> Result<T, String> {
    match env::var(name) {
        Ok(text) => text.parse().map_err(|_| format!("{name} is not a number: {text}")),
        Err(_) => Ok(default),
    }
}
