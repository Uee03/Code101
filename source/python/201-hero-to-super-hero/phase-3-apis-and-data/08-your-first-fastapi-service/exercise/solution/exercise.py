from fastapi import FastAPI, HTTPException
from fastapi.testclient import TestClient

app = FastAPI()
notes = {1: "Read docs"}


@app.get("/notes/{note_id}")
def read_note(note_id: int) -> dict[str, str]:
    if note_id not in notes:
        raise HTTPException(status_code=404, detail="note not found")
    return {"title": notes[note_id]}


with TestClient(app) as client:
    assert client.get("/notes/1").json() == {"title": "Read docs"}
    assert client.get("/notes/2").status_code == 404
print("found: 200; missing: 404")
