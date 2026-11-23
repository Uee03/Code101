OPTION_MAP = {
    "temperature": "temperature",
    "num_predict": "max_tokens",
    "top_p": "top_p",
    "seed": "seed",
    "stop": "stop",
}
HANDLED = {"model", "messages", "stream", "options", "format"}


def to_openai(native):
    body = {"model": native["model"], "messages": native["messages"]}
    dropped = []
    if "stream" in native:
        body["stream"] = native["stream"]
    for name, value in native.get("options", {}).items():
        if name in OPTION_MAP:
            body[OPTION_MAP[name]] = value
        else:
            dropped.append("options." + name)
    fmt = native.get("format")
    if fmt == "json":
        body["response_format"] = {"type": "json_object"}
    elif fmt is not None:
        dropped.append("format (schema)")
    for name in native:
        if name not in HANDLED:
            dropped.append(name)
    return body, dropped
