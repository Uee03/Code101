from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Every setting comes from an environment variable of the same name (DATABASE_URL, TOKEN_ISSUER, ...)."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    service_version: str = "1.0.0"
    log_level: str = "INFO"
    public_base_url: str = "http://localhost:8000"
    enable_docs: bool = True
    database_url: str
    db_pool_size: int = 10
    db_max_overflow: int = 10
    token_issuer: str
    token_audience: str = "tasks-api"
    jwks_url: str
    token_leeway_seconds: int = 30


@lru_cache
def get_settings() -> Settings:
    return Settings()
