#!/usr/bin/env python3
"""Platform conformance script. Standard library only.

  python scripts/conformance.py --infra-only      Keycloak tokens and Postgres reachability
  python scripts/conformance.py                   the above, then the API checks against BASE_URL

Every backend must pass the same checks, in this order. Exit code 0 means all passed.
"""
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
import uuid

BASE_URL = os.environ.get("BASE_URL", "http://127.0.0.1:8000").rstrip("/")
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

tokens = {}  # username -> access token, filled on first use
ctx = {}     # ids and ETags passed from one check to the next


class Response:
    def __init__(self, status, headers, raw):
        self.status = status
        self.headers = headers
        self.text = raw.decode("utf-8", errors="replace")

    @property
    def json(self):
        return json.loads(self.text)


def call(method, url, token=None, body=None, form=None, headers=None):
    hdrs = {"Accept": "application/json"}
    data = None
    if token:
        hdrs["Authorization"] = f"Bearer {token}"
    if body is not None:
        data = json.dumps(body).encode()
        hdrs["Content-Type"] = "application/json"
    if form is not None:
        data = urllib.parse.urlencode(form).encode()
        hdrs["Content-Type"] = "application/x-www-form-urlencoded"
    hdrs.update(headers or {})
    request = urllib.request.Request(url, data=data, headers=hdrs, method=method)
    try:
        with urllib.request.urlopen(request, timeout=15) as response:
            return Response(response.status, response.headers, response.read())
    except urllib.error.HTTPError as err:  # 4xx and 5xx (and 304) arrive here
        return Response(err.code, err.headers, err.read())


def api(method, path, who="alice", **kwargs):
    token = None if who is None else token_for(who)
    return call(method, BASE_URL + path, token=token, **kwargs)


def token_for(username):
    if username not in tokens:
        res = call("POST", f"{KEYCLOAK_URL}/realms/{REALM}/protocol/openid-connect/token", form={
            "grant_type": "password",
            "client_id": SMOKE_CLIENT,
            "username": username,
            "password": PASSWORDS[username],
            "scope": "openid tasks:read tasks:write tasks:admin",
        })
        assert res.status == 200, f"token endpoint answered {res.status}: {res.text[:200]}"
        tokens[username] = res.json["access_token"]
    return tokens[username]


def claims_of(token):
    payload = token.split(".")[1]
    return json.loads(base64.urlsafe_b64decode(payload + "=" * (-len(payload) % 4)))


def expect(res, status):
    assert res.status == status, f"expected HTTP {status}, got {res.status}: {res.text[:200]}"


def expect_problem(res, status):
    expect(res, status)
    content_type = res.headers.get("Content-Type", "")
    assert content_type.startswith("application/problem+json"), f"Content-Type is {content_type!r}"
    body = res.json
    for field in ("type", "title", "status"):
        assert field in body, f"problem has no {field!r}: {body}"
    assert body["status"] == status, f"problem status {body['status']} differs from HTTP {status}"
    return body


def need(key):
    assert key in ctx, f"needs the result of an earlier check ({key})"
    return ctx[key]


# Infrastructure checks ------------------------------------------------------

def check_discovery():
    res = call("GET", f"{KEYCLOAK_URL}/realms/{REALM}/.well-known/openid-configuration")
    expect(res, 200)
    assert res.json["issuer"] == ISSUER, f"issuer is {res.json['issuer']}, expected {ISSUER}"
    assert "S256" in res.json["code_challenge_methods_supported"], "PKCE S256 is not offered"
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
    roles = claims_of(token_for("bob"))["realm_access"]["roles"]
    assert "member" in roles and "admin" not in roles, f"roles are {roles}"
    return "role member only"


def check_postgres():
    with socket.create_connection((POSTGRES_HOST, POSTGRES_PORT), timeout=5) as sock:
        sock.sendall(struct.pack("!ii", 8, 80877103))  # the Postgres SSLRequest message
        answer = sock.recv(1)
    assert answer in (b"S", b"N"), f"unexpected reply {answer!r}"
    return f"{POSTGRES_HOST}:{POSTGRES_PORT} answers the Postgres protocol"


# API checks -----------------------------------------------------------------

