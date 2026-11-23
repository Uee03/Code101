import json
import os
import sys
import urllib.error
import urllib.request

BASE = os.environ.get("RAG_URL", "http://127.0.0.1:8090")
OPENER = urllib.request.build_opener(urllib.request.ProxyHandler({}))
DEFAULT_QUESTION = "Which host port does Keycloak use in the platform stack?"


def ask(payload, token=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = "Bearer " + token
    request = urllib.request.Request(BASE + "/ask", data=json.dumps(payload).encode("utf-8"), headers=headers, method="POST")
    try:
        with OPENER.open(request, timeout=300) as response:
            return response.status, json.load(response)
    except urllib.error.HTTPError as error:
        return error.code, json.loads(error.read().decode("utf-8"))


def main():
    token = os.environ.get("RAG_API_TOKEN")
    if not token:
        raise SystemExit("set RAG_API_TOKEN in the environment first")
    question = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_QUESTION
    try:
        print("no token  ->", ask({"question": question})[0])
        print("bad body  ->", ask({"question": "hi"}, token)[0])
        status, body = ask({"question": question}, token)
    except urllib.error.URLError:
        raise SystemExit(f"cannot reach the service at {BASE}: is it running?")
    print("question  ->", status)
    print("status:", body.get("status"))
    print("answer:", body.get("answer"))
    for citation in body.get("citations", []):
        print(f"[{citation['n']}] {citation['source']} / {citation['section'] or '-'}")


if __name__ == "__main__":
    main()
