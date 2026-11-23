import json
from http.server import BaseHTTPRequestHandler, HTTPServer


def greeting(name):
    return "Hello, " + name + "!"


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        body = json.dumps({"message": greeting("dev loop")}) + "\n"
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(body.encode())


def main():
    HTTPServer(("0.0.0.0", 8000), Handler).serve_forever()


if __name__ == "__main__":
    main()
