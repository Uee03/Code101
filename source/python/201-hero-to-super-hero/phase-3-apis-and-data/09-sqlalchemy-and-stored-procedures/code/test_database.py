import unittest
from uuid import uuid4

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from database import make_engine
from main import add_note
from models import Note


class DatabaseTests(unittest.TestCase):
    def test_bound_quote_and_rollback(self) -> None:
        engine = make_engine()
        title = f"Ada's {uuid4().hex}"
        try:
            with Session(engine) as session:
                add_note(session, title)
                self.assertEqual(session.scalar(select(Note.title).where(Note.title == title)), title)
                session.rollback()
            with Session(engine) as session:
                self.assertIsNone(session.scalar(select(Note.id).where(Note.title == title)))
        finally:
            engine.dispose()

    def test_database_constraint(self) -> None:
        engine = make_engine()
        try:
            with Session(engine) as session:
                with self.assertRaises(IntegrityError):
                    add_note(session, " ")
                session.rollback()
        finally:
            engine.dispose()
