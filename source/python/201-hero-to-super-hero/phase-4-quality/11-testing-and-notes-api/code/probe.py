from pathlib import Path
from secrets import token_hex
from tempfile import TemporaryDirectory

from fastapi.testclient import TestClient
from sqlalchemy import create_engine

from app import create_app
from models import Base
from security import issue_token
from settings import Settings


if __name__ == "__main__":
    with TemporaryDirectory() as folder:
        secret = token_hex(32)
        engine = create_engine(f"sqlite:///{(Path(folder) / 'notes.db').as_posix()}")
        Base.metadata.create_all(engine)
        config = Settings(database_url="sqlite://", jwt_secret=secret, _env_file=None)
        try:
            with TestClient(create_app(config, engine)) as client:
                ada = {"Authorization": f"Bearer {issue_token('ada', secret)}"}
                bob = {"Authorization": f"Bearer {issue_token('bob', secret)}"}
                created = client.post("/notes", json={"title": "Read docs"}, headers=ada)
                note_id = created.json()["id"]
                print("create:", created.status_code)
                print("owner:", client.get(f"/notes/{note_id}", headers=ada).status_code)
                print("other owner:", client.get(f"/notes/{note_id}", headers=bob).status_code)
                print("anonymous:", client.get("/notes").status_code)
        finally:
            engine.dispose()
