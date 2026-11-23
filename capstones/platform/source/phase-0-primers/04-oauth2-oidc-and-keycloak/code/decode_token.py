"""Take a JWT apart the way a backend starts to: split it, decode it, check the claims.

Without an argument it builds a practice token. With a real access token as the first
argument it takes that one apart instead. It never checks the signature.
"""
import base64
import json
import sys
import time

ISSUER = "http://localhost:8180/realms/tasksteams"


def b64url(raw):
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode()


def decode_part(part):
    return json.loads(base64.urlsafe_b64decode(part + "=" * (-len(part) % 4)))


def practice_token(now):
    header = {"alg": "RS256", "typ": "JWT", "kid": "practice-key"}
    payload = {
        "iss": ISSUER,
        "sub": "b0b00000-0000-4000-8000-000000000002",
        "aud": "tasks-api",
        "preferred_username": "bob",
        "scope": "openid tasks:read tasks:write",
        "realm_access": {"roles": ["member"]},
        "iat": now,
        "exp": now + 300,
    }
    return ".".join([
        b64url(json.dumps(header).encode()),
        b64url(json.dumps(payload).encode()),
        b64url(b"signature"),
    ])


def check(claims, now):
    problems = []
    if claims["iss"] != ISSUER:
        problems.append("wrong issuer")
    audience = claims["aud"] if isinstance(claims["aud"], list) else [claims["aud"]]  # aud may be a string or a list
    if "tasks-api" not in audience:
        problems.append("wrong audience")
    if claims["exp"] < now:
        problems.append("token expired")
    if "tasks:read" not in claims["scope"].split():
        problems.append("scope tasks:read missing")
    return problems


now = int(time.time())
token = sys.argv[1] if len(sys.argv) > 1 else practice_token(now)
parts = token.split(".")
print(f"parts: {len(parts)} (header, payload, signature)")
print("header:", decode_part(parts[0]))
claims = decode_part(parts[1])
print("user:", claims["preferred_username"], claims["sub"])
print("roles:", ", ".join(claims["realm_access"]["roles"]))
print("scopes:", claims["scope"])
print("lifetime:", claims["exp"] - claims["iat"], "seconds")
print("checks:", check(claims, now) or "all passed")
print("expired token:", check(dict(claims, exp=now - 1), now))
print("other audience:", check(dict(claims, aud="other-api"), now))
print("signature: not checked here, a real backend verifies it with Keycloak's public key")
