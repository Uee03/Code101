import json
import socket
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer


def resolves(name):
    try:
        socket.gethostbyname(name)
        return True
    except socket.gaierror:
        return False


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        body = json.dumps({"service": "api", "db_resolves": resolves("db")}) + "\n"
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(body.encode())


if len(sys.argv) == 3 and sys.argv[1] == "--check":
    name = sys.argv[2]
    print(name + (" resolves" if resolves(name) else " does not resolve"))
else:
    HTTPServer(("0.0.0.0", 8000), Handler).serve_forever()
