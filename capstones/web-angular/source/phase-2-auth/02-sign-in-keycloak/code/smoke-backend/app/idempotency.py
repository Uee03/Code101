import hashlib
import json
from collections.abc import Callable
from typing import Any
from uuid import UUID

from pydantic import BaseModel
from sqlalchemy import Connection, text

from app.errors import ProblemError, conflict


def fingerprint(method: str, path: str, body: BaseModel) -> str:
    """Two requests are 'the same' when method, path and the JSON body (key order ignored) are equal."""
    canonical = json.dumps(body.model_dump(mode="json", by_alias=True), sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(f"{method} {path} {canonical}".encode()).hexdigest()


def run_idempotent(conn: Connection, user_id: UUID, key: str | None, request_hash: str,
                   create: Callable[[], dict[str, Any]]) -> tuple[dict[str, Any], bool]:
    """Run `create` once per (user, key). Returns the response body and whether it is a replay.

    The key row and the new resource are written in ONE transaction. A second request with the same key
    waits on the unique index until the first one commits, then replays its stored body. If `create`
    fails, the whole transaction rolls back, so the key is free again and the client may retry.
    """
    if key is None:
        return create(), False
    params = {"user_id": user_id, "key": key, "hash": request_hash}
    conn.execute(text("DELETE FROM idempotency_keys WHERE user_id = :user_id AND key = :key AND expires_at < now()"), params)
    claimed = conn.execute(
        text("INSERT INTO idempotency_keys (user_id, key, request_hash) VALUES (:user_id, :key, :hash) "
             "ON CONFLICT DO NOTHING RETURNING 1"),
        params,
    ).first()
    if claimed:
        body = create()
        conn.execute(
            text("UPDATE idempotency_keys SET status_code = 201, response_body = CAST(:body AS jsonb) "
                 "WHERE user_id = :user_id AND key = :key"),
            {**params, "body": json.dumps(body)},
        )
        return body, False
    stored = conn.execute(
        text("SELECT request_hash, status_code, response_body FROM idempotency_keys WHERE user_id = :user_id AND key = :key"),
        params,
    ).mappings().one()
    if stored["request_hash"] != request_hash:
        raise ProblemError(422, "This Idempotency-Key was already used with a different request.")
    if stored["status_code"] is None:
        raise conflict("A request with this Idempotency-Key is still being processed.")
    return stored["response_body"], True
