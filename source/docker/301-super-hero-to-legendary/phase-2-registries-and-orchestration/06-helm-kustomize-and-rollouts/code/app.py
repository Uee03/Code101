import json
import os
import signal
import socket
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

START = time.monotonic()
WARMUP_SECONDS = float(os.environ.get("WARMUP_SECONDS", "5"))
GREETING = os.environ.get("GREETING", "hello")
VERSION = os.environ.get("APP_VERSION", "dev")
TOKEN_FILE = os.environ.get("API_TOKEN_FILE", "")
TOKEN_CONFIGURED = os.path.isfile(TOKEN_FILE) if TOKEN_FILE else False


class Handler(BaseHTTPRequestHandler):
    def send_json(self, status, payload):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/healthz":
            self.send_json(200, {"status": "alive"})
        elif self.path == "/readyz":
            ready = time.monotonic() - START >= WARMUP_SECONDS
            self.send_json(200 if ready else 503, {"ready": ready})
        elif self.path == "/":
            self.send_json(200, {
                "greeting": GREETING,
                "version": VERSION,
                "hostname": socket.gethostname(),
                "token_configured": TOKEN_CONFIGURED,
            })
        else:
            self.send_json(404, {"error": "not found"})


def main():
    server = ThreadingHTTPServer(("0.0.0.0", 8080), Handler)

    def stop(signum, frame):
        threading.Thread(target=server.shutdown, daemon=True).start()

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    print("listening on 8080", flush=True)
    server.serve_forever()
    print("stopped cleanly", flush=True)


if __name__ == "__main__":
    main()
