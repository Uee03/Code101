import json
import urllib.error
import urllib.request
from pathlib import Path


def main():
    path = Path(__file__).with_name("request.json")
    body = json.loads(path.read_text(encoding="utf-8"))
    request = urllib.request.Request(
        "http://127.0.0.1:11434/api/chat",
        data=json.dumps(body).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    with opener.open(request, timeout=180) as response:
        envelope = json.load(response)
    if envelope.get("error") or envelope.get("done") is not True:
        raise ValueError("Incomplete reply")
    result = json.loads(envelope["message"]["content"])
    if not isinstance(result, dict) or set(result) != {"kind", "text"}:
        raise ValueError("Wrong fields")
    if result["kind"] not in ("note", "question"):
        raise ValueError("Wrong kind")
    if not isinstance(result["text"], str) or not 1 <= len(result["text"]) <= 160:
        raise ValueError("Wrong text")
    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    try:
        main()
    except urllib.error.HTTPError as error:
        print(f"Request failed (HTTP {error.code}); check the model and request.")
    except (urllib.error.URLError, TimeoutError, OSError):
        print("Connection or file access failed; check Ollama and request.json.")
    except (ValueError, KeyError, TypeError, AttributeError):
        print("Invalid request or reply; no result accepted.")
    except KeyboardInterrupt:
        print("\nCancelled.")
