from collections.abc import Iterator
from pathlib import Path
from secrets import token_hex

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Engine, create_engine

from app import create_app
from models import Base
from security import issue_token
from settings import Settings


@pytest.fixture
def secret() -> str:
    return token_hex(32)


@pytest.fixture
def engine(tmp_path: Path) -> Iterator[Engine]:
    db = create_engine(f"sqlite:///{(tmp_path / 'notes.db').as_posix()}")
    Base.metadata.create_all(db)
    try:
        yield db
    finally:
        db.dispose()


@pytest.fixture
def client(engine: Engine, secret: str) -> Iterator[TestClient]:
    config = Settings(database_url="sqlite://", jwt_secret=secret, _env_file=None)
    with TestClient(create_app(config, engine)) as test_client:
        yield test_client


@pytest.fixture
def ada_headers(secret: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {issue_token('ada', secret)}"}


@pytest.fixture
def bob_headers(secret: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {issue_token('bob', secret)}"}
