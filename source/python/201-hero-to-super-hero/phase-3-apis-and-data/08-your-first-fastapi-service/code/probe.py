from fastapi.testclient import TestClient

from app import create_app


if __name__ == "__main__":
    with TestClient(create_app()) as client:
        created = client.post("/notes", json={"title": " Read docs "})
        print(created.status_code, created.json())
        missing = client.get("/notes/999")
        print(missing.status_code, missing.json()["detail"])
        print(client.post("/notes", json={"title": " "}).status_code)
