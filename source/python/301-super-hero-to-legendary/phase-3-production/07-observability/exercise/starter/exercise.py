SENSITIVE_KEYS = {"authorization", "password", "token", "secret", "api_key"}


def redact_fields(fields: dict) -> dict:
    # TODO 1: return a NEW dict; do not change the input
    # TODO 2: replace the value of a sensitive key (compare in lower case) with "[redacted]"
    # TODO 3: when a value is itself a dict, redact inside it with the same function
    raise NotImplementedError


if __name__ == "__main__":
    original = {"task_id": 7, "Password": "hunter2", "nested": {"token": "abc", "ok": 1}}
    print(redact_fields(original))
    print("input unchanged:", original["Password"] == "hunter2")
