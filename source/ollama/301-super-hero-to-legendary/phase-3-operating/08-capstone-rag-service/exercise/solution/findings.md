# Findings for service_flawed.py (a review answer; check yours against it)

| # | Line or area | Flaw | Why it matters | Fix (as in service.py) |
|---|--------------|------|----------------|------------------------|
| 1 | `TOKEN = os.environ.get("RAG_API_TOKEN", "secret")` | A default secret | A forgotten setting leaves a guessable password | Refuse to start without a long token (`load_config`) |
| 2 | `== "Bearer " + TOKEN` | Ordinary string comparison | Timing differences can leak the token, one character at a time | `hmac.compare_digest` (`token_ok`) |
| 3 | `HTTPServer(("0.0.0.0", 8090), ...)` | Listens on every network interface | The service is reachable from the network without TLS | Bind to loopback only and put the authenticating proxy in front (`make_server` refuses other hosts) |
| 4 | `self.rfile.read(int(self.headers["Content-Length"]))` | Reads whatever length the client declares; a missing header raises | Memory exhaustion; a crash path | Check the header, cap the size (4096 bytes), answer 411 or 413 |
| 5 | `json.loads(body)["question"]` | No validation of type, length or shape | Wrong types, huge strings, extra fields; exceptions become 500s | Schema validation with `validate`, status 400 and 422 |
| 6 | `print("question:", question)` | The question text is logged | Questions are sensitive; logs live long and travel | A keyed fingerprint, length, status and timing only (`safe_log_record`) |
| 7 | `except Exception as error: reply = {"error": repr(error)}` | Exception details go to the client | Leaks file paths, SQL or library internals | A generic message plus a request id; details only in the protected log |
| 8 | `"sources": [hit.content for hit in result["sources"]]` | Returns the full text of every retrieved passage | More data than the client needs; leaks uncited and possibly sensitive text; unbounded size | Return only cited sources, with a truncated passage (`public_result`) |
| 9 | `answer_question(question, retrieve, generate)` with defaults | No control characters stripped, no delimiter, no canary, no output checks | Prompt injection and exfiltration channels are open | `handle_question` with `strip_control`, `wrap_untrusted`, canary, `output_problems` |
| 10 | No limits | No rate limit, no cap on concurrent generations | One client can exhaust the model | `RateLimiter`, a semaphore, 429 and 503 with `Retry-After` |
| 11 | `HTTPServer` (single thread) and no socket timeout | One slow client blocks everyone | Denial of service | `ThreadingHTTPServer`, a handler `timeout`, bounded concurrency |
| 12 | No path or content-type checks | Any POST path is treated as a question | Surprising behaviour, confusing logs | Only `/ask`, `Content-Type: application/json` (415 otherwise) |
| 13 | Status 401 sent without `WWW-Authenticate`; no `Cache-Control`, no `nosniff` | Missing standard headers | Clients cannot tell the scheme; caches may keep answers | `send_json` adds `Cache-Control: no-store`, `X-Content-Type-Options: nosniff`, `WWW-Authenticate: Bearer` |
| 14 | `serve_forever()` runs at import time | Importing the module starts a server | It cannot be tested | `make_server` and `main` behind `if __name__ == "__main__"` |
| 15 | The default `Server` header | Discloses the Python version | Helps attackers choose exploits | `server_version` set, `sys_version` empty |
