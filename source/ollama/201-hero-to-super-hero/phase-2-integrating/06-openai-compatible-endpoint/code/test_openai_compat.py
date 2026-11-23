import unittest

from openai_compat import parse_sse_line


class SseTests(unittest.TestCase):
    def test_data_line_is_decoded(self):
        line = 'data: {"choices":[{"delta":{"content":"Hi"}}]}\n'
        self.assertEqual(parse_sse_line(line), {"choices": [{"delta": {"content": "Hi"}}]})

    def test_done_marker(self):
        self.assertEqual(parse_sse_line("data: [DONE]\n"), "DONE")

    def test_other_lines_are_skipped(self):
        for line in ["\n", ": keep-alive\n", "event: ping\n"]:
            self.assertIsNone(parse_sse_line(line))

    def test_broken_json_is_an_error(self):
        with self.assertRaises(ValueError):
            parse_sse_line("data: {not json}\n")


if __name__ == "__main__":
    unittest.main()
