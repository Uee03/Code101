from validate import validate

SCHEMA = {
    "type": "object",
    "properties": {
        "title": {"type": "string", "minLength": 3},
        "attendees": {"type": "array", "items": {"type": "string"}, "minItems": 1},
        "duration_minutes": {"type": "integer", "minimum": 5, "maximum": 480},
    },
    "required": ["title", "attendees", "duration_minutes"],
    "additionalProperties": False,
}

SAMPLES = [
    ("good", {"title": "Planning", "attendees": ["Ada", "Lin"], "duration_minutes": 30}, True),
    ("no attendees", {"title": "Planning", "attendees": [], "duration_minutes": 30}, False),
    ("too long", {"title": "Planning", "attendees": ["Ada"], "duration_minutes": 900}, False),
]


def main():
    for name, document, should_pass in SAMPLES:
        errors = validate(document, SCHEMA)
        ok = (not errors) == should_pass
        print(f"{'PASS' if ok else 'FAIL'}: {name} {errors}")


if __name__ == "__main__":
    main()
