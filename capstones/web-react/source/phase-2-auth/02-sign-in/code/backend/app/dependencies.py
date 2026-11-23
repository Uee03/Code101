from typing import Annotated

from fastapi import Depends, Request

from app.config import Settings, get_settings
from app.db import Database
from app.ratelimit import FixedWindowLimiter
from app.tokens import TokenVerifier


def get_db(request: Request) -> Database:
    return request.app.state.db


def get_verifier(request: Request) -> TokenVerifier:
    return request.app.state.verifier


def get_limiter(request: Request) -> FixedWindowLimiter:
    return request.app.state.limiter


Db = Annotated[Database, Depends(get_db)]
Verifier = Annotated[TokenVerifier, Depends(get_verifier)]
Limiter = Annotated[FixedWindowLimiter, Depends(get_limiter)]
AppSettings = Annotated[Settings, Depends(get_settings)]
