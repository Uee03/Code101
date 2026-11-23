---
track: python
level: 301
phase: 3
phase_name: production
lesson: '08'
title: "Security hardening: dependencies, secrets, validation, SSRF and the OWASP API Top 10"
time: "95 min"
prerequisites: [301.1.03, 301.3.07, 201.3.10]
versions: { python: "3.14 or newer", pydantic: "2.14.4", pip-audit: "2.10.1" }
verified: not yet run
source: source/python/301-super-hero-to-legendary/phase-3-production/08-security-hardening/
assets: []
---

# 08. Security hardening: dependencies, secrets, validation, SSRF and the OWASP API Top 10

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Audit a Python project's dependencies for known vulnerabilities and explain what the audit cannot tell you.
- Load secrets so they never appear in code, images, logs or `repr` output, and compare tokens in constant time.
- Validate input strictly (unknown fields, limits, types) and prevent broken object-level authorization.
- Build and test a server-side request forgery (SSRF) guard, and map the OWASP API Security Top 10 (2023) to controls in a Python service.

## Recap
1. Lesson 03: why is the idempotency key scoped by user?
   <details><summary>Answer</summary>Otherwise one user could replay, or read the stored response of, another user's request.</details>
2. Lesson 07: which logging mechanism protects against a secret reaching a log line, and why is it only a safety net?
   <details><summary>Answer</summary>The redaction by field name. It cannot see a secret inside a free-text message, so call sites must not log secrets at all.</details>
3. Python 201 lesson 10: which three claims must a service check on every bearer token besides the signature?
   <details><summary>Answer</summary>The issuer (`iss`), the audience (`aud`) and the expiry (`exp`).</details>

## Why it matters
Most breaches of API services are not clever. They are a missing ownership check, a dependency with a published fix nobody applied, a secret committed to a repository, or a server that fetches whatever URL it is given. Security hardening is the discipline of removing those ordinary holes systematically and keeping them removed. It belongs in code, tests and CI, not in a document that nobody re-reads.

## What you will build
Five small controls, each with tests, plus a mapping of the OWASP API Security Top 10 (2023) to where each risk is handled:

| Module | Control | OWASP risk |
|---|---|---|
| `ownership.py` | Object-level authorization and a response view that hides internal fields | API1, API3 |
| `validation.py` | Strict request model: no unknown fields, limits, no type coercion | API3, API4 |
| `secrets_hygiene.py` | Secrets from files or environment, safe `repr`, constant-time comparison, fail closed | API2, API8 |
| `ssrf_guard.py` | Allow-list, https only, resolved address checks | API7, API10 |
| `pip-audit` commands | Known-vulnerability scan of dependencies | API9, API8 |

## Before you start
- **Prerequisites:** Python 301 lessons [03, API design at scale](../phase-1-architecture/03-api-design-at-scale.md) and [07, observability](07-observability.md); [Python 201 lesson 10, authentication basics](../../201-hero-to-super-hero/phase-3-apis-and-data/10-authentication-basics.md).
- Time: 95 min. Break after Step 7.
- Python **3.14 or newer**; Windows `py -3.14`, macOS and Linux `python3.14`. A network connection for `pip install` and, optionally, `pip-audit`.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the course repository https://github.com/Uee03/Code101 under `source/python/301-super-hero-to-legendary/phase-3-production/08-security-hardening/` (on that page choose **Code, Download ZIP**, or run `git clone https://github.com/Uee03/Code101.git`).
- Never test the SSRF guard against real internal addresses on a network you do not own. The lesson uses a fake resolver so nothing is contacted.

## Steps
### Step 1. Create the workspace and the environment
**PowerShell - folder: anywhere**
```powershell
New-Item -ItemType Directory -Path "$HOME/code101/python301/lesson08" -Force | Out-Null
Set-Location "$HOME/code101/python301/lesson08"
py -3.14 -m venv .venv
code .
```

**macOS/Linux - folder: anywhere**
```bash
mkdir -p ~/code101/python301/lesson08
cd ~/code101/python301/lesson08
python3.14 -m venv .venv
code .
```
Create the files below in this folder (flat). If lost: `cd ~/code101/python301/lesson08`.

### Step 2. Dependency files
**File: `requirements.txt`**
```text
pydantic==2.14.4
```

