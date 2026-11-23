import json
import urllib.error
import urllib.request

MODEL = "code101-study:local"
MAX_TURNS = 4
MAX_CHARS = 600


def reply(messages):
    body = {"model": MODEL, "messages": messages, "stream": False}
    request = urllib.request.Request(
        "http://127.0.0.1:11434/api/chat",
        data=json.dumps(body).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    with opener.open(request, timeout=180) as response:
        data = json.load(response)
    if data.get("error") or data.get("done") is not True:
        raise ValueError("Incomplete reply")
    content = data["message"]["content"]
    if not isinstance(content, str) or not content.strip():
        raise ValueError("Empty reply")
    return content


def main():
    history = []
    print("Study helper: /reset clears memory; /bye exits. Public or invented text only.")
    while True:
        text = input("You: ").strip()
        if text == "/bye":
            print("Goodbye. Session memory released.")
            return
        if text == "/reset":
            history.clear()
            print("Conversation memory cleared.")
            continue
        if not text:
            continue
        if len(text) > MAX_CHARS:
            print(f"Use at most {MAX_CHARS} characters; nothing sent.")
            continue
        keep = 2 * (MAX_TURNS - 1)
        recent = history[-keep:] if keep else []
        pending = recent + [{"role": "user", "content": text}]
        try:
            answer = reply(pending)
        except urllib.error.HTTPError as error:
            print(f"Request failed (HTTP {error.code}); history unchanged.")
            continue
        except (urllib.error.URLError, TimeoutError, OSError):
            print("Connection failed or timed out; history unchanged.")
            continue
        except (ValueError, KeyError, TypeError, AttributeError):
            print("Invalid reply; history unchanged.")
            continue
        print("Assistant:", answer)
        history = pending + [{"role": "assistant", "content": answer}]


if __name__ == "__main__":
    try:
        main()
    except (EOFError, KeyboardInterrupt):
        print("\nSession ended. Memory is not saved to a file.")
