#!/usr/bin/env python3
"""Call the Tasks and Teams API and print the answer. Standard library only.

  python scripts/call.py GET /v1/teams
  python scripts/call.py --as bob GET /v1/me
  python scripts/call.py POST /v1/teams name="Ops Team" --idempotency-key 11111111-aaaa
  python scripts/call.py PATCH /v1/tasks/<id> status=in_progress --if-match 1

key=value pairs make the JSON body; a value that is valid JSON (true, 5, null) keeps its type, anything else is text.
--body-file sends a file as the body instead. --as alice|bob|carol first asks Keycloak for an access token (fake local passwords, client tasks-smoke).
"""
import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

BASE_URL = os.environ.get("BASE_URL", "http://127.0.0.1:8000").rstrip("/")
KEYCLOAK_URL = os.environ.get("KEYCLOAK_URL", "http://127.0.0.1:8180")
PASSWORDS = {"alice": "alice-local-fake", "bob": "bob-local-fake", "carol": "carol-local-fake"}
SHOWN = ("ETag", "Location", "Idempotent-Replayed", "RateLimit-Limit", "RateLimit-Remaining", "RateLimit-Reset",
         "Retry-After", "WWW-Authenticate", "Content-Type")


def token_for(user, scope):
    form = urllib.parse.urlencode({"grant_type": "password", "client_id": "tasks-smoke", "username": user,
                                   "password": PASSWORDS[user], "scope": scope}).encode()
    request = urllib.request.Request(f"{KEYCLOAK_URL}/realms/tasksteams/protocol/openid-connect/token", data=form)
    with urllib.request.urlopen(request, timeout=15) as response:
        return json.load(response)["access_token"]


def parse_pair(pair):
    key, _, value = pair.partition("=")
    try:
        return key, json.loads(value)
    except json.JSONDecodeError:
        return key, value


def main():
    parser = argparse.ArgumentParser(description="Call the Tasks and Teams API.")
    parser.add_argument("method")
    parser.add_argument("path")
    parser.add_argument("fields", nargs="*", help="key=value pairs for the JSON body")
    parser.add_argument("--as", dest="user", choices=sorted(PASSWORDS), help="sign in as this user first")
    parser.add_argument("--token", help="send this text as the bearer token (to try a wrong one)")
    parser.add_argument("--scope", default="openid tasks:read tasks:write tasks:admin")
    parser.add_argument("--if-match", help="version number, sent as If-Match")
    parser.add_argument("--if-none-match", help="version number, sent as If-None-Match")
    parser.add_argument("--idempotency-key")
    parser.add_argument("--body-file", help="send this file as the JSON body")
    parser.add_argument("--pretty", action="store_true", help="indent the JSON answer")
    args = parser.parse_args()

    headers = {"Accept": "application/json"}
    if args.user:
        headers["Authorization"] = "Bearer " + token_for(args.user, args.scope)
    if args.token:
        headers["Authorization"] = "Bearer " + args.token
    if args.if_match:
        headers["If-Match"] = f'"{args.if_match}"'
    if args.if_none_match:
        headers["If-None-Match"] = f'"{args.if_none_match}"'
    if args.idempotency_key:
        headers["Idempotency-Key"] = args.idempotency_key
    data = None
    if args.fields:
        data = json.dumps(dict(parse_pair(pair) for pair in args.fields)).encode()
    if args.body_file:
        with open(args.body_file, "rb") as body_file:
            data = body_file.read()
    if data is not None:
        headers["Content-Type"] = "application/merge-patch+json" if args.method.upper() == "PATCH" else "application/json"

    request = urllib.request.Request(BASE_URL + args.path, data=data, headers=headers, method=args.method.upper())
    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            status, reason, received, body = response.status, response.reason, response.headers, response.read()
    except urllib.error.HTTPError as error:
        status, reason, received, body = error.code, error.reason, error.headers, error.read()

    print(f"HTTP {status} {reason}")
    for name in SHOWN:
        if received.get(name):
            print(f"{name}: {received[name]}")
    if body:
        print()
        try:
            print(json.dumps(json.loads(body), indent=2 if args.pretty else None, separators=None if args.pretty else (",", ":")))
        except json.JSONDecodeError:
            print(body.decode(errors="replace"))
    return 0 if status < 400 else 1


if __name__ == "__main__":
    sys.exit(main())
