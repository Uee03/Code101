from http.server import BaseHTTPRequestHandler, HTTPServer


class Page(BaseHTTPRequestHandler):
    def do_GET(self):
        body = b"Hello from the bakery!\n"
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write(body)


print("Code101 web listening on 8000", flush=True)
HTTPServer(("0.0.0.0", 8000), Page).serve_forever()