**File: `requirements-dev.txt`**
```text
-r requirements.txt
pip-audit==2.10.1
```
The runtime file lists only what production needs. The development file adds tools and includes the runtime file with `-r`. Keeping them apart means the audit tool is never installed in the production image.

**PowerShell - folder: `~/code101/python301/lesson08`**
```powershell
& .\.venv\Scripts\python.exe -m pip install -r requirements-dev.txt
```

**macOS/Linux - folder: `~/code101/python301/lesson08`**
```bash
.venv/bin/python -m pip install -r requirements-dev.txt
```
Expected result: pip ends with `Successfully installed` and lists `pydantic`, `pip-audit` and their dependencies.

### Step 3. Audit the dependencies
**PowerShell - folder: `~/code101/python301/lesson08`**
```powershell
& .\.venv\Scripts\python.exe -m pip_audit -r requirements.txt
```

**macOS/Linux - folder: `~/code101/python301/lesson08`**
```bash
.venv/bin/python -m pip_audit -r requirements.txt
```
Expected result, not yet run: either `No known vulnerabilities found` or a table with the columns name, version, vulnerability id, fix versions. The exit code is 0 when nothing is found and non-zero otherwise, which is what makes it usable as a CI gate. The command needs network access, because it queries a vulnerability database for each pinned version.

How to read the result:
- A finding is a **known** vulnerability in that exact version. It is not proof that you are exploitable (maybe you never call the affected code) and a clean report is not proof that you are safe (unknown or unreported flaws, malicious packages and typosquats do not appear).
- Triage each finding: is the vulnerable code reachable, is there a fixed version, can you upgrade within your constraints, and if not what compensating control do you apply and when will you revisit?
- Audit what you **deploy**, i.e. the resolved lock file including transitive dependencies. This lesson pins only direct dependencies, which understates the real attack surface.

Supply-chain practices beyond the audit (read, then decide what your team needs):
- **Pin and lock** everything, including transitive packages, with a tool that records hashes (`pip-compile --generate-hashes`, `uv lock`), and install with `pip install --require-hashes -r requirements.txt` so that a changed package on the index is refused.
- **Review the name** of every new dependency. Typosquatted packages exist.
- **Dependency confusion:** if you use a private index, configure pip so that internal package names can never be fetched from the public index (`--index-url`, not `--extra-index-url`, unless you understand the consequences).
- **Automate updates** (Dependabot, Renovate) so that fixes arrive as small reviewed changes instead of one risky jump.
- **Minimise** dependencies. Each package is code you run with the application's privileges.

### Step 4. Object-level authorization and property-level exposure
**File: `ownership.py`**
```python
from dataclasses import dataclass


class NotFound(Exception):
    pass


@dataclass(frozen=True)
class OwnedTask:
    id: int
    owner: str
    title: str


def get_task_for(tasks: dict[int, OwnedTask], task_id: int, caller: str) -> OwnedTask:
    task = tasks.get(task_id)
    if task is None or task.owner != caller:
        raise NotFound("task not found")
    return task


def public_view(task: OwnedTask) -> dict[str, object]:
    return {"id": task.id, "title": task.title}
```
**Broken object level authorization (BOLA)**, the number one API risk, is a handler that looks a record up by an id from the request and returns it without checking that the caller may see it. `get_task_for` takes the **caller** as a parameter, so it is impossible to look a task up without one. A task owned by someone else gives **the same error as a missing task**: a different error ("forbidden" versus "not found") would let an attacker discover which ids exist. `public_view` is an explicit allow-list of response fields: new internal columns do not leak by default (broken object *property* level authorization).

### Step 5. Strict input validation
**File: `validation.py`**
```python
from pydantic import BaseModel, ConfigDict, Field


class TaskCreate(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

    title: str = Field(min_length=1, max_length=80)
    due_in_days: int = Field(default=7, ge=0, le=365, strict=True)
```
- `extra="forbid"` rejects unknown fields. By default Pydantic *ignores* them, which hides typos and blocks nothing; with an ORM-backed `**body.model_dump()` pattern, extra fields are how **mass assignment** (a client setting `owner` or `is_admin`) happens.
- `min_length`/`max_length` and `ge`/`le` bound every input. Unbounded strings and numbers are how memory and CPU are exhausted (unrestricted resource consumption).
- `strict=True` on the integer stops `"7"` (a string) from being silently converted. Choosing strictness per field is a trade-off: the more lenient the parser, the more inputs an attacker can use to confuse two systems that parse differently.
- `str_strip_whitespace=True` normalises before the length check, so `"   "` is an empty title.

