import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer


def writable(directory):
    probe = os.path.join(directory, "probe.txt")
    try:
        with open(probe, "w", encoding="utf-8") as handle:
            handle.write("x")
        os.remove(probe)
        return True
    except OSError:
        return False


def proc_status():
    values = {}
    with open("/proc/self/status", encoding="utf-8") as handle:
        for line in handle:
            key, _, value = line.partition(":")
            values[key] = value.strip()
    return values


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        status = proc_status()
        body = json.dumps({
            "uid": os.getuid(),
            "var_tmp_writable": writable("/var/tmp"),
            "tmp_writable": writable("/tmp"),
            "cap_bounding": status.get("CapBnd"),
            "no_new_privs": status.get("NoNewPrivs"),
            "seccomp": status.get("Seccomp"),
        }).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
