from sqlalchemy import create_engine, text

engine = create_engine("sqlite://")
with engine.begin() as connection:
    connection.execute(text("CREATE TABLE notes (title TEXT NOT NULL)"))
    title = "Ada's note"
    connection.execute(text("INSERT INTO notes (title) VALUES (:title)"), {"title": title})
    saved = connection.scalar(text("SELECT title FROM notes"))
    assert saved == title
    print(saved)
engine.dispose()