Validation at the edge is **syntax and bounds**. Business rules (who may do this, is it allowed in this state) stay in the domain (lessons 01 and 02).

### Step 6. Secrets that do not leak
**File: `secrets_hygiene.py`**
```python
import hmac
import os
from collections.abc import Mapping
from pathlib import Path


class Secret:
    __slots__ = ("_value",)

    def __init__(self, value: str) -> None:
        self._value = value

    def reveal(self) -> str:
        return self._value

    def __repr__(self) -> str:
        return "Secret('****')"

    __str__ = __repr__


def read_secret(name: str, environ: Mapping[str, str] = os.environ) -> Secret:
    file_path = environ.get(f"{name}_FILE")
    if file_path:
        return Secret(Path(file_path).read_text(encoding="utf-8").strip())
    value = environ.get(name)
    if value:
        return Secret(value)
    raise RuntimeError(f"secret {name} is not configured")


def tokens_match(supplied: str, expected: Secret) -> bool:
    return hmac.compare_digest(supplied.encode(), expected.reveal().encode())
```
- `Secret` makes accidental disclosure harder: printing it, logging it or putting it in an exception message shows `Secret('****')`. Reading the value requires an explicit `reveal()` you can search for in code review.
- `read_secret` first looks for `NAME_FILE`, a path to a file. This is the convention used by Docker and Kubernetes secrets, which are mounted as files, because **environment variables leak easily**: they appear in process listings and crash reports and are inherited by child processes. The plain variable remains as a fallback for development.
- A missing secret raises at start-up: the service **fails closed** instead of running with an empty or default credential.
- `hmac.compare_digest` compares in time that does not depend on where the first difference is. Comparing a token with `==` can leak, by timing, how many leading characters were right.
- The `environ` parameter defaults to the real environment but accepts any mapping, so tests need no environment variables.

Where secrets must never live: source code, `Dockerfile` `ENV` or `ARG` lines (they remain in image layers), compose files committed to a repository, logs, error messages, URLs. Commit a `.env.example` with placeholders, never a real `.env`. Rotate any secret that was ever exposed, and prefer short-lived credentials issued by an identity system over long-lived static keys.

### Step 7. The SSRF guard
**Server-side request forgery** happens when your server fetches a URL that a user supplied (a webhook target, an avatar link, an "import from URL" feature). The attacker points it at something only your server can reach: a cloud metadata endpoint (such as `169.254.169.254`), an internal admin service, or `localhost`. The response, or just the fact that it connected, can leak credentials or map your network.

**File: `ssrf_guard.py`**
```python
import ipaddress
import socket
from collections.abc import Callable
from dataclasses import dataclass
from urllib.parse import urlsplit

Resolver = Callable[[str, int], list]


class UnsafeUrl(ValueError):
    """The URL must not be fetched by the server."""


@dataclass(frozen=True)
class Target:
    host: str
    port: int
    address: str


def is_public(address: str) -> bool:
    ip = ipaddress.ip_address(address.split("%")[0])
    if isinstance(ip, ipaddress.IPv6Address) and ip.ipv4_mapped is not None:
        ip = ip.ipv4_mapped
    return ip.is_global and not ip.is_multicast


def validate_outbound_url(
    url: str, allowed_hosts: set[str], resolver: Resolver = socket.getaddrinfo
) -> Target:
    try:
        parts = urlsplit(url)
    except ValueError as error:
        raise UnsafeUrl("the URL cannot be parsed") from error
    if parts.scheme != "https":
        raise UnsafeUrl("only https is allowed")
    if parts.username or parts.password:
        raise UnsafeUrl("credentials in the URL are not allowed")
    host = (parts.hostname or "").lower()
    if host not in allowed_hosts:
        raise UnsafeUrl(f"host {host!r} is not on the allow-list")
    try:
        port = parts.port or 443
    except ValueError as error:
        raise UnsafeUrl("the port is not a valid number") from error
    addresses = [info[4][0] for info in resolver(host, port)]
    if not addresses:
        raise UnsafeUrl(f"{host} did not resolve")
    for address in addresses:
        if not is_public(address):
            raise UnsafeUrl(f"{host} resolves to a non-public address")
    return Target(host, port, addresses[0])
```
The checks, in order of strength:
1. **Allow-list of hosts.** The strongest control: you can only be tricked into calling servers you named. Everything else is defence in depth.
2. **`https` only.** Refuses `file:`, `gopher:` and plain `http:`.
3. **No credentials in the URL** and a valid port.
4. **Resolve the name and check every address** (`socket.getaddrinfo` returns all of them). An allowed name that resolves to a private or loopback address, including an IPv4 address wrapped in IPv6 (`::ffff:127.0.0.1`), is refused. `is_global` is false for private, loopback, link-local and shared (carrier-grade NAT) ranges; multicast needs its own check.
5. The `resolver` argument defaults to the real function and accepts a fake in tests, so the tests never touch the network.