def check_health():
    res = api("GET", "/health", who=None)
    expect(res, 200)
    assert res.json["status"] == "ok", f"status is {res.json['status']}"
    return "200, status ok, no token needed"


def check_me():
    res = api("GET", "/v1/me")
    expect(res, 200)
    me = res.json
    assert me["id"] == ALICE_ID and me["username"] == "alice", f"unexpected user {me['id']}"
    assert "admin" in me["roles"], f"roles are {me['roles']}"
    for name in ("RateLimit-Limit", "RateLimit-Remaining", "RateLimit-Reset"):
        assert res.headers.get(name, "").isdigit(), f"header {name} missing or not a number"
    return "alice is admin, RateLimit headers present"


def check_create_team():
    name = f"Conformance {uuid.uuid4().hex[:8]}"
    res = api("POST", "/v1/teams", body={"name": name, "description": "Created by the conformance script"},
              headers={"Idempotency-Key": str(uuid.uuid4())})
    expect(res, 201)
    team = res.json
    assert res.headers.get("Location", "").endswith(f"/v1/teams/{team['id']}"), "Location header does not point at the team"
    assert res.headers.get("ETag") == f'"{team["version"]}"', "ETag is not the quoted version"
    assert team["name"] == name and team["version"] == 1, f"unexpected team {team}"
    ctx["team"] = team["id"]
    return f"201, Location and ETag set, team {team['id']}"


def check_create_project():
    res = api("POST", f"/v1/teams/{need('team')}/projects",
              body={"key": "CNF", "name": "Conformance project"}, headers={"Idempotency-Key": str(uuid.uuid4())})
    expect(res, 201)
    ctx["project"] = res.json["id"]
    return f"201, project {ctx['project']}"


def check_create_task_idempotent():
    path = f"/v1/projects/{need('project')}/tasks"
    body = {"title": "First task", "priority": "high", "dueDate": "2027-06-30"}
    headers = {"Idempotency-Key": str(uuid.uuid4())}
    first = api("POST", path, body=body, headers=headers)
    expect(first, 201)
    assert first.json["status"] == "todo" and first.json["priority"] == "high", f"unexpected task {first.json}"
    replay = api("POST", path, body=body, headers=headers)
    expect(replay, 201)
    assert replay.json["id"] == first.json["id"], "the replay created a second task"
    assert replay.headers.get("Idempotent-Replayed") == "true", "replay lacks Idempotent-Replayed: true"
    expect_problem(api("POST", path, body={"title": "Another body"}, headers=headers), 422)
    ctx["task"] = first.json["id"]
    return "created once, replay returned the same task, other body gave 422"


def check_get_task_etag():
    res = api("GET", f"/v1/tasks/{need('task')}")
    expect(res, 200)
    etag = res.headers.get("ETag")
    assert etag == f'"{res.json["version"]}"', f"ETag {etag} is not the quoted version"
    cached = api("GET", f"/v1/tasks/{need('task')}", headers={"If-None-Match": etag})
    expect(cached, 304)
    ctx["etag"], ctx["version"] = etag, res.json["version"]
    return f"ETag {etag}, If-None-Match gave 304"


def check_update_if_match():
    res = api("PATCH", f"/v1/tasks/{need('task')}", body={"status": "in_progress", "assigneeId": ALICE_ID},
              headers={"If-Match": need("etag"), "Content-Type": "application/merge-patch+json"})
    expect(res, 200)
    task = res.json
    assert task["status"] == "in_progress" and task["assigneeId"] == ALICE_ID, f"unexpected task {task}"
    assert task["version"] == ctx["version"] + 1, f"version is {task['version']}"
    assert res.headers.get("ETag") == f'"{task["version"]}"', "new ETag is not the new version"
    return f"200, version {ctx['version']} -> {task['version']}"


def check_stale_if_match():
    path = f"/v1/tasks/{need('task')}"
    stale = api("PATCH", path, body={"title": "Too late"},
                headers={"If-Match": need("etag"), "Content-Type": "application/merge-patch+json"})
    expect_problem(stale, 412)
    missing = api("PATCH", path, body={"title": "No precondition"}, headers={"Content-Type": "application/merge-patch+json"})
    expect_problem(missing, 428)
    return "stale If-Match gave 412, missing If-Match gave 428"


