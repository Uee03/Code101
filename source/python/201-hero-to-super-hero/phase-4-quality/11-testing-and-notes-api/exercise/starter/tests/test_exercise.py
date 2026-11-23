from fastapi.testclient import TestClient


def test_two_owners(client: TestClient, ada_headers: dict[str, str], bob_headers: dict[str, str]) -> None:
    response = client.post("/notes", json={"title": "Ada only"}, headers=ada_headers)
    note_id = response.json()["id"]
    # TODO: assert Ada can read this note and Bob receives 404.
    raise NotImplementedError("complete the ownership assertions")
