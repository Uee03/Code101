#!/usr/bin/env python3
"""Run the token rules offline: build tokens that break one rule each and show what the verifier says.

  python scripts/token_rules.py

No Keycloak and no network: the script makes its own RSA key and hands the verifier the matching public key.
"""
import base64
import hashlib
import hmac
import json
import sys
import time
from pathlib import Path

import jwt
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from app.tokens import TokenRejected, TokenVerifier  # noqa: E402

ISSUER = "http://localhost:8180/realms/tasksteams"
AUDIENCE = "tasks-api"
trusted_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
attacker_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
verifier = TokenVerifier(issuer=ISSUER, audience=AUDIENCE, key_for=lambda token: trusted_key.public_key(), leeway=30)


def make_token(key=trusted_key, algorithm="RS256", **changes) -> str:
    now = int(time.time())
    claims = {"iss": ISSUER, "aud": AUDIENCE, "sub": "a11ce000-0000-4000-8000-000000000001", "iat": now, "exp": now + 300}
    claims.update(changes)
    claims = {name: value for name, value in claims.items() if value is not None}  # None removes a claim
    return jwt.encode(claims, key, algorithm=algorithm, headers={"kid": "demo"})


def hs256_with_public_key() -> str:
    """The key-confusion attack: sign with HMAC, using the server's PUBLIC key text as the secret."""
    def part(data: dict) -> str:
        return base64.urlsafe_b64encode(json.dumps(data).encode()).rstrip(b"=").decode()

    public_pem = trusted_key.public_key().public_bytes(serialization.Encoding.PEM, serialization.PublicFormat.SubjectPublicKeyInfo)
    now = int(time.time())
    signing_input = part({"alg": "HS256", "typ": "JWT", "kid": "demo"}) + "." + part(
        {"iss": ISSUER, "aud": AUDIENCE, "sub": "a11ce000-0000-4000-8000-000000000001", "exp": now + 300})
    signature = hmac.new(public_pem, signing_input.encode(), hashlib.sha256).digest()
    return signing_input + "." + base64.urlsafe_b64encode(signature).rstrip(b"=").decode()


now = int(time.time())
cases = [
    ("valid token", make_token(), True),
    ("audience is a list that contains tasks-api", make_token(aud=["account", AUDIENCE]), True),
    ("expired 10 s ago (inside the 30 s skew)", make_token(exp=now - 10), True),
    ("expired 120 s ago", make_token(exp=now - 120), False),
    ("not valid before 5 minutes from now", make_token(nbf=now + 300), False),
    ("wrong issuer", make_token(iss="http://evil.example/realms/tasksteams"), False),
    ("wrong audience (string)", make_token(aud="account"), False),
    ("wrong audience (list)", make_token(aud=["account", "other-api"]), False),
    ("no exp claim", make_token(exp=None), False),
    ("no sub claim", make_token(sub=None), False),
    ("signed with another key", make_token(key=attacker_key), False),
    ("algorithm none (no signature)", make_token(key=None, algorithm="none"), False),
    ("HS256 signed with the public key", hs256_with_public_key(), False),
    ("not a token at all", "hello", False),
]

failures = 0
for name, token, should_pass in cases:
    try:
        verifier.verify(token)
        outcome, passed = "accepted", True
    except TokenRejected as rejected:
        outcome, passed = f"rejected: {rejected.reason}", False
    verdict = "ok   " if passed == should_pass else "WRONG"
    failures += passed != should_pass
    print(f"{verdict} {name:<44} {outcome}")
print("all rules hold" if failures == 0 else f"{failures} rule(s) broken")
sys.exit(1 if failures else 0)
