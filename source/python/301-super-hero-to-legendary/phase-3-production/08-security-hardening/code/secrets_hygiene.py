import hmac
import os
from collections.abc import Mapping
from pathlib import Path


class Secret:
    __slots__ = ("_value",)

    def __init__(self, value: str) -> None:
        self._value = value

    def reveal(self) -> str:
        return self._value

    def __repr__(self) -> str:
        return "Secret('****')"

    __str__ = __repr__


def read_secret(name: str, environ: Mapping[str, str] = os.environ) -> Secret:
    file_path = environ.get(f"{name}_FILE")
    if file_path:
        return Secret(Path(file_path).read_text(encoding="utf-8").strip())
    value = environ.get(name)
    if value:
        return Secret(value)
    raise RuntimeError(f"secret {name} is not configured")


def tokens_match(supplied: str, expected: Secret) -> bool:
    return hmac.compare_digest(supplied.encode(), expected.reveal().encode())
