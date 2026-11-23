SEARCH_TASKS_PARAMETERS = {
    "type": "object",
    "properties": {
        "query": {"type": "string", "minLength": 1, "maxLength": 50},
        "limit": {"type": "integer", "minimum": 1, "maximum": 10},
    },
    "required": ["query"],
    "additionalProperties": False,
}
