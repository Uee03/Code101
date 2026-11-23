from datetime import UTC, datetime, timedelta

import jwt
import pytest
from fastapi.testclient import TestClient

from security import AUDIENCE, ISSUER, issue_token


def test_create_read_and_output_filter(client: TestClient, ada_headers: dict[str, str]) -> None:
    response = client.post("/notes", json={"title": " Read docs "}, headers=ada_headers)
    assert response.status_code == 201
    assert response.json() == {"id": 1, "title": "Read docs"}
    assert client.get("/notes/1", headers=ada_headers).json() == response.json()


@pytest.mark.parametrize("title", ["", "   ", "x" * 121])
def test_invalid_title(client: TestClient, ada_headers: dict[str, str], title: str) -> None:
    response = client.post("/notes", json={"title": title}, headers=ada_headers)
    assert response.status_code == 422
    assert client.get("/notes", headers=ada_headers).json() == []


def test_extra_owner_is_rejected(client: TestClient, ada_headers: dict[str, str]) -> None:
    response = client.post("/notes", json={"title": "Read", "owner": "bob"}, headers=ada_headers)
    assert response.status_code == 422


def test_ownership(client: TestClient, ada_headers: dict[str, str], bob_headers: dict[str, str]) -> None:
    client.post("/notes", json={"title": "Ada only"}, headers=ada_headers)
    assert client.get("/notes/1", headers=bob_headers).status_code == 404
    assert client.get("/notes", headers=bob_headers).json() == []
    assert client.get("/notes", headers=ada_headers).json() == [{"id": 1, "title": "Ada only"}]


def test_missing_note(client: TestClient, ada_headers: dict[str, str]) -> None:
    assert client.get("/notes/999", headers=ada_headers).status_code == 404


@pytest.mark.parametrize("headers", [{}, {"Authorization": "Bearer broken"}, {"Authorization": "Basic abc"}])
def test_invalid_bearer(client: TestClient, headers: dict[str, str]) -> None:
    response = client.get("/notes", headers=headers)
    assert response.status_code == 401
    assert response.headers["www-authenticate"] == "Bearer"


def test_expired_bearer(client: TestClient, secret: str) -> None:
    token = issue_token("ada", secret, now=datetime(2000, 1, 1, tzinfo=UTC))
    assert client.get("/notes", headers={"Authorization": f"Bearer {token}"}).status_code == 401


@pytest.mark.parametrize("change", [{"iss": "wrong"}, {"aud": "wrong"}, {"sub": " "}, {"exp": None}])
def test_invalid_claims(client: TestClient, secret: str, change: dict[str, object]) -> None:
    claims = {"sub": "ada", "iss": ISSUER, "aud": AUDIENCE, "exp": datetime.now(UTC) + timedelta(minutes=5)}
    claims.update(change)
    if claims["exp"] is None:
        del claims["exp"]
    token = jwt.encode(claims, secret, algorithm="HS256")
    assert client.get("/notes", headers={"Authorization": f"Bearer {token}"}).status_code == 401


def test_health(client: TestClient) -> None:
    assert client.get("/health").json() == {"status": "ok"}
