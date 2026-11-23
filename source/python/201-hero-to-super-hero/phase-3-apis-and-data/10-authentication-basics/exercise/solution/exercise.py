from secrets import token_hex

import jwt
from jwt.exceptions import InvalidTokenError


def validate(token: str, secret: str) -> str:
    claims = jwt.decode(
        token, secret, algorithms=["HS256"], issuer="python201", audience="notes-api",
        options={"require": ["exp", "sub", "iss", "aud"]},
    )
    return claims["sub"]


secret = token_hex(32)
token = jwt.encode({"sub": "ada", "iss": "python201", "aud": "notes-api"}, secret, algorithm="HS256")
try:
    validate(token, secret)
except InvalidTokenError:
    print("missing expiry rejected")
else:
    raise AssertionError("accepted a token without exp")
