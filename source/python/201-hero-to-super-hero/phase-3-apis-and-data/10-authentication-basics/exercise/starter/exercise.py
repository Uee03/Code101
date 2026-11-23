from secrets import token_hex

import jwt
from jwt.exceptions import InvalidTokenError


def validate(token: str, secret: str) -> str:
    # TODO: validate signature, HS256, issuer, audience and required claims.
    raise NotImplementedError("complete token validation")


secret = token_hex(32)
token = jwt.encode({"sub": "ada", "iss": "python201", "aud": "notes-api"}, secret, algorithm="HS256")
try:
    validate(token, secret)
except InvalidTokenError:
    print("missing expiry rejected")
else:
    raise AssertionError("accepted a token without exp")
