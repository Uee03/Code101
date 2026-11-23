import unittest
from unittest import mock

import probe


class ProbeTests(unittest.TestCase):
    def test_basic_auth_header(self):
        self.assertEqual(probe.basic_auth_header("alice", "secret"), {"Authorization": "Basic YWxpY2U6c2VjcmV0"})

    def test_format_check(self):
        self.assertEqual(probe.format_check("x", 401, 401), "PASS x: expected 401, got 401")
        self.assertEqual(probe.format_check("x", 401, 200), "FAIL x: expected 401, got 200")

    def test_count_status(self):
        with mock.patch.object(probe, "status_of", side_effect=[429, 200, 429]):
            self.assertEqual(probe.count_status(429, 3, "/api/version", {}), 2)


if __name__ == "__main__":
    unittest.main()
