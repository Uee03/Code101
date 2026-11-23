import unittest

from modelfile_lint import lint

GOOD = """# comment
FROM llama3.2:1b
PARAMETER temperature 0.2
PARAMETER stop "<|eot_id|>"
PARAMETER stop "<|end_header_id|>"
SYSTEM \"\"\"Answer briefly.
Answer with facts.\"\"\"
MESSAGE user Hello
MESSAGE assistant Hi
"""


class LintTests(unittest.TestCase):
    def test_good_file_has_no_problems(self):
        self.assertEqual(lint(GOOD), [])

    def test_missing_from(self):
        self.assertIn("no FROM instruction", lint("PARAMETER temperature 0.2\n"))

    def test_unknown_parameter(self):
        problems = lint("FROM x\nPARAMETER tempature 0.2\n")
        self.assertEqual(problems, ["line 2: unknown parameter 'tempature'"])

    def test_number_expected(self):
        problems = lint("FROM x\nPARAMETER temperature hot\n")
        self.assertEqual(problems, ["line 2: temperature needs a float, got 'hot'"])

    def test_duplicate_parameter(self):
        problems = lint("FROM x\nPARAMETER seed 1\nPARAMETER seed 2\n")
        self.assertEqual(problems, ["line 3: parameter 'seed' is set twice"])

    def test_stop_may_repeat(self):
        self.assertEqual(lint('FROM x\nPARAMETER stop "a"\nPARAMETER stop "b"\n'), [])

    def test_block_text_is_not_read_as_instructions(self):
        text = 'FROM x\nSYSTEM """First line\nAnswer in French\n"""\n'
        self.assertEqual(lint(text), [])

    def test_unterminated_block(self):
        self.assertIn("a triple-quoted block is never closed", lint('FROM x\nSYSTEM """open\n'))

    def test_bad_message_role(self):
        problems = lint("FROM x\nMESSAGE robot Hello\n")
        self.assertEqual(len(problems), 1)
        self.assertTrue(problems[0].startswith("line 2: MESSAGE role"))


if __name__ == "__main__":
    unittest.main()