def check_cursor_pagination():
    path = f"/v1/projects/{need('project')}/tasks"
    for title in ("Second task", "Third task"):
        expect(api("POST", path, body={"title": title}), 201)
    first = api("GET", f"{path}?limit=2&sort=createdAt")
    expect(first, 200)
    page_one = first.json
    assert len(page_one["items"]) == 2 and page_one["page"]["nextCursor"], f"unexpected first page {page_one['page']}"
    cursor = urllib.parse.quote(page_one["page"]["nextCursor"])
    second = api("GET", f"{path}?limit=2&sort=createdAt&cursor={cursor}")
    expect(second, 200)
    page_two = second.json
    assert len(page_two["items"]) == 1 and page_two["page"]["nextCursor"] is None, f"unexpected second page {page_two['page']}"
    ids = {item["id"] for item in page_one["items"] + page_two["items"]}
    assert len(ids) == 3, "the pages overlap or miss a task"
    return "2 + 1 tasks, no overlap, last page has nextCursor null"


def check_no_token():
    res = api("GET", "/v1/me", who=None)
    expect_problem(res, 401)
    assert res.headers.get("WWW-Authenticate", "").startswith("Bearer"), "WWW-Authenticate is not a Bearer challenge"
    return "401 problem details with a Bearer challenge"


def check_member_forbidden():
    expect_problem(api("GET", "/v1/audit-log", who="bob"), 403)
    expect_problem(api("POST", "/v1/teams", who="bob", body={"name": "Not allowed"}), 403)
    return "bob (member) gets 403 on the audit log and on creating a team"


def check_problem_shape():
    invalid = expect_problem(api("POST", "/v1/teams", body={"name": ""}), 422)
    pointers = [error.get("pointer") for error in invalid.get("errors", [])]
    assert "/name" in pointers, f"errors do not point at /name: {invalid.get('errors')}"
    missing = expect_problem(api("GET", f"/v1/tasks/{uuid.uuid4()}"), 404)
    assert missing["type"].startswith("http"), f"type is not a URI: {missing['type']}"
    return "422 with errors[/name], 404 with type, title and status"


def check_audit_log():
    res = api("GET", f"/v1/audit-log?entityType=task&entityId={need('task')}&limit=20")
    expect(res, 200)
    actions = {item["action"] for item in res.json["items"]}
    assert {"create", "update"} <= actions, f"audit actions are {actions}"
    creates = [item for item in res.json["items"] if item["action"] == "create"]
    assert creates[0]["actorId"] == ALICE_ID, "the create entry does not name alice"
    return "task create and update are in the audit trail"


def check_cleanup():
    team = need("team")
    expect(api("DELETE", f"/v1/teams/{team}"), 204)
    expect_problem(api("GET", f"/v1/teams/{team}"), 404)
    return "team deleted, then 404"


def run(name, check):
    try:
        detail = check()
    except Exception as exc:  # a failed check is reported, the others still run
        print(f"FAIL  {name}: {exc}")
        return False
    print(f"PASS  {name} ({detail})")
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--infra-only", action="store_true", help="skip the API checks (no backend needed)")
    args = parser.parse_args()
    checks = [
        ("keycloak discovery", check_discovery),
        ("token for alice", check_alice_token),
        ("token for bob", check_bob_token),
        ("postgres reachable", check_postgres),
    ]
    if not args.infra_only:
        checks += [
            ("health", check_health),
            ("me", check_me),
            ("create team", check_create_team),
            ("create project", check_create_project),
            ("create task with Idempotency-Key", check_create_task_idempotent),
            ("get task with ETag", check_get_task_etag),
            ("update with If-Match", check_update_if_match),
            ("stale If-Match gives 412", check_stale_if_match),
            ("cursor pagination", check_cursor_pagination),
            ("401 without token", check_no_token),
            ("403 for member on admin route", check_member_forbidden),
            ("problem details shape", check_problem_shape),
            ("audit log", check_audit_log),
            ("cleanup", check_cleanup),
        ]
    results = [run(name, check) for name, check in checks]
    print(f"{sum(results)} passed, {len(results) - sum(results)} failed")
    return 0 if all(results) else 1


if __name__ == "__main__":
    sys.exit(main())
