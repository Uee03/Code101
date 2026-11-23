#!/usr/bin/env python3
"""Platform checks, phase 3: Keycloak tokens and Postgres reachability. Standard library only."""
import argparse
import base64
import json
import os
import socket
import struct
import sys
import urllib.error
import urllib.parse
import urllib.request

KEYCLOAK_URL = os.environ.get("KEYCLOAK_URL", "http://127.0.0.1:8180")
ISSUER = os.environ.get("TOKEN_ISSUER", "http://localhost:8180/realms/tasksteams")
REALM = os.environ.get("KEYCLOAK_REALM", "tasksteams")
POSTGRES_HOST = os.environ.get("POSTGRES_HOST", "127.0.0.1")
POSTGRES_PORT = int(os.environ.get("POSTGRES_PORT", "5432"))
SMOKE_CLIENT = "tasks-smoke"
PASSWORDS = {
    "alice": os.environ.get("SMOKE_ALICE_PASSWORD", "alice-local-fake"),
    "bob": os.environ.get("SMOKE_BOB_PASSWORD", "bob-local-fake"),
}
ALICE_ID = "a11ce000-0000-4000-8000-000000000001"


def http_post_form(url, form):
    data = urllib.parse.urlencode(form).encode()
    request = urllib.request.Request(url, data=data, method="POST")
    try:
        with urllib.request.urlopen(request, timeout=15) as response:
            return response.status, json.loads(response.read())
    except urllib.error.HTTPError as err:
        return err.code, json.loads(err.read() or b"{}")


def http_get_json(url):
    with urllib.request.urlopen(url, timeout=15) as response:
        return json.loads(response.read())


def token_for(username):
    url = f"{KEYCLOAK_URL}/realms/{REALM}/protocol/openid-connect/token"
    status, body = http_post_form(url, {
        "grant_type": "password",
        "client_id": SMOKE_CLIENT,
        "username": username,
        "password": PASSWORDS[username],
        "scope": "openid tasks:read tasks:write tasks:admin",
    })
    if status != 200:
        raise AssertionError(f"token endpoint answered {status}: {body.get('error_description', body)}")
    return body["access_token"]


def claims_of(token):
    payload = token.split(".")[1]
    return json.loads(base64.urlsafe_b64decode(payload + "=" * (-len(payload) % 4)))


def check_discovery():
    doc = http_get_json(f"{KEYCLOAK_URL}/realms/{REALM}/.well-known/openid-configuration")
    assert doc["issuer"] == ISSUER, f"issuer is {doc['issuer']}, expected {ISSUER}"
    assert "S256" in doc["code_challenge_methods_supported"], "PKCE S256 is not offered"
    return "issuer matches, PKCE S256 offered"


def check_alice_token():
    claims = claims_of(token_for("alice"))
    assert claims["iss"] == ISSUER, f"iss is {claims['iss']}"
    audience = claims["aud"] if isinstance(claims["aud"], list) else [claims["aud"]]  # aud may be a string or a list
    assert "tasks-api" in audience, f"aud is {claims['aud']}"
    assert claims["sub"] == ALICE_ID, f"sub is {claims['sub']}"
    assert "admin" in claims["realm_access"]["roles"], "role admin missing"
    assert {"tasks:read", "tasks:write", "tasks:admin"} <= set(claims["scope"].split()), "scopes missing"
    return "iss, aud tasks-api, sub, role admin, three scopes"


def check_bob_token():
    claims = claims_of(token_for("bob"))
    roles = claims["realm_access"]["roles"]
    assert "member" in roles and "admin" not in roles, f"roles are {roles}"
    return "role member only"


def check_postgres():
    with socket.create_connection((POSTGRES_HOST, POSTGRES_PORT), timeout=5) as sock:
        sock.sendall(struct.pack("!ii", 8, 80877103))  # the Postgres SSLRequest message
        answer = sock.recv(1)
    assert answer in (b"S", b"N"), f"unexpected reply {answer!r}"
    return f"{POSTGRES_HOST}:{POSTGRES_PORT} answers the Postgres protocol"


def run(name, check):
    try:
        detail = check()
    except Exception as exc:  # a failed check is reported, the others still run
        print(f"FAIL  {name}: {exc}")
        return False
    print(f"PASS  {name} ({detail})")
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--infra-only", action="store_true", help="accepted for later phases; phase 3 only has infra checks")
    parser.parse_args()
    checks = [
        ("keycloak discovery", check_discovery),
        ("token for alice", check_alice_token),
        ("token for bob", check_bob_token),
        ("postgres reachable", check_postgres),
    ]
    results = [run(name, check) for name, check in checks]
    print(f"{sum(results)} passed, {len(results) - sum(results)} failed")
    return 0 if all(results) else 1


if __name__ == "__main__":
    sys.exit(main())
