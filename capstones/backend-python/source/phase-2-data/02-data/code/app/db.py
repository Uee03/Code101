from collections.abc import Iterator
from contextlib import contextmanager
from uuid import UUID

from sqlalchemy import Connection, Engine, create_engine, text
from sqlalchemy.exc import SQLAlchemyError


class Database:
    """Owns the connection pool. Every request borrows a connection for the length of one transaction."""

    def __init__(self, url: str, pool_size: int, max_overflow: int) -> None:
        self.engine: Engine = create_engine(
            url,
            pool_size=pool_size,
            max_overflow=max_overflow,
            pool_timeout=5,
            pool_pre_ping=True,
            connect_args={"connect_timeout": 3},
        )

    @contextmanager
    def transaction(self, actor_id: UUID | None = None) -> Iterator[Connection]:
        """Commit when the block ends, roll back when it raises.

        With an actor, the first statement stores the user id in a transaction-local setting.
        The audit trigger and the stored functions read it, so every audit row names the caller.
        """
        with self.engine.begin() as conn:
            if actor_id is not None:
                conn.execute(text("SELECT set_config('app.current_user_id', :actor, true)"), {"actor": str(actor_id)})
            yield conn

    def ping(self) -> bool:
        try:
            with self.engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            return True
        except SQLAlchemyError:
            return False

    def dispose(self) -> None:
        self.engine.dispose()
