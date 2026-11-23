from datetime import UTC, datetime, timedelta

import jwt
from jwt.exceptions import InvalidTokenError
from pwdlib import PasswordHash

ISSUER = "python201"
AUDIENCE = "notes-api"
ALGORITHM = "HS256"
password_hash = PasswordHash.recommended()


def issue_token(subject: str, secret: str, *, now: datetime | None = None) -> str:
    if not subject.strip():
        raise ValueError("subject must not be blank")
    issued = now if now is not None else datetime.now(UTC)
    return jwt.encode(
        {"sub": subject, "iss": ISSUER, "aud": AUDIENCE, "exp": issued + timedelta(minutes=5)},
        secret,
        algorithm=ALGORITHM,
    )


def validate_token(token: str, secret: str) -> str:
    claims = jwt.decode(
        token,
        secret,
        algorithms=[ALGORITHM],
        issuer=ISSUER,
        audience=AUDIENCE,
        options={"require": ["exp", "sub", "iss", "aud"]},
    )
    subject = claims["sub"]
    if not isinstance(subject, str) or not subject.strip():
        raise InvalidTokenError("subject must not be blank")
    return subject
