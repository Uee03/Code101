from collections.abc import AsyncIterator, Iterator
from contextlib import asynccontextmanager
from typing import Annotated

from fastapi import Depends, FastAPI, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jwt.exceptions import InvalidTokenError
from pydantic import BaseModel, ConfigDict, StringConstraints
from sqlalchemy import Engine, create_engine, select, text
from sqlalchemy.orm import Session

from models import Note
from security import validate_token
from settings import Settings

Title = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=120)]


class NoteCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")
    title: Title


class NoteRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    title: str


def create_app(settings: Settings | None = None, engine: Engine | None = None) -> FastAPI:
    config = settings if settings is not None else Settings()
    owns_engine = engine is None
    db = engine if engine is not None else create_engine(
        config.database_url.get_secret_value(), pool_pre_ping=True
    )

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        try:
            yield
        finally:
            if owns_engine:
                db.dispose()

    app = FastAPI(title="Small notes API", lifespan=lifespan)
    bearer = HTTPBearer(auto_error=False)

    def get_session() -> Iterator[Session]:
        with Session(db) as session:
            yield session

    def current_subject(
        credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer)],
    ) -> str:
        if credentials is not None:
            try:
                return validate_token(credentials.credentials, config.jwt_secret.get_secret_value())
            except InvalidTokenError:
                pass
        raise HTTPException(status_code=401, detail="invalid credentials", headers={"WWW-Authenticate": "Bearer"})

    @app.get("/health")
    def health(session: Annotated[Session, Depends(get_session)]) -> dict[str, str]:
        session.execute(text("SELECT 1"))
        return {"status": "ok"}

    @app.post("/notes", response_model=NoteRead, status_code=201)
    def create_note(
        payload: NoteCreate,
        subject: Annotated[str, Depends(current_subject)],
        session: Annotated[Session, Depends(get_session)],
    ) -> NoteRead:
        with session.begin():
            note = Note(title=payload.title, owner=subject)
            session.add(note)
            session.flush()
            result = NoteRead.model_validate(note)
        return result

    @app.get("/notes", response_model=list[NoteRead])
    def list_notes(
        subject: Annotated[str, Depends(current_subject)],
        session: Annotated[Session, Depends(get_session)],
    ) -> list[Note]:
        return list(session.scalars(select(Note).where(Note.owner == subject).order_by(Note.id).limit(100)))

    @app.get("/notes/{note_id}", response_model=NoteRead)
    def read_note(
        note_id: int,
        subject: Annotated[str, Depends(current_subject)],
        session: Annotated[Session, Depends(get_session)],
    ) -> Note:
        note = session.scalar(select(Note).where(Note.id == note_id, Note.owner == subject))
        if note is None:
            raise HTTPException(status_code=404, detail="note not found")
        return note

    return app
