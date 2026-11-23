from pydantic import Field, ValidationError
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="EXERCISE_", env_file=None)
    # TODO: constrain retries to the inclusive range 1 through 5.
    retries: int = 3


assert Settings(retries=5).retries == 5
try:
    Settings(retries=0)
except ValidationError:
    print("invalid retries rejected")
else:
    raise AssertionError("zero retries was accepted")
