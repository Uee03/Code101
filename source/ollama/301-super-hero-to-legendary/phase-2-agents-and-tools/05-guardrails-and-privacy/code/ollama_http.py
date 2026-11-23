import json
import sys
import urllib.error
import urllib.request

BASE_URL = "http://127.0.0.1:11434"
_OPENER = urllib.request.build_opener(urllib.request.ProxyHandler({}))


def _request(path, body):
    data = None if body is None else json.dumps(body).encode("utf-8")
    return urllib.request.Request(
        BASE_URL + path,
        data=data,
        headers={"Content-Type": "application/json"},
        method="GET" if body is None else "POST",
    )


def post_json(path, body, timeout=180):
    with _OPENER.open(_request(path, body), timeout=timeout) as response:
        return json.load(response)


def get_json(path, timeout=10):
    return post_json(path, None, timeout)


def post_stream(path, body, timeout=180):
    with _OPENER.open(_request(path, body), timeout=timeout) as response:
        for raw in response:
            line = raw.decode("utf-8").strip()
            if line:
                yield json.loads(line)


def describe_error(error):
    if isinstance(error, urllib.error.HTTPError):
        return f"HTTP {error.code} from Ollama: check the model name and the request body."
    return "Cannot reach Ollama on 127.0.0.1:11434 (not running, or it timed out)."


def run_cli(main):
    try:
        main()
    except (urllib.error.URLError, TimeoutError, ConnectionError) as error:
        print(describe_error(error), file=sys.stderr)
        raise SystemExit(1)
