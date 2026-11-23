import argparse
import json
import urllib.request

from ollama_http import BASE_URL, get_json, post_json, run_cli

_OPENER = urllib.request.build_opener(urllib.request.ProxyHandler({}))


def parse_sse_line(line):
    """Return the decoded event, the string DONE for the end marker, or None for lines to skip."""
    line = line.strip()
    if not line.startswith("data:"):
        return None
    payload = line[len("data:"):].strip()
    if payload == "[DONE]":
        return "DONE"
    return json.loads(payload)


def stream_events(path, body, timeout=180):
    request = urllib.request.Request(
        BASE_URL + path,
        data=json.dumps(body).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with _OPENER.open(request, timeout=timeout) as response:
        for raw in response:
            event = parse_sse_line(raw.decode("utf-8"))
            if event == "DONE":
                return
            if event is not None:
                yield event


def chat_body(model, prompt):
    return {
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.2,
        "max_tokens": 200,
    }


def chat_once(model, prompt):
    data = post_json("/v1/chat/completions", chat_body(model, prompt))
    choice = data["choices"][0]
    return choice["message"]["content"], choice.get("finish_reason"), data.get("usage", {})


def chat_stream(model, prompt):
    body = {**chat_body(model, prompt), "stream": True}
    for event in stream_events("/v1/chat/completions", body):
        choices = event.get("choices") or []
        if choices:
            yield choices[0].get("delta", {}).get("content") or "", choices[0].get("finish_reason")


def json_mode(model, prompt):
    body = {**chat_body(model, prompt), "response_format": {"type": "json_object"}}
    data = post_json("/v1/chat/completions", body)
    return json.loads(data["choices"][0]["message"]["content"])


def embed(model, texts):
    data = post_json("/v1/embeddings", {"model": model, "input": texts})
    ordered = sorted(data["data"], key=lambda item: item["index"])
    return [item["embedding"] for item in ordered]


def list_models():
    return [item["id"] for item in get_json("/v1/models")["data"]]


def main():
    parser = argparse.ArgumentParser(description="Try the OpenAI-compatible endpoint with the standard library.")
    parser.add_argument("action", choices=["models", "chat", "stream", "json", "embed"])
    parser.add_argument("--model", default=None)
    parser.add_argument("--prompt", default="Name two uses of an HTTP timeout.")
    args = parser.parse_args()
    if args.action == "models":
        for name in list_models():
            print(name)
    elif args.action == "chat":
        text, reason, usage = chat_once(args.model or "llama3.2:1b", args.prompt)
        print(text)
        print(f"finish_reason={reason} usage={usage}")
    elif args.action == "stream":
        for piece, reason in chat_stream(args.model or "llama3.2:1b", args.prompt):
            print(piece, end="", flush=True)
            if reason:
                print(f"\nfinish_reason={reason}")
    elif args.action == "json":
        prompt = "Reply as JSON with the keys city and country for the capital of France."
        print(json.dumps(json_mode(args.model or "llama3.2:1b", prompt)))
    else:
        vectors = embed(args.model or "nomic-embed-text:v1.5", [args.prompt])
        print(f"vectors: {len(vectors)}, dimensions: {len(vectors[0])}")


if __name__ == "__main__":
    run_cli(main)
