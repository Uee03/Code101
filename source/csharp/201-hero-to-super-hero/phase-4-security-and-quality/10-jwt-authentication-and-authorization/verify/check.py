"""Checks the lesson-10 API. The API must already run in Development on port 5081."""
import json
import sys
import urllib.error
import urllib.request

BASE = "http://localhost:5081"


def call(method, path, token=None):
    request = urllib.request.Request(BASE + path, method=method, data=b"" if method == "POST" else None)
    if token:
        request.add_header("Authorization", "Bearer " + token)
    try:
        with urllib.request.urlopen(request) as response:
            return response.status, response.read().decode()
    except urllib.error.HTTPError as error:
        return error.code, error.read().decode()


def token_for(who):
    status, body = call("POST", "/dev/token?who=" + who)
    assert status == 200, f"token for {who}: {status}"
    return body


def expect(label, actual, expected):
    if actual != expected:
        print(f"FAIL {label}: expected {expected!r}, got {actual!r}")
        sys.exit(1)


ada, grace, root = token_for("ada"), token_for("grace"), token_for("root")

expect("public", call("GET", "/public"), (200, "Anyone can read this."))
expect("me anonymous", call("GET", "/me")[0], 401)
status, body = call("GET", "/me", grace)
expect("me grace status", status, 200)
expect("me grace body", json.loads(body), {"name": "grace", "role": "user", "permissions": ["notes:read", "notes:write"]})
expect("write as reader", call("POST", "/notes", ada)[0], 403)
expect("write as writer", call("POST", "/notes", grace)[0], 201)
expect("read own note", call("GET", "/notes/1", ada)[0], 200)
expect("read foreign note", call("GET", "/notes/1", grace)[0], 403)
expect("admin reads any note", call("GET", "/notes/1", root)[0], 200)
expect("delete as writer", call("DELETE", "/notes/1", grace)[0], 403)
expect("delete as admin", call("DELETE", "/notes/1", root)[0], 204)
expect("tampered token", call("GET", "/me", grace[:-3] + "abc")[0], 401)
