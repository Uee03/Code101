import json
import os
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer


def can_write(folder):
    path = os.path.join(folder, "probe.txt")
    try:
        with open(path, "w") as handle:
            handle.write("x")
        os.remove(path)
        return True
    except OSError:
        return False


def report():
    return {
        "uid": os.getuid(),
        "gid": os.getgid(),
        "write_app": can_write("/app"),
        "write_data": can_write("/data"),
        "write_tmp": can_write("/tmp"),
    }


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        body = (json.dumps(report()) + "\n").encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(body)


if "--once" in sys.argv:
    print(json.dumps(report()))
else:
    HTTPServer(("0.0.0.0", 8000), Handler).serve_forever()
