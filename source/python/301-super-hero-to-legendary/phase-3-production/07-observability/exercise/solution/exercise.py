SENSITIVE_KEYS = {"authorization", "password", "token", "secret", "api_key"}


def redact_fields(fields: dict) -> dict:
    cleaned = {}
    for key, value in fields.items():
        if key.lower() in SENSITIVE_KEYS:
            cleaned[key] = "[redacted]"
        elif isinstance(value, dict):
            cleaned[key] = redact_fields(value)
        else:
            cleaned[key] = value
    return cleaned


if __name__ == "__main__":
    original = {"task_id": 7, "Password": "hunter2", "nested": {"token": "abc", "ok": 1}}
    print(redact_fields(original))
    print("input unchanged:", original["Password"] == "hunter2")
