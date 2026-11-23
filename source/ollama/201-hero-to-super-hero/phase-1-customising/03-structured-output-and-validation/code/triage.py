import json
from pathlib import Path

from ollama_http import post_json, run_cli
from validate import validate

HERE = Path(__file__).resolve().parent
MODEL = "llama3.2:1b"


def build_messages(email, schema):
    system = (
        "You triage customer support emails. Reply with JSON only, matching this schema: "
        + json.dumps(schema)
    )
    return [
        {"role": "system", "content": system},
        {"role": "user", "content": email},
    ]


def triage(email, schema, attempts=2):
    messages = build_messages(email, schema)
    errors = []
    for attempt in range(1, attempts + 1):
        body = {
            "model": MODEL,
            "messages": messages,
            "stream": False,
            "format": schema,
            "options": {"temperature": 0, "num_predict": 200},
        }
        data = post_json("/api/chat", body)
        reply = data["message"]["content"]
        if data.get("done_reason") == "length":
            errors = ["the reply was cut off by num_predict"]
        else:
            try:
                parsed = json.loads(reply)
            except json.JSONDecodeError as error:
                errors = [f"not valid JSON: {error.msg}"]
            else:
                errors = validate(parsed, schema)
                if not errors:
                    return parsed, attempt, []
        messages = messages + [
            {"role": "assistant", "content": reply},
            {"role": "user", "content": "That reply was rejected: " + "; ".join(errors) + ". Reply again with valid JSON only."},
        ]
    return None, attempts, errors


def main():
    schema = json.loads((HERE / "schema.json").read_text(encoding="utf-8"))
    emails = json.loads((HERE / "emails.json").read_text(encoding="utf-8"))
    for email in emails:
        result, attempts, errors = triage(email["text"], schema)
        if result is None:
            print(f"{email['id']}: REJECTED after {attempts} attempts: {errors}")
        else:
            print(f"{email['id']}: accepted on attempt {attempts}: {json.dumps(result)}")


if __name__ == "__main__":
    run_cli(main)
