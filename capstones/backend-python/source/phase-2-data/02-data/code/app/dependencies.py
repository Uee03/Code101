from typing import Annotated

from fastapi import Depends, Request

from app.config import Settings, get_settings
from app.db import Database


def get_db(request: Request) -> Database:
    return request.app.state.db


Db = Annotated[Database, Depends(get_db)]
AppSettings = Annotated[Settings, Depends(get_settings)]
