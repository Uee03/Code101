from sqlalchemy import select, text
from sqlalchemy.orm import Session

from database import make_engine
from models import Note


def add_note(session: Session, title: str) -> None:
    session.execute(text("CALL add_note(:title)"), {"title": title})


if __name__ == "__main__":
    engine = make_engine()
    try:
        with Session(engine) as session:
            with session.begin():
                add_note(session, "Read SQLAlchemy")
            title = session.scalar(select(Note.title).where(Note.title == "Read SQLAlchemy").limit(1))
            print(f"saved: {title == 'Read SQLAlchemy'}")
    finally:
        engine.dispose()
