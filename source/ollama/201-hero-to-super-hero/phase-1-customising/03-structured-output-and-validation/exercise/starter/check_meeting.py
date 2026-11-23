from validate import validate

SCHEMA = {
    "type": "object",
    "properties": {
        "title": {"type": "string", "minLength": 3},
        # TODO 1: add "attendees": an array of strings with at least one item
        # TODO 2: add "duration_minutes": an integer from 5 to 480
    },
    # TODO 3: make all three properties required
    # TODO 4: reject properties that are not listed
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
