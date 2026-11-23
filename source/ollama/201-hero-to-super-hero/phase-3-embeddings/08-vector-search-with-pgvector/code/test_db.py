import unittest

from db import parse_env, to_vector_literal


class DbHelperTests(unittest.TestCase):
    def test_parse_env_skips_comments_and_bad_lines(self):
        text = "# comment\nA=1\n\nB = two words \nnot a setting\n"
        self.assertEqual(parse_env(text), {"A": "1", "B": "two words"})

    def test_vector_literal(self):
        self.assertEqual(to_vector_literal([1, 2.5, -3], dimensions=3), "[1.0,2.5,-3.0]")

    def test_wrong_dimension_is_rejected(self):
        with self.assertRaises(ValueError):
            to_vector_literal([1.0, 2.0], dimensions=3)

    def test_not_a_number_is_rejected(self):
        with self.assertRaises(ValueError):
            to_vector_literal([1.0, float("nan")], dimensions=2)


if __name__ == "__main__":
    unittest.main()
