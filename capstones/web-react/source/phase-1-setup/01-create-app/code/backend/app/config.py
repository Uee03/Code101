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
    rate_limit_user: int = 100
    rate_limit_anonymous: int = 30
    rate_limit_window_seconds: int = 60
    max_body_bytes: int = 1_048_576
    cors_origins: str = "http://localhost:4200,http://localhost:5173"
    enable_hsts: bool = False

    @property
    def cors_origin_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
