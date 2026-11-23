from collections.abc import Callable
from typing import Any

import jwt
from jwt import PyJWKClient, PyJWKClientConnectionError


class TokenRejected(Exception):
    """The token cannot be trusted. `reason` is for our log, `public` is safe to show the caller."""

    def __init__(self, reason: str, public: str = "The access token is invalid.") -> None:
        super().__init__(reason)
        self.reason = reason
        self.public = public


class KeysUnavailable(Exception):
    """The signing keys could not be fetched. Not the caller's fault, so the API answers 503, not 401."""


class JwksKeys:
    """Finds the public key for a token. PyJWKClient keeps the JWK Set in memory for `lifespan` seconds and,
    when a token names an unknown `kid`, fetches it again at most once per `cooldown` seconds."""

    def __init__(self, url: str, lifespan: float = 300, cooldown: float = 30, timeout: float = 5) -> None:
        self._client = PyJWKClient(url, lifespan=lifespan, cooldown_duration=cooldown, timeout=timeout)

    def __call__(self, token: str) -> Any:
        try:
            return self._client.get_signing_key_from_jwt(token).key
        except PyJWKClientConnectionError as exc:
            raise KeysUnavailable(str(exc)) from exc
        except jwt.PyJWTError as exc:
            raise TokenRejected(f"no signing key for this token: {exc}") from exc


class TokenVerifier:
    """Applies the platform's token rules (platform TDD, section 7) and returns the claims of a valid token."""

    def __init__(self, *, issuer: str, audience: str, key_for: Callable[[str], Any], leeway: int = 30) -> None:
        self.issuer = issuer
        self.audience = audience
        self.key_for = key_for
        self.leeway = leeway

    def verify(self, token: str) -> dict[str, Any]:
        try:
            header = jwt.get_unverified_header(token)
        except jwt.PyJWTError:
            raise TokenRejected("not a JWT") from None
        if header.get("alg") != "RS256":  # blocks alg=none and the HS256 key-confusion attack before any key is looked up
            raise TokenRejected(f"algorithm {header.get('alg')!r} is not allowed")
        key = self.key_for(token)
        try:
            return jwt.decode(
                token,
                key,
                algorithms=["RS256"],
                issuer=self.issuer,
                audience=self.audience,  # PyJWT accepts both a string and a list in the aud claim
                leeway=self.leeway,
                options={"require": ["exp", "iss", "aud", "sub"]},
            )
        except jwt.ExpiredSignatureError:
            raise TokenRejected("token expired", "The access token has expired.") from None
        except jwt.PyJWTError as exc:
            raise TokenRejected(f"{type(exc).__name__}: {exc}") from None
