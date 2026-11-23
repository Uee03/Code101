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
    # TODO 1: copy "stream" into body when the native request has it
    # TODO 2: for every name and value in native.get("options", {}):
    #         when the name is in OPTION_MAP, store the value in body under the mapped name,
    #         otherwise append "options." + name to dropped
    # TODO 3: when native["format"] is the string "json", set body["response_format"] to {"type": "json_object"};
    #         for any other format value append "format (schema)" to dropped
    # TODO 4: for every top-level name in native that is not in HANDLED, append the name to dropped
    return body, dropped
