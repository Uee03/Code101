import base64
import hashlib
import json
import threading
from typing import Annotated

from fastapi import APIRouter, Depends, FastAPI, Header, Query, Request, Response
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field


class ApiError(Exception):
    def __init__(self, status: int, title: str, detail: str) -> None:
        self.status = status
        self.title = title
        self.detail = detail


class TaskIn(BaseModel):
    title: str = Field(min_length=1, max_length=80)


class TaskV1(BaseModel):
    id: int
    title: str
    done: bool


class PageV1(BaseModel):
    items: list[TaskV1]
    next_cursor: str | None


class TaskV2(BaseModel):
    id: int
    title: str
    status: str


class PageV2(BaseModel):
    items: list[TaskV2]
    next_cursor: str | None


class Store:
    def __init__(self) -> None:
        self.lock = threading.Lock()
        self.tasks: list[dict] = [
            {"id": n, "title": f"Seed task {n}", "done": n % 2 == 0} for n in range(1, 8)
        ]
        self.replays: dict[str, tuple[str, dict]] = {}


def encode_cursor(last_id: int) -> str:
    return base64.urlsafe_b64encode(f"after:{last_id}".encode()).decode()


def decode_cursor(cursor: str | None) -> int:
    if cursor is None:
        return 0
    try:
        text = base64.urlsafe_b64decode(cursor.encode()).decode()
        prefix, _, number = text.partition(":")
        if prefix != "after":
            raise ValueError(text)
        return int(number)
    except ValueError as error:
        raise ApiError(400, "Invalid cursor", "The cursor was not issued by this API.") from error


def take_page(store: Store, limit: int, cursor: str | None) -> tuple[list[dict], str | None]:
    after = decode_cursor(cursor)
    rows = [task for task in store.tasks if task["id"] > after][: limit + 1]
    has_more = len(rows) > limit
    rows = rows[:limit]
    return rows, (encode_cursor(rows[-1]["id"]) if has_more else None)


def fingerprint(body: TaskIn) -> str:
    canonical = json.dumps(body.model_dump(), sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(canonical.encode()).hexdigest()


def deprecate_v1(response: Response) -> None:
    response.headers["Sunset"] = "Wed, 31 Dec 2031 23:59:59 GMT"
    response.headers["Link"] = '</v2/tasks>; rel="successor-version"'


def create_app() -> FastAPI:
    store = Store()
    app = FastAPI(title="Tasks API", docs_url=None, redoc_url=None)

    @app.exception_handler(ApiError)
    async def handle_api_error(_: Request, error: ApiError) -> JSONResponse:
        body = {"type": "about:blank", "title": error.title, "status": error.status, "detail": error.detail}
        return JSONResponse(body, status_code=error.status, media_type="application/problem+json")

    v1 = APIRouter(prefix="/v1", dependencies=[Depends(deprecate_v1)])
    v2 = APIRouter(prefix="/v2")

    @v1.get("/tasks", response_model=PageV1)
    def list_v1(limit: Annotated[int, Query(ge=1, le=100)] = 3, cursor: str | None = None) -> dict:
        rows, next_cursor = take_page(store, limit, cursor)
        return {"items": rows, "next_cursor": next_cursor}

    @v2.get("/tasks", response_model=PageV2)
    def list_v2(limit: Annotated[int, Query(ge=1, le=100)] = 3, cursor: str | None = None) -> dict:
        rows, next_cursor = take_page(store, limit, cursor)
        items = [
            {"id": row["id"], "title": row["title"], "status": "done" if row["done"] else "open"}
            for row in rows
        ]
        return {"items": items, "next_cursor": next_cursor}

    @v1.post("/tasks", response_model=TaskV1, status_code=201)
    def create_v1(
        body: TaskIn,
        response: Response,
        idempotency_key: Annotated[str, Header(min_length=8, max_length=64)],
    ) -> dict:
        digest = fingerprint(body)
        with store.lock:
            replay = store.replays.get(idempotency_key)
            if replay is not None:
                stored_digest, stored_task = replay
                if stored_digest != digest:
                    raise ApiError(
                        422,
                        "Idempotency key reused",
                        "This Idempotency-Key was used with a different request body.",
                    )
                response.headers["Idempotent-Replay"] = "true"
                return stored_task
            task = {"id": len(store.tasks) + 1, "title": body.title, "done": False}
            store.tasks.append(task)
            store.replays[idempotency_key] = (digest, task)
            return task

    app.include_router(v1)
    app.include_router(v2)
    return app
