from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy import Engine, URL, create_engine


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="forbid")

    postgres_password: SecretStr
    db_user: str = "notes"
    db_name: str = "notes"
    db_host: str = "127.0.0.1"
    db_port: int = 5542


def make_engine() -> Engine:
    settings = Settings()
    url = URL.create(
        "postgresql+psycopg",
        username=settings.db_user,
        password=settings.postgres_password.get_secret_value(),
        host=settings.db_host,
        port=settings.db_port,
        database=settings.db_name,
    )
    return create_engine(url, pool_pre_ping=True)
