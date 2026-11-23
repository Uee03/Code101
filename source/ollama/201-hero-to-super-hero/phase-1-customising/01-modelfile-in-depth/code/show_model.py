import argparse

from ollama_http import post_json, run_cli

DEFAULT_MODEL = "code101-reviewer:local"


def show(model):
    info = post_json("/api/show", {"model": model}, timeout=30)
    print(f"model: {model}")
    print("parameters:")
    print(info.get("parameters") or "(none)")
    print("system:", info.get("system") or "(none)")
    print("template set:", bool(info.get("template")))


def ask(model, prompt, temperature):
    body = {
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        "stream": False,
    }
    if temperature is not None:
        body["options"] = {"temperature": temperature}
    data = post_json("/api/chat", body, timeout=180)
    print(data["message"]["content"])
    print(f"done_reason: {data.get('done_reason')}  tokens: {data.get('eval_count')}")


def main():
    parser = argparse.ArgumentParser(description="Inspect and ask a custom model.")
    parser.add_argument("action", choices=["show", "ask"])
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--prompt", default="Review: for i in range(10): total += i")
    parser.add_argument("--temperature", type=float, default=None)
    args = parser.parse_args()
    if args.action == "show":
        show(args.model)
    else:
        ask(args.model, args.prompt, args.temperature)


if __name__ == "__main__":
    run_cli(main)
