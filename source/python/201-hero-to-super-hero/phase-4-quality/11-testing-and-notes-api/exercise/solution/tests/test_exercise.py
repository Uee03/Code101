from fastapi.testclient import TestClient


def test_two_owners(client: TestClient, ada_headers: dict[str, str], bob_headers: dict[str, str]) -> None:
    response = client.post("/notes", json={"title": "Ada only"}, headers=ada_headers)
    note_id = response.json()["id"]
    assert client.get(f"/notes/{note_id}", headers=ada_headers).status_code == 200
    assert client.get(f"/notes/{note_id}", headers=bob_headers).status_code == 404
