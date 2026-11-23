import os
from pathlib import Path
from http.server import BaseHTTPRequestHandler, HTTPServer


class Page(BaseHTTPRequestHandler):
    def do_GET(self):
        secret_loaded = bool(Path("/run/secrets/demo_token").read_text().strip())
        message = os.environ["GREETING"]
        body = f"{message}; secret-loaded={str(secret_loaded).lower()}\n".encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write(body)


print("Code101 web listening on 8000", flush=True)
HTTPServer(("0.0.0.0", 8000), Page).serve_forever()
