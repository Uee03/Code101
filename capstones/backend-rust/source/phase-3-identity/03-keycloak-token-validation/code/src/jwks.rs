use std::{
    collections::HashMap,
    time::{Duration, Instant},
};

use jsonwebtoken::{
    Algorithm, DecodingKey, Validation, decode, decode_header,
    jwk::{JwkSet, KeyAlgorithm, PublicKeyUse},
};
use tokio::sync::{Mutex, RwLock};

use crate::{auth::Claims, config::Config, error::AppError};

/// Keycloak is asked for its keys again at most this often when a token names a key we do not know.
const REFETCH_COOLDOWN: Duration = Duration::from_secs(10);

/// Validates access tokens: signature (keys from the JWKS endpoint, cached), issuer, audience and expiry.
pub struct Authenticator {
    http: reqwest::Client,
    jwks_url: String,
    validation: Validation,
    keys: RwLock<HashMap<String, DecodingKey>>,
    refresh: Mutex<Refresh>,
}

#[derive(Default)]
struct Refresh {
    at: Option<Instant>,
    failed: bool,
}

impl Authenticator {
    pub fn new(config: &Config) -> Self {
        // Only RS256 is accepted, so a token with `alg: none` or an HMAC `alg` is rejected before any key is used.
        let mut validation = Validation::new(Algorithm::RS256);
        validation.set_issuer(&[&config.token_issuer]);
        validation.set_audience(&[&config.token_audience]);
        validation.set_required_spec_claims(&["exp", "iss", "aud", "sub"]);
        validation.validate_nbf = true;
        validation.leeway = 30;
        let http = reqwest::Client::builder().timeout(Duration::from_secs(5)).build().expect("HTTP client");
        Self { http, jwks_url: config.jwks_url.clone(), validation, keys: RwLock::default(), refresh: Mutex::default() }
    }

    pub async fn verify(&self, token: &str) -> Result<Claims, AppError> {
        let header = decode_header(token).map_err(|_| AppError::InvalidToken)?;
        let kid = header.kid.ok_or(AppError::InvalidToken)?;
        let key = self.key(&kid).await?;
        decode::<Claims>(token, &key, &self.validation).map(|data| data.claims).map_err(|err| {
            // The reason helps an operator; it is never sent to the client and never contains the token.
            tracing::debug!(reason = %err, "access token rejected");
            AppError::InvalidToken
        })
    }

    async fn key(&self, kid: &str) -> Result<DecodingKey, AppError> {
        if let Some(key) = self.keys.read().await.get(kid) {
            return Ok(key.clone());
        }
        // Unknown key id: one task at a time asks Keycloak, and not more often than the cooldown allows,
        // so a client that invents key ids cannot turn this API into a request flood against Keycloak.
        let mut refresh = self.refresh.lock().await;
        if let Some(key) = self.keys.read().await.get(kid) {
            return Ok(key.clone());
        }
        if refresh.at.is_some_and(|at| at.elapsed() < REFETCH_COOLDOWN) {
            return Err(if refresh.failed {
                AppError::Internal("the signing keys are not available".to_owned())
            } else {
                AppError::InvalidToken
            });
        }
        refresh.at = Some(Instant::now());
        match self.fetch_keys().await {
            Ok(fetched) => {
                refresh.failed = false;
                let key = fetched.get(kid).cloned();
                *self.keys.write().await = fetched;
                key.ok_or(AppError::InvalidToken)
            }
            Err(err) => {
                refresh.failed = true;
                Err(AppError::Internal(format!("cannot fetch the signing keys: {err}")))
            }
        }
    }

    async fn fetch_keys(&self) -> Result<HashMap<String, DecodingKey>, reqwest::Error> {
        let set: JwkSet = self.http.get(&self.jwks_url).send().await?.error_for_status()?.json().await?;
        let keys = set
            .keys
            .iter()
            .filter(|jwk| !matches!(jwk.common.public_key_use, Some(PublicKeyUse::Encryption)))
            .filter(|jwk| matches!(jwk.common.key_algorithm, None | Some(KeyAlgorithm::RS256)))
            .filter_map(|jwk| Some((jwk.common.key_id.clone()?, DecodingKey::from_jwk(jwk).ok()?)))
            .collect();
        Ok(keys)
    }
}