**Limits you must know.** A check followed by a separate connection is a **time-of-check to time-of-use** gap: a malicious DNS server can answer with a public address for your check and a private one for the connection (DNS rebinding). The function therefore returns the validated address, and a production client should connect to **that address** (keeping the original host name for TLS server-name checks and the `Host` header). Also disable automatic redirects (a redirect target is a new, unchecked URL) and apply a **network-level egress policy** that blocks internal ranges, which does not depend on code being right. On cloud platforms also require the hardened version of the metadata service where one exists.

**Stop here for a break if you like.**

### Step 8. Predict, then run the demo
**File: `demo.py`**
```python
from pydantic import ValidationError

from ownership import NotFound, OwnedTask, get_task_for, public_view
from secrets_hygiene import read_secret, tokens_match
from ssrf_guard import UnsafeUrl, validate_outbound_url
from validation import TaskCreate

ALLOWED_HOSTS = {"hooks.partner.example", "metadata.partner.example"}
ADDRESSES = {"hooks.partner.example": "8.8.8.8", "metadata.partner.example": "169.254.169.254"}


def fake_resolver(host: str, port: int) -> list:
    return [(0, 0, 0, "", (ADDRESSES[host], port))]


def main() -> None:
    target = validate_outbound_url("https://hooks.partner.example/notify", ALLOWED_HOSTS, fake_resolver)
    print(f"allowed: {target.host} -> {target.address}:{target.port}")
    for url in (
        "http://hooks.partner.example/notify",
        "https://evil.example/notify",
        "https://metadata.partner.example/latest",
    ):
        try:
            validate_outbound_url(url, ALLOWED_HOSTS, fake_resolver)
        except UnsafeUrl as error:
            print("refused:", error)

    try:
        TaskCreate(title="Pay invoice", owner="alice")
    except ValidationError:
        print("mass assignment refused: True")

    tasks = {1: OwnedTask(1, "alice", "Pay invoice")}
    print("alice sees:", public_view(get_task_for(tasks, 1, "alice")))
    try:
        get_task_for(tasks, 1, "bob")
    except NotFound as error:
        print("bob gets:", error)

    secret = read_secret("API_TOKEN", {"API_TOKEN": "s3cr3t-value"})
    print("secret repr:", secret)
    print("token check:", tokens_match("s3cr3t-value", secret), tokens_match("wrong", secret))


if __name__ == "__main__":
    main()
```
The fake resolver says `metadata.partner.example` resolves to `169.254.169.254`, the well-known link-local metadata address on many clouds: a name on your own allow-list that points at a dangerous address. Predict which of the three URLs is refused for which reason.

**PowerShell - folder: `~/code101/python301/lesson08`**
```powershell
& .\.venv\Scripts\python.exe demo.py
```

**macOS/Linux - folder: `~/code101/python301/lesson08`**
```bash
.venv/bin/python demo.py
```
Expected output, not yet run:
```text
allowed: hooks.partner.example -> 8.8.8.8:443
refused: only https is allowed
refused: host 'evil.example' is not on the allow-list
refused: metadata.partner.example resolves to a non-public address
mass assignment refused: True
alice sees: {'id': 1, 'title': 'Pay invoice'}
bob gets: task not found
secret repr: Secret('****')
token check: True False
```

