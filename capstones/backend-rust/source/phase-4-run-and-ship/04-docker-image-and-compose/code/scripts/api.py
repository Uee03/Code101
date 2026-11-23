#!/usr/bin/env python3
"""A small HTTP client for the lessons, so the same commands work on Windows, macOS and Linux. Standard library only.

  python scripts/api.py GET /health
  python scripts/api.py --as alice GET /v1/me
  python scripts/api.py --as alice POST /v1/teams name="Rust Team" description="Made by hand"
  python scripts/api.py --as alice PATCH /v1/tasks/ID --if-match 1 status=done assigneeId:=null
  python scripts/api.py --raw '{bad' POST /v1/teams
  python scripts/api.py --as alice --token

name=text sends a JSON string. name:=value sends raw JSON (a number, true, false, null).
--raw TEXT sends TEXT as the body; --raw @- reads the body from standard input.
--if-match 3 sends If-Match: "3" (the quotes of an ETag are easy to lose in a shell, so the script adds them).
--as alice|bob asks Keycloak for an access token first (the smoke client of the platform realm).
Environment: BASE_URL (default http://127.0.0.1:8000), KEYCLOAK_URL (default http://127.0.0.1:8180).
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
PASSWORDS = {"alice": "alice-local-fake", "bob": "bob-local-fake"}


def send(method, url, headers=None, data=None):
    request = urllib.request.Request(url, data=data, headers=headers or {}, method=method)
    try:
        with urllib.request.urlopen(request, timeout=15) as response:
            return response.status, response.headers, response.read()
    except urllib.error.HTTPError as err:  # 4xx and 5xx answers are results, not crashes
        return err.code, err.headers, err.read()


def token_for(username):
    form = urllib.parse.urlencode({
        "grant_type": "password",
        "client_id": "tasks-smoke",
        "username": username,
        "password": PASSWORDS[username],
        "scope": "openid tasks:read tasks:write tasks:admin",
    }).encode()
    url = f"{KEYCLOAK_URL}/realms/tasksteams/protocol/openid-connect/token"
    status, _, body = send("POST", url, {"Content-Type": "application/x-www-form-urlencoded"}, form)
    if status != 200:
        sys.exit(f"Keycloak answered {status}: {body.decode()[:200]}")
    return json.loads(body)["access_token"]


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--as", dest="user", choices=sorted(PASSWORDS), help="send a bearer token for this user")
    parser.add_argument("--token", action="store_true", help="print the access token and stop")
    parser.add_argument("--raw", help="send this text as the body, exactly as written")
    parser.add_argument("-H", dest="headers", action="append", default=[], help="extra header, 'Name: value'")
    parser.add_argument("--if-match", metavar="VERSION", help="send If-Match with the version in quotes")
    parser.add_argument("--if-none-match", metavar="VERSION", help="send If-None-Match with the version in quotes")
    parser.add_argument("method", nargs="?", help="GET, POST, PUT, PATCH or DELETE")
    parser.add_argument("path", nargs="?", help="for example /v1/me")
    parser.add_argument("fields", nargs="*", help="name=text or name:=json")
    args = parser.parse_args()

    if args.token:
        print(token_for(args.user or "alice"))
        return 0
    if not args.method or not args.path:
        parser.error("give a method and a path")

    headers = {"Accept": "application/json"}
    if args.user:
        headers["Authorization"] = f"Bearer {token_for(args.user)}"
    for line in args.headers:
        name, _, value = line.partition(":")
        headers[name.strip()] = value.strip()
    if args.if_match:
        headers["If-Match"] = f'"{args.if_match}"'
    if args.if_none_match:
        headers["If-None-Match"] = f'"{args.if_none_match}"'

    data = None
    if args.raw is not None:
        data = sys.stdin.buffer.read() if args.raw == "@-" else args.raw.encode()
    elif args.fields:
        body = {}
        for field in args.fields:
            if ":=" in field:
                name, _, value = field.partition(":=")
                body[name] = json.loads(value)
            else:
                name, _, value = field.partition("=")
                body[name] = value
        data = json.dumps(body).encode()
    if data is not None:
        headers.setdefault("Content-Type", "application/json")

    status, response_headers, raw = send(args.method.upper(), BASE_URL + args.path, headers, data)
    print(f"HTTP {status}")
    for name, value in response_headers.items():
        if name.lower() not in ("date", "content-length", "connection", "transfer-encoding", "keep-alive"):
            print(f"{name}: {value}")
    text = raw.decode("utf-8", errors="replace")
    if text:
        try:
            text = json.dumps(json.loads(text), indent=2)
        except json.JSONDecodeError:
            pass
        print()
        print(text)
    return 0 if status < 400 else 1


if __name__ == "__main__":
    sys.exit(main())
