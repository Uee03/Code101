import hashlib
import hmac
import re
import secrets
from datetime import datetime, timezone
from urllib.parse import urlparse

MAX_ANSWER_CHARS = 1200
CONTROL = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]")
INJECTION_PATTERNS = [
    re.compile(r"ignore\s+(all\s+|any\s+|the\s+)?(previous|prior|above)\s+(instructions|rules)", re.IGNORECASE),
    re.compile(r"disregard\s+(all\s+|any\s+|the\s+)?(previous|prior|above)?\s*(instructions|rules)", re.IGNORECASE),
    re.compile(r"you\s+are\s+now\b", re.IGNORECASE),
    re.compile(r"reveal\s+(your|the)\s+(system\s+)?prompt", re.IGNORECASE),
    re.compile(r"new\s+instructions?\s*:", re.IGNORECASE),
    re.compile(r"\bsystem\s*:", re.IGNORECASE),
]
URL = re.compile(r"https?://[^\s)\]>\"']+", re.IGNORECASE)
MARKDOWN_IMAGE = re.compile(r"!\[[^\]]*\]\([^)]*\)")
HTML_TAG = re.compile(r"</?\s*(script|iframe|img|object|embed|style|link)\b", re.IGNORECASE)
EMAIL = re.compile(r"[\w.+-]+@[\w-]+(?:\.[\w-]+)+")
PHONE = re.compile(r"\+?\d[\d\s().-]{7,}\d")


def strip_control(text):
    return CONTROL.sub("", text)


def scan_injection(text):
    return [pattern.pattern for pattern in INJECTION_PATTERNS if pattern.search(text)]


def wrap_untrusted(text, label, boundary=None):
    boundary = boundary or secrets.token_hex(8)
    cleaned = strip_control(text).replace(boundary, "")
    return f"<<<{label} {boundary}>>>\n{cleaned}\n<<<END {label} {boundary}>>>"


def output_problems(answer, allowed_hosts=(), max_chars=MAX_ANSWER_CHARS):
    allowed = {host.lower() for host in allowed_hosts}
    problems = []
    if len(answer) > max_chars:
        problems.append("the answer is longer than the limit")
    if MARKDOWN_IMAGE.search(answer):
        problems.append("the answer contains a markdown image")
    if HTML_TAG.search(answer):
        problems.append("the answer contains active HTML")
    for url in URL.findall(answer):
        host = (urlparse(url).hostname or "").lower()
        if host not in allowed:
            problems.append(f"the answer links to a host that is not allowed: {host}")
    return problems


def make_canary():
    return "CANARY-" + secrets.token_hex(6)


def leaks_canary(text, canary):
    return canary in text


def redact(text):
    return PHONE.sub("[phone]", EMAIL.sub("[email]", text))


def fingerprint(question, key):
    return hmac.new(key, question.encode("utf-8"), hashlib.sha256).hexdigest()[:16]


def safe_log_record(question, status, milliseconds, key, debug_until=None, now=None):
    now = now or datetime.now(timezone.utc)
    record = {
        "q_hmac": fingerprint(question, key),
        "q_len": len(question),
        "status": status,
        "ms": milliseconds,
    }
    if debug_until is not None and now < debug_until:
        record["text"] = redact(question)
    return record