### Step 9. The tests
**File: `test_security.py`**
```python
import tempfile
import unittest
from pathlib import Path

from pydantic import ValidationError

from ownership import NotFound, OwnedTask, get_task_for, public_view
from secrets_hygiene import Secret, read_secret, tokens_match
from ssrf_guard import UnsafeUrl, is_public, validate_outbound_url
from validation import TaskCreate

ALLOWED = {"hooks.partner.example"}


def resolving_to(*addresses: str):
    def resolver(host: str, port: int) -> list:
        return [(0, 0, 0, "", (address, port)) for address in addresses]

    return resolver


class SsrfGuardTests(unittest.TestCase):
    def test_a_public_address_on_the_allow_list_is_accepted(self) -> None:
        target = validate_outbound_url("https://hooks.partner.example/x", ALLOWED, resolving_to("8.8.8.8"))
        self.assertEqual((target.host, target.port, target.address), ("hooks.partner.example", 443, "8.8.8.8"))

    def test_non_public_addresses_are_never_public(self) -> None:
        for address in ("127.0.0.1", "10.0.0.5", "169.254.169.254", "100.64.0.1", "::1", "224.0.0.1", "::ffff:127.0.0.1"):
            with self.subTest(address=address):
                self.assertFalse(is_public(address))

    def test_a_host_that_resolves_to_a_private_address_is_refused(self) -> None:
        with self.assertRaises(UnsafeUrl):
            validate_outbound_url("https://hooks.partner.example/x", ALLOWED, resolving_to("10.0.0.5"))

    def test_one_bad_address_among_good_ones_refuses_the_url(self) -> None:
        with self.assertRaises(UnsafeUrl):
            validate_outbound_url(
                "https://hooks.partner.example/x", ALLOWED, resolving_to("8.8.8.8", "127.0.0.1")
            )

    def test_other_unsafe_forms_are_refused(self) -> None:
        resolver = resolving_to("8.8.8.8")
        for url in (
            "http://hooks.partner.example/x",
            "https://user:pw@hooks.partner.example/x",
            "https://evil.example/x",
            "https://127.0.0.1/x",
            "https://hooks.partner.example:abc/x",
            "file:///etc/passwd",
        ):
            with self.subTest(url=url):
                with self.assertRaises(UnsafeUrl):
                    validate_outbound_url(url, ALLOWED, resolver)


class ValidationTests(unittest.TestCase):
    def test_unknown_fields_are_refused(self) -> None:
        with self.assertRaises(ValidationError):
            TaskCreate(title="Pay", owner="alice")

    def test_limits_and_strict_types_are_enforced(self) -> None:
        for data in ({"title": ""}, {"title": "x" * 81}, {"title": "   "}, {"title": "ok", "due_in_days": "7"}, {"title": "ok", "due_in_days": 366}):
            with self.subTest(data=data):
                with self.assertRaises(ValidationError):
                    TaskCreate(**data)

    def test_a_valid_body_gets_its_default(self) -> None:
        self.assertEqual(TaskCreate(title="  Pay  ").title, "Pay")
        self.assertEqual(TaskCreate(title="Pay").due_in_days, 7)


class OwnershipTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tasks = {1: OwnedTask(1, "alice", "Pay invoice")}

    def test_the_owner_can_read_the_task(self) -> None:
        self.assertEqual(get_task_for(self.tasks, 1, "alice").title, "Pay invoice")

    def test_another_user_gets_the_same_error_as_a_missing_task(self) -> None:
        with self.assertRaises(NotFound) as other_user:
            get_task_for(self.tasks, 1, "bob")
        with self.assertRaises(NotFound) as missing:
            get_task_for(self.tasks, 2, "bob")
        self.assertEqual(str(other_user.exception), str(missing.exception))

    def test_the_public_view_hides_the_owner(self) -> None:
        self.assertEqual(public_view(self.tasks[1]), {"id": 1, "title": "Pay invoice"})


class SecretTests(unittest.TestCase):
    def test_a_secret_does_not_print_its_value(self) -> None:
        secret = Secret("s3cr3t-value")
        self.assertNotIn("s3cr3t", repr(secret) + str(secret) + f"{secret}")

    def test_a_secret_can_come_from_a_file(self) -> None:
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "token"
            path.write_text("from-file\n", encoding="utf-8")
            secret = read_secret("API_TOKEN", {"API_TOKEN_FILE": str(path)})
        self.assertEqual(secret.reveal(), "from-file")

    def test_a_missing_secret_stops_start_up(self) -> None:
        with self.assertRaises(RuntimeError):
            read_secret("API_TOKEN", {})

    def test_token_comparison(self) -> None:
        secret = Secret("abc")
        self.assertTrue(tokens_match("abc", secret))
        self.assertFalse(tokens_match("abd", secret))


if __name__ == "__main__":
    unittest.main()
```
**PowerShell - folder: `~/code101/python301/lesson08`**
```powershell
& .\.venv\Scripts\python.exe -m unittest -v
```

