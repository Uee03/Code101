import unittest

from hosts import extract_hosts


class HostTests(unittest.TestCase):
    def test_hosts_are_collected_in_lower_case(self):
        text = "See https://Docs.Example.org/a and http://evil.example/x?y=1 or https://docs.example.org/b."
        self.assertEqual(extract_hosts(text), {"docs.example.org", "evil.example"})

    def test_no_urls(self):
        self.assertEqual(extract_hosts("no links here"), set())

    def test_a_markdown_image_url_is_found(self):
        self.assertEqual(extract_hosts("![x](https://evil.example/log?d=1)"), {"evil.example"})


if __name__ == "__main__":
    unittest.main()
