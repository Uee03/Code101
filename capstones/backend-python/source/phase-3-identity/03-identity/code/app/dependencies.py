from typing import Annotated

from fastapi import Depends, Request

from app.config import Settings, get_settings
from app.db import Database
from app.tokens import TokenVerifier


def get_db(request: Request) -> Database:
    return request.app.state.db


def get_verifier(request: Request) -> TokenVerifier:
    return request.app.state.verifier


Db = Annotated[Database, Depends(get_db)]
Verifier = Annotated[TokenVerifier, Depends(get_verifier)]
AppSettings = Annotated[Settings, Depends(get_settings)]
