from pydantic import SecretStr, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="NOTES_", env_file=".env", extra="ignore")
    database_url: SecretStr
    jwt_secret: SecretStr

    @field_validator("jwt_secret")
    @classmethod
    def require_generated_secret(cls, value: SecretStr) -> SecretStr:
        secret = value.get_secret_value()
        if len(secret) < 32 or secret.startswith("replace-"):
            raise ValueError("generate a private JWT secret of at least 32 characters")
        return value
