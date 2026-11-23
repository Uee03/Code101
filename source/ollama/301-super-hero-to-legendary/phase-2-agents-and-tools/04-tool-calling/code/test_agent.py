import unittest

import agent
import tools


def call(name, arguments):
    return {"function": {"name": name, "arguments": arguments}}


def scripted(replies):
    seen = []
    queue = list(replies)

    def chat(messages):
        seen.append(list(messages))
        return queue.pop(0)

    return chat, seen


class AgentLoopTests(unittest.TestCase):
    def setUp(self):
        tools.PROPOSALS.clear()

    def test_a_tool_result_is_sent_back_and_the_final_text_is_returned(self):
        chat, seen = scripted([
            {"role": "assistant", "content": "", "tool_calls": [call("count_tasks", {"team_id": "t1", "status": "open"})]},
            {"role": "assistant", "content": "Platform has 2 open tasks."},
        ])
        text, trace = agent.run_agent("How many open tasks has t1?", chat)
        self.assertEqual(text, "Platform has 2 open tasks.")
        self.assertEqual(trace, [("count_tasks", {"team_id": "t1", "status": "open"}, "2")])
        self.assertEqual(seen[1][-1], {"role": "tool", "tool_name": "count_tasks", "content": "2"})

    def test_the_step_limit_stops_a_loop(self):
        looping = {"role": "assistant", "content": "", "tool_calls": [call("list_teams", {})]}
        chat, _ = scripted([looping, looping, looping])
        text, trace = agent.run_agent("Keep going", chat, max_steps=2)
        self.assertEqual(text, "I could not finish within the step limit.")
        self.assertEqual(len(trace), 2)

    def test_too_many_calls_in_one_step_are_cut(self):
        many = {"role": "assistant", "content": "", "tool_calls": [call("list_teams", {})] * 5}
        chat, _ = scripted([many, {"role": "assistant", "content": "done"}])
        text, trace = agent.run_agent("Many calls", chat)
        self.assertEqual(text, "done")
        self.assertEqual(len(trace), agent.MAX_CALLS_PER_STEP)

    def test_an_unknown_tool_is_reported_to_the_model_not_executed(self):
        chat, seen = scripted([
            {"role": "assistant", "content": "", "tool_calls": [call("format_disk", {})]},
            {"role": "assistant", "content": "I cannot do that."},
        ])
        text, trace = agent.run_agent("Do something dangerous", chat)
        self.assertEqual(trace[0][2], "ERROR: unknown tool")
        self.assertEqual(seen[1][-1]["content"], "ERROR: unknown tool")

    def test_a_direct_answer_needs_no_tool(self):
        chat, _ = scripted([{"role": "assistant", "content": "Hello!"}])
        text, trace = agent.run_agent("Hi", chat)
        self.assertEqual((text, trace), ("Hello!", []))


class ToolSelectionTests(unittest.TestCase):
    def test_selected_tool(self):
        self.assertEqual(agent.selected_tool({"tool_calls": [call("get_task", {"task_id": "k1"})]}), "get_task")
        self.assertIsNone(agent.selected_tool({"content": "no tool"}))

    def test_score_eval_counts_matches(self):
        def always_list_teams(messages):
            return {"role": "assistant", "content": "", "tool_calls": [call("list_teams", {})]}

        results = agent.run_eval(always_list_teams)
        self.assertEqual(agent.score_eval(results), (1, 6))


if __name__ == "__main__":
    unittest.main()
