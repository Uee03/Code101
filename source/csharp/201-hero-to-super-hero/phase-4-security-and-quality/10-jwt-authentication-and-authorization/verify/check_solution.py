"""Checks the exercise solution of lesson 10. The API must already run in Development on port 5082."""
import json
import sys
import urllib.error
import urllib.request

BASE = "http://localhost:5082"


def call(method, path, token=None):
    request = urllib.request.Request(BASE + path, method=method, data=b"" if method == "POST" else None)
    if token:
        request.add_header("Authorization", "Bearer " + token)
    try:
        with urllib.request.urlopen(request) as response:
            return response.status, response.read().decode()
    except urllib.error.HTTPError as error:
        return error.code, error.read().decode()


def expect(label, actual, expected):
    if actual != expected:
        print(f"FAIL {label}: expected {expected!r}, got {actual!r}")
        sys.exit(1)


ada = call("POST", "/dev/token?who=ada")[1]
grace = call("POST", "/dev/token?who=grace")[1]

expect("list anonymous", call("GET", "/notes")[0], 401)
status, body = call("GET", "/notes", ada)
expect("list as reader", status, 200)
expect("list body", json.loads(body), [{"id": 1, "owner": "ada"}, {"id": 2, "owner": "grace"}])
expect("foreign note is hidden", call("GET", "/notes/1", grace)[0], 404)
expect("own note", call("GET", "/notes/1", ada)[0], 200)
