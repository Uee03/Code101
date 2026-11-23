import json
import sys
import urllib.error
import urllib.request

URL = "http://127.0.0.1:11434/api/chat"
MODEL = "llama3.2:1b"


def read_reply(response, streaming):
    if not streaming:
        data = json.load(response)
        if data.get("error") or data.get("done") is not True:
            raise ValueError("Incomplete reply")
        print(data["message"]["content"])
        return
    finished = False
    for line in response:
        if not line.strip():
            continue
        event = json.loads(line)
        if event.get("error"):
            raise ValueError("Stream error")
        piece = ""  # TODO: read content from this event, allowing a missing message.
        print(piece, end="", flush=True)
        if event.get("done") is True:
            finished = True
            break
    print()
    if not finished:
        raise ValueError("Incomplete stream")


def main():
    if sys.argv[1:] not in ([], ["--stream"]):
        print("Use: chat.py [--stream]")
        return
    streaming = sys.argv[1:] == ["--stream"]
    prompt = input("You (public or invented text only): ").strip()
    if not prompt:
        print("No text sent.")
        return
    if len(prompt) > 600:
        print("Use at most 600 characters.")
        return
    body = {
        "model": MODEL,
        "messages": [{"role": "user", "content": prompt}],
        "stream": streaming,
        "options": {"num_ctx": 2048, "num_predict": 160},
    }
    request = urllib.request.Request(
        URL,
        data=json.dumps(body).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    with opener.open(request, timeout=180) as response:
        read_reply(response, streaming)


if __name__ == "__main__":
    try:
        main()
    except urllib.error.HTTPError as error:
        print(f"Request failed (HTTP {error.code}); check the server and model tag.")
    except (urllib.error.URLError, TimeoutError, OSError):
        print("Connection failed or timed out; check the native Ollama server.")
    except (ValueError, KeyError, TypeError, AttributeError):
        print("Reply incomplete or invalid; discard any partial text.")
    except (EOFError, KeyboardInterrupt):
        print("\nCancelled.")
