from dataclasses import dataclass
from threading import Lock
from typing import Annotated

from fastapi import Depends, FastAPI, HTTPException
from pydantic import BaseModel, ConfigDict, StringConstraints

Title = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=120)]


@dataclass
class Note:
    id: int
    title: str
    audit_label: str = "internal"


class NoteCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")
    title: Title


class NoteRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    title: str


class Repository:
    def __init__(self) -> None:
        self.notes: dict[int, Note] = {}
        self.lock = Lock()

    def add(self, title: str) -> Note:
        with self.lock:
            note = Note(id=len(self.notes) + 1, title=title)
            self.notes[note.id] = note
            return note

    def get(self, note_id: int) -> Note | None:
        with self.lock:
            return self.notes.get(note_id)


def create_app() -> FastAPI:
    app = FastAPI(title="Notes, first service")
    repository = Repository()

    def get_repository() -> Repository:
        return repository

    @app.post("/notes", response_model=NoteRead, status_code=201)
    def create_note(payload: NoteCreate, repo: Annotated[Repository, Depends(get_repository)]) -> Note:
        return repo.add(payload.title)

    @app.get("/notes/{note_id}", response_model=NoteRead)
    def read_note(note_id: int, repo: Annotated[Repository, Depends(get_repository)]) -> Note:
        note = repo.get(note_id)
        if note is None:
            raise HTTPException(status_code=404, detail="note not found")
        return note

    return app
