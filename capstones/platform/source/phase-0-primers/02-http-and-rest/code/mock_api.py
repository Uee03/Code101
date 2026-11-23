"""A tiny stand-in for the Tasks and Teams API. Standard library only. Practice use only."""
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PROJECT_ID = "9a000000-0000-4000-8000-000000000001"
TASK_ID = "7a500000-0000-4000-8000-000000000003"
NEW_TASK_ID = "7a500000-0000-4000-8000-0000000000aa"
TASK = {
    "id": TASK_ID,
    "projectId": PROJECT_ID,
    "title": "Configure Keycloak",
    "description": "Realm, clients, roles and users.",
    "status": "in_progress",
    "priority": "urgent",
    "assigneeId": "ca401000-0000-4000-8000-000000000003",
    "dueDate": "2027-02-05",
    "completedAt": None,
    "createdBy": "a11ce000-0000-4000-8000-000000000001",
    "version": 1,
    "createdAt": "2026-11-23T08:00:00Z",
    "updatedAt": "2026-11-23T08:00:00Z",
}


class Handler(BaseHTTPRequestHandler):
    def send(self, status, body, content_type="application/json", extra=None):
        data = json.dumps(body).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        for name, value in (extra or {}).items():
            self.send_header(name, value)
        self.end_headers()
        self.wfile.write(data)

    def problem(self, status, title, detail):
        self.send(status, {
            "type": "https://code101.example/problems/" + title.lower().replace(" ", "-"),
            "title": title,
            "status": status,
            "detail": detail,
            "instance": self.path,
        }, "application/problem+json")

    def signed_in(self):
        return self.headers.get("Authorization", "").startswith("Bearer ")

    def do_GET(self):
        if self.path == "/health":
            self.send(200, {"status": "ok", "version": "1.0.0", "database": "up"})
        elif self.path.startswith("/v1/tasks/"):
            if not self.signed_in():
                self.problem(401, "Unauthorized", "A bearer access token is required.")
            elif self.path == "/v1/tasks/" + TASK_ID:
                self.send(200, TASK, extra={"ETag": '"1"'})
            else:
                self.problem(404, "Not Found", "No such task.")
        else:
            self.problem(404, "Not Found", "No such path.")

    def do_POST(self):
        if self.path != "/v1/projects/" + PROJECT_ID + "/tasks":
            self.problem(404, "Not Found", "No such path.")
            return
        if not self.signed_in():
            self.problem(401, "Unauthorized", "A bearer access token is required.")
            return
        length = int(self.headers.get("Content-Length", 0))
        try:
            body = json.loads(self.rfile.read(length) or b"{}")
        except json.JSONDecodeError:
            self.problem(400, "Bad Request", "The body is not valid JSON.")
            return
        title = body.get("title") if isinstance(body, dict) else None
        if not isinstance(title, str) or not 1 <= len(title) <= 200:
            self.problem(422, "Validation failed", "The title must be 1 to 200 characters.")
            return
        created = dict(
            TASK,
            id=NEW_TASK_ID,
            title=title,
            description=body.get("description", ""),
            status="todo",
            priority=body.get("priority", "medium"),
            assigneeId=None,
            dueDate=None,
        )
        self.send(201, created, extra={
            "Location": "http://localhost:8000/v1/tasks/" + NEW_TASK_ID,
            "ETag": '"1"',
        })


if __name__ == "__main__":
    server = ThreadingHTTPServer(("127.0.0.1", 8000), Handler)
    print("Stand-in API on http://localhost:8000 (press Ctrl+C to stop)")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("Stopped")
