import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer


def read_secret(name):
    path = os.environ[name + "_FILE"]
    with open(path) as handle:
        return handle.read().strip()


def load_config():
    with open(os.environ["APP_CONFIG_FILE"]) as handle:
        return json.load(handle)


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        password = read_secret("DB_PASSWORD")
        body = json.dumps({
            "greeting": os.environ["GREETING"],
            "config": load_config(),
            "secret_length": len(password),
        }) + "\n"
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(body.encode())


HTTPServer(("0.0.0.0", 8000), Handler).serve_forever()
