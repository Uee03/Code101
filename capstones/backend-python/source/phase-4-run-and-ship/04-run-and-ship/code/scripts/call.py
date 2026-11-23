#!/usr/bin/env python3
"""Send one request to the API and print the answer the way `curl -i` would. Works the same in every shell.

  python scripts/call.py GET /health
  python scripts/call.py GET /v1/me --user bob
  python scripts/call.py POST /v1/projects/<id>/tasks --user bob --body requests/task-create.json --idempotency-key demo-key-0001
  python scripts/call.py PATCH /v1/tasks/<id> --user bob --body requests/task-patch.json --if-match 1
  python scripts/call.py token alice          prints only the access token, for use with curl

--user alice|bob|carol fetches a token from Keycloak (the tasks-smoke client, fake local users only).
"""
import argparse
import http.client
import json
import os
import sys
import urllib.parse
import urllib.request
from pathlib import Path

API_URL = os.environ.get("API_URL", "http://127.0.0.1:8000")
KEYCLOAK_URL = os.environ.get("KEYCLOAK_URL", "http://127.0.0.1:8180")
PASSWORDS = {"alice": "alice-local-fake", "bob": "bob-local-fake", "carol": "carol-local-fake"}


def get_token(username: str) -> str:
    form = urllib.parse.urlencode({
        "grant_type": "password",
        "client_id": "tasks-smoke",
        "username": username,
        "password": PASSWORDS[username],
        "scope": "openid tasks:read tasks:write tasks:admin",
    }).encode()
    url = f"{KEYCLOAK_URL}/realms/tasksteams/protocol/openid-connect/token"
    with urllib.request.urlopen(urllib.request.Request(url, data=form), timeout=15) as response:
        return json.load(response)["access_token"]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("method", help="GET, POST, PUT, PATCH, DELETE, or the word token")
    parser.add_argument("target", help="the path, for example /v1/me; or the user name after the word token")
    parser.add_argument("--user", choices=sorted(PASSWORDS), help="send a bearer token for this user")
    parser.add_argument("--token", help="send this bearer token as it is (for example a forged one)")
    parser.add_argument("--body", help="file with the JSON request body")
    parser.add_argument("--if-match", help="version number; sent as the strong ETag \"N\"")
    parser.add_argument("--if-none-match", help="version number; sent as \"N\"")
    parser.add_argument("--idempotency-key")
    parser.add_argument("--header", action="append", default=[], help="extra header as 'Name: value'")
    args = parser.parse_args()

    if args.method == "token":
        print(get_token(args.target))
        return 0

    headers = {"Accept": "application/json"}
    token = args.token or (get_token(args.user) if args.user else None)
    if token:
        headers["Authorization"] = f"Bearer {token}"
    data = None
    if args.body:
        data = Path(args.body).read_bytes()
        headers["Content-Type"] = "application/merge-patch+json" if args.method == "PATCH" else "application/json"
    if args.if_match:
        headers["If-Match"] = f'"{args.if_match}"'
    if args.if_none_match:
        headers["If-None-Match"] = f'"{args.if_none_match}"'
    if args.idempotency_key:
        headers["Idempotency-Key"] = args.idempotency_key
    for header in args.header:
        name, _, value = header.partition(":")
        headers[name.strip()] = value.strip()

    parts = urllib.parse.urlsplit(API_URL)
    connection = http.client.HTTPConnection(parts.hostname, parts.port or 80, timeout=30)
    connection.request(args.method, args.target, body=data, headers=headers)
    response = connection.getresponse()
    print(f"HTTP/1.1 {response.status} {response.reason}")
    for name, value in response.getheaders():
        print(f"{name.lower()}: {value}")
    print()
    print(response.read().decode("utf-8", errors="replace"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
