import unittest

from translate import to_openai

MESSAGES = [{"role": "user", "content": "Hi"}]


class TranslateTests(unittest.TestCase):
    def test_options_are_renamed(self):
        native = {"model": "m", "messages": MESSAGES, "options": {"temperature": 0.1, "num_predict": 50}}
        body, dropped = to_openai(native)
        self.assertEqual(body["temperature"], 0.1)
        self.assertEqual(body["max_tokens"], 50)
        self.assertEqual(dropped, [])

    def test_unmapped_fields_are_reported(self):
        native = {"model": "m", "messages": MESSAGES, "keep_alive": "10m", "options": {"num_ctx": 8192}}
        body, dropped = to_openai(native)
        self.assertNotIn("keep_alive", body)
        self.assertEqual(dropped, ["options.num_ctx", "keep_alive"])

    def test_json_format(self):
        body, dropped = to_openai({"model": "m", "messages": MESSAGES, "format": "json", "stream": False})
        self.assertEqual(body["response_format"], {"type": "json_object"})
        self.assertIs(body["stream"], False)
        self.assertEqual(dropped, [])

    def test_schema_format_is_reported(self):
        body, dropped = to_openai({"model": "m", "messages": MESSAGES, "format": {"type": "object"}})
        self.assertNotIn("response_format", body)
        self.assertEqual(dropped, ["format (schema)"])


if __name__ == "__main__":
    unittest.main()