**macOS/Linux - folder: `~/code101/python301/lesson08`**
```bash
.venv/bin/python -m unittest -v
```
Expected output, not yet run: fifteen tests ending in `ok`, then `Ran 15 tests in <time>s` and `OK`.

## How it works
The OWASP API Security Top 10 (2023) mapped to controls, and where the capstone applies them:

| Risk | What goes wrong | Control in a Python service | Where here and in the capstone |
|---|---|---|---|
| **API1** Broken object level authorization | Caller reads or changes another user's object by changing an id | Every lookup takes the caller; same error for "missing" and "not yours" | `ownership.py`; capstone access checks ([chapters 02 and 05](https://github.com/Uee03/Code101/blob/main/capstones/backend-python/tutorials/phase-5-hardening/05-hardening.md)) |
| **API2** Broken authentication | Weak or unvalidated tokens, credential stuffing | Validate `iss`, `aud`, `exp` and signature algorithm; rate-limit login; no secrets in code | `secrets_hygiene.py`; capstone [chapter 03](https://github.com/Uee03/Code101/blob/main/capstones/backend-python/tutorials/phase-3-identity/03-identity.md) |
| **API3** Broken object property level authorization | Over-sharing fields; mass assignment | Response allow-lists; `extra="forbid"` on request models | `public_view`, `validation.py` |
| **API4** Unrestricted resource consumption | Large bodies, deep pages, expensive queries, paid third-party calls | Body-size limit, max page size (lesson 03), timeouts, rate limits, quotas | `validation.py` limits; capstone rate limiter and 413 handling |
| **API5** Broken function level authorization | A normal user reaches an admin function | Role or scope checks on each route, deny by default | capstone roles and scopes |
| **API6** Unrestricted access to sensitive business flows | Automated abuse of a legitimate flow (bulk sign-up, ticket hoarding) | Business-level limits, step-up checks, detection (a design question, not a library) | domain rules (lesson 02), metrics (lesson 07) |
| **API7** Server side request forgery | Server fetches an attacker-chosen URL | Allow-list, resolved-address check, no redirects, egress policy | `ssrf_guard.py` |
| **API8** Security misconfiguration | Debug on, open CORS, missing headers, default credentials, verbose errors | Secure defaults in code, docs off in production, security headers, least privilege containers | capstone hardening chapter; lesson 09 |
| **API9** Improper inventory management | Old versions and forgotten endpoints stay exposed | Versioning and sunset (lesson 03), an inventory of hosts and versions, dependency audit | Step 3 |
| **API10** Unsafe consumption of APIs | Trusting data from a third-party API | Validate and bound responses from partners like any input, timeouts, TLS verification on | `ssrf_guard.py` plus parsing with Pydantic |

**Misconception to correct:** "Authentication is the security." A perfectly authenticated user is still the most likely attacker of your authorization logic. Four of the ten risks (API1, API3, API5, API6) are about what an *authenticated* caller may do.

## Decision record (ADR-008)
| | |
|---|---|
| **Context** | A service that stores users' tasks, calls partner webhooks and runs in containers. |
| **Decision** | Strict request models (`extra="forbid"`, limits, strict types). Every data access takes the caller. Secrets are read from mounted files with environment fallback and fail closed. Outbound URLs go through an allow-list guard, plus a network egress policy. CI runs a dependency audit on the lock file. |
| **Consequences** | Stricter parsers reject some sloppy client requests (these are found and fixed early). The allow-list needs maintenance when partners change hosts. The audit adds a network step to CI and findings need triage time. |
| **Alternatives rejected** | A deny-list of "bad" hosts or ranges alone (always incomplete). Trusting a web application firewall to catch SSRF or BOLA (it cannot know who owns an object). Lenient parsing "for compatibility" (turns every parsing difference into a potential bypass). |

## When not to use this
- **Do not hand-roll cryptography or token validation.** Use maintained libraries and the identity provider's flows; the guard code here is for *your* logic around them.
- **Do not rely on the IP check without the allow-list.** Pure IP filtering is a weak control on its own.
- **Do not make validation stricter than your clients can follow** without a versioning plan (lesson 03): tightening a rule is a breaking change.
- **Do not treat `pip-audit` as a gate that blocks everything immediately** without a documented exception process: teams then disable it. A time-limited, reviewed ignore list is better than no audit.
- **An in-process secret wrapper does not replace a secret manager.** It reduces accidental disclosure; storage, rotation and access control are the manager's job.

## What to measure
- **Dependency freshness:** the number of dependencies with known vulnerabilities, and the age of the oldest unfixed finding (days). Track the trend, not a single day.
- **Authorization test coverage:** for every route that takes an id, is there a test where a different user is refused? Count the routes without one.
- **Refusal rates:** the number of 400, 401, 403, 404, 413 and 429 responses per route. A spike in 403 on one route is an attack or a bug; both need a human.
- **Secrets exposure:** the number of secrets rotated because they were exposed, and the time to rotate. Run a secret scanner over every commit.
- **Egress:** outbound connections from the service to destinations not on the allow-list, from network logs.

## Production checklist
- [ ] Dependencies are locked with hashes, audited in CI, and updated on a schedule.
- [ ] Every request model forbids extra fields, bounds strings, numbers and collections, and is strict where coercion is dangerous.
- [ ] A test per id-taking route proves another user is refused with the same response as "not found".
- [ ] Responses are built from allow-listed views, never by serialising the storage model.
- [ ] Secrets come from a manager or mounted files, are never in images or logs, and are rotated; the service refuses to start without them.
- [ ] Outbound calls go through a guard; redirects are off; egress is restricted at the network level.
- [ ] Interactive docs, debug mode and detailed errors are off in production; security headers and a restrictive CORS policy are on (the capstone hardening chapter lists them).
- [ ] Security events (refusals, failed authentications) are logged with a trace id, without the secret that triggered them.
- [ ] Rate limits and body-size limits exist at the edge and in the application.

## Try it
Starter: `exercise/starter/exercise.py`. Copy the `starter` folder itself and rename the copy `try08`, then work in `try08`.
1. **Guided:** implement `is_safe_redirect`, the check used after login so that `?next=` cannot send users to an attacker's site (an open redirect). The program prints the verdict for six targets.
2. **Change:** add the SSRF guard's missing property: a maximum response size. Write a function `read_limited(stream, limit)` that reads at most `limit` bytes from a file-like object and raises `ValueError` if the data is longer, and test both outcomes with `io.BytesIO`.
3. **Stretch (no single answer):** your partners need to call you back from changing IP addresses and you need to call them. Compare an allow-list in code, an allow-list in configuration reloaded at run time, and an egress proxy that is the only route to the internet. For each, say who can change it, how a change is reviewed and what failure looks like.

**File: `exercise/starter/exercise.py`**
```python
from urllib.parse import urlsplit


def is_safe_redirect(target: str, allowed_hosts: set[str]) -> bool:
    # TODO 1: accept a path that starts with one "/" but not "//" and not "/\\" (browsers treat both as a host)
    # TODO 2: otherwise accept only an https URL whose hostname is in allowed_hosts
    # TODO 3: everything else (other schemes, empty host, relative text) is unsafe
    raise NotImplementedError


if __name__ == "__main__":
    allowed = {"app.example"}
    for target in ["/dashboard", "//evil.example/x", "https://app.example/home", "https://evil.example/", "javascript:alert(1)", "/\\evil.example"]:
        print(target, "->", is_safe_redirect(target, allowed))
```
Expected output once complete:
```text
/dashboard -> True
//evil.example/x -> False
https://app.example/home -> True
https://evil.example/ -> False
javascript:alert(1) -> False
/\evil.example -> False
```

<details><summary>Solution</summary>

**File: `exercise/solution/exercise.py`** (only `is_safe_redirect` differs)
```python
def is_safe_redirect(target: str, allowed_hosts: set[str]) -> bool:
    if target.startswith("/") and not target.startswith("//") and not target.startswith("/\\"):
        return True
    parts = urlsplit(target)
    return parts.scheme == "https" and (parts.hostname or "") in allowed_hosts
```
A path beginning with `//` or `/\` is a "protocol-relative" URL that browsers resolve to another host, so a simple "starts with /" check is not enough. Everything not explicitly allowed is refused: a default-deny shape.

</details>

## Check yourself
1. Why does `get_task_for` raise the same error for "not yours" and "does not exist"?
   <details><summary>Answer</summary>A different response would reveal which ids exist, helping an attacker enumerate objects.</details>
2. A clean `pip-audit` report: what does it prove?
   <details><summary>Answer</summary>Only that none of the pinned versions has a vulnerability known to the database at that moment. It says nothing about unknown flaws, malicious packages, transitive packages you did not audit, or your own code.</details>
3. Predict: the allow-listed host `hooks.partner.example` starts resolving to `10.0.0.5`. What does `validate_outbound_url` do, and why is that the right behaviour?
   <details><summary>Answer</summary>It raises `UnsafeUrl` ("resolves to a non-public address"). A name can be pointed at an internal address by whoever controls DNS or a compromised partner, so the resolved address is checked, not only the name.</details>
4. Why prefer `NAME_FILE` to an environment variable for production secrets?
   <details><summary>Answer</summary>Environment variables are visible in process listings and crash dumps and are inherited by child processes; a mounted file has tighter permissions and does not spread.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `ModuleNotFoundError: No module named 'pydantic'` | Ran `python` instead of the `.venv` interpreter | Use `.venv/bin/python` or `.\.venv\Scripts\python.exe` |
| `No module named pip_audit` | Installed `requirements.txt` instead of `requirements-dev.txt` | Install the dev file (Step 2) |
| `pip-audit` reports a connection or network error (typical message) | No network or a proxy blocks the vulnerability service | Run it where the network is available (CI) |
| A `ValidationError` for a field you did not expect (symptom) | `extra="forbid"` turns a typo or an extra client field into an error | Read the error's `loc` field; fix the client or the model deliberately |
| The guard rejects a valid partner (symptom) | The host is missing from the allow-list or resolves to a non-public address in your test network | Add the host after review; use the fake resolver in unit tests |
| A secret appears in a traceback (symptom) | It was used in an f-string or exception message | Pass `Secret` objects around and call `reveal()` only at the point of use |

## Best practice
Deny by default: allow-list inputs, hosts and response fields; check ownership on every access; fail closed when a secret is missing. Source: OWASP API Security Top 10 2023 https://owasp.org/API-Security/editions/2023/en/0x11-t10/ ; Pydantic strict mode and configuration https://docs.pydantic.dev/latest/concepts/strict_mode/ ; Python `ipaddress` https://docs.python.org/3/library/ipaddress.html ; `hmac.compare_digest` https://docs.python.org/3/library/hmac.html#hmac.compare_digest ; Python `secrets` module https://docs.python.org/3/library/secrets.html

## Going further
- The capstone's [hardening chapter](https://github.com/Uee03/Code101/blob/main/capstones/backend-python/tutorials/phase-5-hardening/05-hardening.md) has its own OWASP walk-through: compare its table with yours and find one row that goes further.
- Read the PyPA documentation on secure installs (hash-checking mode) before you adopt a lock-file workflow.

## Summary
- You audited dependencies and explained what a report can and cannot prove.
- You enforced ownership, property-level exposure and strict validation, and tested each.
- You loaded secrets without leaking them and compared tokens safely.
- You built an SSRF guard with its limits stated, and mapped the OWASP API Top 10 to Python controls.

## Next lesson
09. Packaging, release and a production readiness checklist, finishing with a capstone-style review exercise.
