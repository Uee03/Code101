# Findings for nginx.flawed.conf (a review answer; check yours against it)

| # | Flaw | Why it is a problem | Fix (as in the lab nginx.conf) |
|---|------|---------------------|--------------------------------|
| 1 | No authentication | Anyone who can reach the port can use the model; Ollama has none of its own | `auth_basic` with a hashed password file (later: OIDC) |
| 2 | `location /` proxies everything | `/api/pull`, `/api/delete`, `/api/create`, `/api/show` and `/api/tags` are reachable: disk filling, deleting models, probing | Allow-list only the endpoints the clients need; `return 403` for the rest |
| 3 | No rate limit | One client can occupy the model and starve others | `limit_req_zone` and `limit_req`, with status 429 |
| 4 | `client_max_body_size 0` | Unlimited request bodies; memory and disk exhaustion | A small explicit limit such as `1m` |
| 5 | The access log includes `$request_body` | Prompts, which may hold private data, are written to logs | Default access log (no body); never log bodies |
| 6 | `proxy_read_timeout 3600s` and no client timeouts | Slow or stuck connections tie up workers for an hour | Short client and send timeouts; a read timeout sized to the longest legitimate answer |
| 7 | `proxy_buffering` left on | Streamed answers arrive in bursts instead of piece by piece | `proxy_buffering off` on the proxied location |
| 8 | `server_tokens` left on | The version is disclosed in headers | `server_tokens off` |
| 9 | Plain HTTP on every interface the container publishes (not visible in this file) | Credentials and prompts cross the network unencrypted if the port leaves the machine | Publish on `127.0.0.1` only (Compose), or terminate TLS (`nginx.tls.conf`) |
| 10 | No method restriction | Methods other than the ones needed are accepted | `limit_except GET POST { deny all; }` |
