import base64
import os
import sys
import urllib.error
import urllib.request

BASE = os.environ.get("PROBE_URL", "http://127.0.0.1:8088")
OPENER = urllib.request.build_opener(urllib.request.ProxyHandler({}))
BURST = 30


def basic_auth_header(user, password):
    token = base64.b64encode(f"{user}:{password}".encode("utf-8")).decode("ascii")
    return {"Authorization": f"Basic {token}"}


def status_of(method, path, headers=None, body=None):
    request = urllib.request.Request(BASE + path, data=body, method=method, headers=headers or {})
    try:
        with OPENER.open(request, timeout=10) as response:
            return response.status
    except urllib.error.HTTPError as error:
        return error.code


def count_status(status, attempts, path, headers):
    return sum(1 for _ in range(attempts) if status_of("GET", path, headers) == status)


def format_check(label, expected, actual):
    return f"{'PASS' if expected == actual else 'FAIL'} {label}: expected {expected}, got {actual}"


def run_checks(user, password):
    good = basic_auth_header(user, password)
    wrong = basic_auth_header(user, password + "x")
    json_headers = {**good, "Content-Type": "application/json"}
    lines = [
        format_check("no credentials", 401, status_of("GET", "/api/version")),
        format_check("wrong password", 401, status_of("GET", "/api/version", wrong)),
        format_check("valid credentials", 200, status_of("GET", "/api/version", good)),
        format_check("blocked endpoint /api/pull", 403, status_of("POST", "/api/pull", json_headers, b'{"model": "x"}')),
        format_check("blocked endpoint /api/tags", 403, status_of("GET", "/api/tags", good)),
    ]
    limited = count_status(429, BURST, "/api/version", good)
    lines.append(f"{'PASS' if limited > 0 else 'FAIL'} rate limit: {limited} of {BURST} rapid requests were answered 429")
    return lines


def main():
    user = os.environ.get("PROBE_USER")
    password = os.environ.get("PROBE_PASSWORD")
    if not user or not password:
        raise SystemExit("set PROBE_USER and PROBE_PASSWORD in the environment first")
    try:
        lines = run_checks(user, password)
    except urllib.error.URLError:
        raise SystemExit(f"cannot reach the proxy at {BASE}: is it running?")
    print("\n".join(lines))
    if any(line.startswith("FAIL") for line in lines):
        sys.exit(1)


if __name__ == "__main__":
    main()
