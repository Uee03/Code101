use std::{env, net::SocketAddr};

#[derive(Clone)]
pub struct Config {
    pub bind_addr: SocketAddr,
    pub database_url: String,
    pub public_base_url: String,
    pub token_issuer: String,
    pub token_audience: String,
    pub jwks_url: String,
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
        Ok(Self { bind_addr, database_url, public_base_url, token_issuer, token_audience, jwks_url })
    }
}

fn var_or(name: &str, default: &str) -> String {
    env::var(name).unwrap_or_else(|_| default.to_owned())
}
