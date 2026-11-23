import unittest

from search_schema import SEARCH_TASKS_PARAMETERS
from validate import validate


class SearchSchemaTests(unittest.TestCase):
    def test_valid_arguments(self):
        self.assertEqual(validate({"query": "login", "limit": 5}, SEARCH_TASKS_PARAMETERS), [])
        self.assertEqual(validate({"query": "login"}, SEARCH_TASKS_PARAMETERS), [])

    def test_limit_is_bounded(self):
        self.assertEqual(
            validate({"query": "login", "limit": 50}, SEARCH_TASKS_PARAMETERS),
            ["$.limit: 50 is above the maximum 10"],
        )

    def test_query_must_not_be_empty_or_missing(self):
        self.assertEqual(validate({"query": ""}, SEARCH_TASKS_PARAMETERS), ["$.query: shorter than 1 characters"])
        self.assertEqual(validate({}, SEARCH_TASKS_PARAMETERS), ["$: missing required property 'query'"])

    def test_unknown_properties_are_rejected(self):
        self.assertEqual(
            validate({"query": "login", "sql": "DROP TABLE tasks"}, SEARCH_TASKS_PARAMETERS),
            ["$: unexpected property 'sql'"],
        )


if __name__ == "__main__":
    unittest.main()
