from typing import Literal

from pydantic import Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_prefix="NOTES_", env_file=".env", env_file_encoding="utf-8", extra="forbid"
    )

    api_key: SecretStr
    batch_size: int = Field(default=10, ge=1, le=100)
    log_level: Literal["DEBUG", "INFO", "WARNING"] = "INFO"
