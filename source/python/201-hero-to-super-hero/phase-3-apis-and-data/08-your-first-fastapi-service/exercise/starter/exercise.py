from fastapi import FastAPI, HTTPException
from fastapi.testclient import TestClient

app = FastAPI()
notes = {1: "Read docs"}


@app.get("/notes/{note_id}")
def read_note(note_id: int) -> dict[str, str]:
    # TODO: return a title or raise HTTPException with status 404.
    raise NotImplementedError("complete the route")


with TestClient(app) as client:
    assert client.get("/notes/1").json() == {"title": "Read docs"}
    assert client.get("/notes/2").status_code == 404
print("found: 200; missing: 404")
