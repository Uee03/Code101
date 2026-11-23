from pydantic import Field, ValidationError
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="EXERCISE_", env_file=None)
    retries: int = Field(default=3, ge=1, le=5)


assert Settings(retries=5).retries == 5
try:
    Settings(retries=0)
except ValidationError:
    print("invalid retries rejected")
else:
    raise AssertionError("zero retries was accepted")
