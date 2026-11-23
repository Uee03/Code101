#!/usr/bin/env python3
"""Show what is inside an access token. For learning only: it does not check the signature.

  python scripts/show_token.py bob

It asks Keycloak for a token (fake local password, client tasks-smoke) and prints the header and the claims.
"""
import base64
import json
import os
import sys
import urllib.parse
import urllib.request

KEYCLOAK_URL = os.environ.get("KEYCLOAK_URL", "http://127.0.0.1:8180")
PASSWORDS = {"alice": "alice-local-fake", "bob": "bob-local-fake", "carol": "carol-local-fake"}


def decode(part):
    return json.loads(base64.urlsafe_b64decode(part + "=" * (-len(part) % 4)))


def main():
    user = sys.argv[1] if len(sys.argv) > 1 else "alice"
    form = urllib.parse.urlencode({"grant_type": "password", "client_id": "tasks-smoke", "username": user,
                                   "password": PASSWORDS[user], "scope": "openid tasks:read tasks:write"}).encode()
    request = urllib.request.Request(f"{KEYCLOAK_URL}/realms/tasksteams/protocol/openid-connect/token", data=form)
    with urllib.request.urlopen(request, timeout=15) as response:
        token = json.load(response)["access_token"]
    header, claims, _signature = token.split(".")
    print("header:", json.dumps(decode(header)))
    for name, value in decode(claims).items():
        print(f"{name}: {json.dumps(value)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
