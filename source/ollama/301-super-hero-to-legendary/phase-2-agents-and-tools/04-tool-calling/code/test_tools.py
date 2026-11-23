import unittest
from unittest import mock

import tools


class ToolTests(unittest.TestCase):
    def setUp(self):
        tools.PROPOSALS.clear()

    def test_list_teams(self):
        self.assertEqual(tools.run_tool("list_teams", {}), '[{"id": "t1", "name": "Platform"}, {"id": "t2", "name": "Design"}]')

    def test_count_tasks(self):
        self.assertEqual(tools.run_tool("count_tasks", {"team_id": "t1", "status": "open"}), "2")
        self.assertEqual(tools.run_tool("count_tasks", {"team_id": "t1", "status": "done"}), "1")
        self.assertEqual(tools.run_tool("count_tasks", {"team_id": "t2", "status": "open"}), "1")

    def test_arguments_may_arrive_as_a_json_string(self):
        self.assertEqual(tools.run_tool("count_tasks", '{"team_id": "t2", "status": "open"}'), "1")

    def test_unknown_tool(self):
        self.assertEqual(tools.run_tool("delete_everything", {}), "ERROR: unknown tool")
        self.assertEqual(tools.run_tool(["list_teams"], {}), "ERROR: unknown tool")

    def test_invalid_arguments_are_explained(self):
        self.assertEqual(
            tools.run_tool("count_tasks", {"team_id": "t1", "status": "closed"}),
            "ERROR: invalid arguments: $.status: 'closed' is not one of ['open', 'done']",
        )
        self.assertEqual(
            tools.run_tool("count_tasks", {"team_id": "t1"}),
            "ERROR: invalid arguments: $: missing required property 'status'",
        )
        self.assertEqual(tools.run_tool("list_teams", {"x": 1}), "ERROR: invalid arguments: $: unexpected property 'x'")

    def test_bad_argument_containers(self):
        self.assertEqual(tools.run_tool("list_teams", "{not json"), "ERROR: arguments are not valid JSON")
        self.assertEqual(tools.run_tool("list_teams", [1]), "ERROR: arguments must be an object")

    def test_long_results_are_truncated(self):
        with mock.patch.object(tools, "MAX_RESULT_CHARS", 10):
            result = tools.run_tool("list_teams", {})
        self.assertEqual(len(result), 10 + len("...[truncated]"))
        self.assertTrue(result.endswith("...[truncated]"))

    def test_a_failing_tool_does_not_crash_the_loop(self):
        def boom(task_id):
            raise RuntimeError("secret internal detail")

        with mock.patch.dict(tools.TOOLS["get_task"], {"function": boom}):
            result = tools.run_tool("get_task", {"task_id": "k1"})
        self.assertEqual(result, "ERROR: the tool failed (RuntimeError)")

    def test_proposing_a_close_changes_nothing(self):
        before = {task_id: dict(task) for task_id, task in tools.TASKS.items()}
        result = tools.run_tool("propose_close_task", {"task_id": "k1"})
        self.assertIn('"executed": false', result)
        self.assertEqual(tools.TASKS, before)
        self.assertEqual(tools.PROPOSALS, ["k1"])

    def test_schemas_do_not_leak_the_python_functions(self):
        for schema in tools.tool_schemas():
            self.assertEqual(schema["type"], "function")
            self.assertEqual(set(schema["function"]), {"name", "description", "parameters"})


if __name__ == "__main__":
    unittest.main()
