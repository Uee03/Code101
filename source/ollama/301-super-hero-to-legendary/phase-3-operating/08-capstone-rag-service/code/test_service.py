import http.client
import json
import threading
import time
import unittest
import urllib.error
import urllib.request

import service
from rag_core import REFUSAL, Hit

TOKEN = "t" * 32
HIT = Hit(1, "README.md", "Host ports", "Keycloak is published on 127.0.0.1 port 8180.", 0.9)
OTHER = Hit(2, "TDD.md", "Stack", "Keycloak 26.8.2 on 8180.", 0.8)
OPENER = urllib.request.build_opener(urllib.request.ProxyHandler({}))


def answered(question):
    return {"answer": "Keycloak uses port 8180 [1].", "status": "answered", "sources": [HIT, OTHER], "problems": []}


class ConfigTests(unittest.TestCase):
    def test_a_short_token_is_refused(self):
        with self.assertRaises(RuntimeError):
            service.load_config({"RAG_API_TOKEN": "short"})

    def test_defaults_and_port_range(self):
        config = service.load_config({"RAG_API_TOKEN": TOKEN})
        self.assertEqual(config["port"], 8090)
        self.assertEqual(len(config["log_key"]), 32)
        with self.assertRaises(RuntimeError):
            service.load_config({"RAG_API_TOKEN": TOKEN, "RAG_PORT": "80"})


class SmallPartsTests(unittest.TestCase):
    def test_token_check(self):
        self.assertTrue(service.token_ok("Bearer " + TOKEN, TOKEN))
        self.assertFalse(service.token_ok("Bearer wrong", TOKEN))
        self.assertFalse(service.token_ok("Basic " + TOKEN, TOKEN))
        self.assertFalse(service.token_ok(None, TOKEN))

    def test_rate_limiter_window(self):
        now = [0.0]
        limiter = service.RateLimiter(2, 60, clock=lambda: now[0])
        self.assertTrue(limiter.allow("k"))
        self.assertTrue(limiter.allow("k"))
        self.assertFalse(limiter.allow("k"))
        now[0] = 61.0
        self.assertTrue(limiter.allow("k"))

    def test_the_server_refuses_to_bind_outside_loopback(self):
        with self.assertRaises(ValueError):
            service.make_server("0.0.0.0", 0, TOKEN, answered)


class HandleQuestionTests(unittest.TestCase):
    def run_with(self, reply, canary="CANARY-abc"):
        seen = []

        def generate(messages):
            seen.extend(messages)
            return reply

        result = service.handle_question("Which port does Keycloak use?", lambda question: [HIT, OTHER], generate, canary)
        return result, seen

    def test_a_good_answer_passes(self):
        result, seen = self.run_with("Port 8180 [1].")
        self.assertEqual(result["status"], "answered")
        self.assertIn("<<<SOURCES ", seen[1]["content"])
        self.assertIn("CANARY-abc", seen[0]["content"])

    def test_a_markdown_image_is_blocked(self):
        result, _ = self.run_with("Port 8180 [1]. ![x](https://evil.example/?d=1)")
        self.assertEqual(result["status"], "blocked_by_output_guard")
        self.assertEqual(result["answer"], REFUSAL)

    def test_a_leaked_canary_is_blocked(self):
        result, _ = self.run_with("Port 8180 [1]. The marker is CANARY-abc.")
        self.assertEqual(result["status"], "blocked_by_output_guard")

    def test_control_characters_are_removed_from_the_question(self):
        seen_questions = []
        service.handle_question("Why\x00 8180?", lambda question: seen_questions.append(question) or [], lambda messages: "", "c")
        self.assertEqual(seen_questions, ["Why 8180?"])

    def test_only_cited_sources_are_public_and_passages_are_cut(self):
        long_hit = Hit(2, "TDD.md", "Stack", "x" * 400, 0.8)
        result = {"answer": "See [2].", "status": "answered", "sources": [HIT, long_hit], "problems": []}
        public = service.public_result(result)
        self.assertEqual([citation["n"] for citation in public["citations"]], [2])
        self.assertEqual(len(public["citations"][0]["passage"]), 300)


