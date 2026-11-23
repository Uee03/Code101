from sqlalchemy import create_engine, text

engine = create_engine("sqlite://")
with engine.begin() as connection:
    connection.execute(text("CREATE TABLE notes (title TEXT NOT NULL)"))
    title = "Ada's note"
    # TODO: insert title using text() and a separate parameter dictionary.
    saved = connection.scalar(text("SELECT title FROM notes"))
    assert saved == title
    print(saved)
engine.dispose()
