import unittest
from pathlib import Path
import json

from validate import validate

SCHEMA = {
    "type": "object",
    "properties": {
        "name": {"type": "string", "minLength": 2, "maxLength": 5},
        "age": {"type": "integer", "minimum": 0, "maximum": 150},
        "tags": {"type": "array", "items": {"type": "string"}, "maxItems": 2},
        "kind": {"type": "string", "enum": ["a", "b"]},
    },
    "required": ["name", "age"],
    "additionalProperties": False,
}


class ValidateTests(unittest.TestCase):
    def test_valid_document(self):
        document = {"name": "Ada", "age": 36, "tags": ["x"], "kind": "a"}
        self.assertEqual(validate(document, SCHEMA), [])

    def test_missing_required(self):
        self.assertEqual(validate({"name": "Ada"}, SCHEMA), ["$: missing required property 'age'"])

    def test_wrong_type(self):
        self.assertEqual(validate({"name": 5, "age": 3}, SCHEMA), ["$.name: expected string, got int"])

    def test_bool_is_not_an_integer(self):
        self.assertEqual(validate({"name": "Ada", "age": True}, SCHEMA), ["$.age: expected integer, got bool"])

    def test_enum(self):
        errors = validate({"name": "Ada", "age": 1, "kind": "z"}, SCHEMA)
        self.assertEqual(errors, ["$.kind: 'z' is not one of ['a', 'b']"])

    def test_extra_property(self):
        self.assertEqual(validate({"name": "Ada", "age": 1, "x": 1}, SCHEMA), ["$: unexpected property 'x'"])

    def test_string_lengths(self):
        self.assertEqual(validate({"name": "A", "age": 1}, SCHEMA), ["$.name: shorter than 2 characters"])
        self.assertEqual(validate({"name": "Adalovelace", "age": 1}, SCHEMA), ["$.name: longer than 5 characters"])

    def test_number_range(self):
        self.assertEqual(validate({"name": "Ada", "age": 200}, SCHEMA), ["$.age: 200 is above the maximum 150"])

    def test_arrays(self):
        self.assertEqual(validate({"name": "Ada", "age": 1, "tags": ["a", "b", "c"]}, SCHEMA), ["$.tags: more than 2 items"])
        self.assertEqual(validate({"name": "Ada", "age": 1, "tags": [1]}, SCHEMA), ["$.tags[0]: expected string, got int"])

    def test_unsupported_type_raises(self):
        with self.assertRaises(ValueError):
            validate(1, {"type": "date"})

    def test_ticket_schema_accepts_a_good_ticket(self):
        schema = json.loads(Path(__file__).with_name("schema.json").read_text(encoding="utf-8"))
        ticket = {"category": "billing", "priority": "high", "summary": "Charged twice for March", "needs_human": True}
        self.assertEqual(validate(ticket, schema), [])


if __name__ == "__main__":
    unittest.main()