class ServerCase(unittest.TestCase):
    ask = staticmethod(answered)
    options = {}

    def setUp(self):
        self.logs = []
        self.server = service.make_server("127.0.0.1", 0, TOKEN, self.ask, log=self.logs.append, **self.options)
        self.port = self.server.server_address[1]
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join(timeout=5)

    def post(self, payload, token=TOKEN, path="/ask", content_type="application/json", raw=None):
        data = raw if raw is not None else json.dumps(payload).encode("utf-8")
        headers = {"Content-Type": content_type}
        if token:
            headers["Authorization"] = "Bearer " + token
        request = urllib.request.Request(f"http://127.0.0.1:{self.port}{path}", data=data, headers=headers, method="POST")
        try:
            with OPENER.open(request, timeout=10) as response:
                return response.status, json.load(response), response.headers
        except urllib.error.HTTPError as error:
            return error.code, json.loads(error.read().decode("utf-8")), error.headers

    def wait_for_logs(self, count):
        deadline = time.monotonic() + 5
        while len(self.logs) < count and time.monotonic() < deadline:
            time.sleep(0.01)


class HttpTests(ServerCase):
    def test_health(self):
        with OPENER.open(f"http://127.0.0.1:{self.port}/healthz", timeout=10) as response:
            self.assertEqual(json.load(response), {"status": "ok"})

    def test_a_missing_or_wrong_token_is_refused(self):
        status, _, headers = self.post({"question": "Which port?"}, token=None)
        self.assertEqual(status, 401)
        self.assertEqual(headers["WWW-Authenticate"], "Bearer")
        self.assertEqual(self.post({"question": "Which port?"}, token="wrong")[0], 401)

    def test_a_valid_question_is_answered_with_citations(self):
        status, body, headers = self.post({"question": "Which port does Keycloak use?"})
        self.assertEqual(status, 200)
        self.assertEqual(body["status"], "answered")
        self.assertEqual([citation["source"] for citation in body["citations"]], ["README.md"])
        self.assertEqual(headers["Cache-Control"], "no-store")

    def test_bad_requests_get_specific_statuses(self):
        self.assertEqual(self.post(None, raw=b"{not json")[0], 400)
        self.assertEqual(self.post({"q": "x"})[0], 422)
        self.assertEqual(self.post({"question": "hi"})[0], 422)
        self.assertEqual(self.post({"question": "Which port?"}, content_type="text/plain")[0], 415)
        self.assertEqual(self.post({"question": "Which port?"}, path="/other")[0], 404)

    def test_a_declared_body_that_is_too_large_is_refused(self):
        connection = http.client.HTTPConnection("127.0.0.1", self.port, timeout=10)
        connection.putrequest("POST", "/ask")
        connection.putheader("Authorization", "Bearer " + TOKEN)
        connection.putheader("Content-Type", "application/json")
        connection.putheader("Content-Length", str(service.MAX_BODY_BYTES + 1))
        connection.endheaders()
        self.assertEqual(connection.getresponse().status, 413)
        connection.close()

    def test_logs_hold_no_question_text(self):
        self.post({"question": "My very secret question"})
        self.wait_for_logs(1)
        self.assertEqual(len(self.logs), 1)
        record = json.loads(self.logs[0])
        self.assertNotIn("secret", self.logs[0])
        self.assertEqual(set(record), {"q_hmac", "q_len", "status", "ms", "request_id"})
        self.assertEqual(record["status"], "answered")


class RateLimitTests(ServerCase):
    options = {"rate_limit": 2}

    def test_the_third_request_is_limited(self):
        statuses = [self.post({"question": "Which port?"})[0] for _ in range(3)]
        self.assertEqual(statuses, [200, 200, 429])


class BusyTests(ServerCase):
    options = {"max_concurrent": 1}

    def setUp(self):
        self.entered = threading.Event()
        self.release = threading.Event()
        self.ask = self.slow_ask
        super().setUp()

    def slow_ask(self, question):
        self.entered.set()
        self.release.wait(10)
        return answered(question)

    def test_a_second_request_gets_503_while_the_slot_is_taken(self):
        results = []
        first = threading.Thread(target=lambda: results.append(self.post({"question": "Which port?"})[0]))
        first.start()
        self.assertTrue(self.entered.wait(10))
        self.assertEqual(self.post({"question": "Which port?"})[0], 503)
        self.release.set()
        first.join(10)
        self.assertEqual(results, [200])


class FailureTests(ServerCase):
    @staticmethod
    def ask(question):
        raise RuntimeError("secret internal detail")

    def test_internal_errors_leak_nothing(self):
        status, body, _ = self.post({"question": "Which port?"})
        self.assertEqual(status, 500)
        self.assertNotIn("secret", json.dumps(body))
        self.assertIn("request_id", body)


if __name__ == "__main__":
    unittest.main()
