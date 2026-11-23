import base64
import json
import logging
from dataclasses import dataclass
from typing import Annotated, Any
from uuid import UUID

from fastapi import Depends, Request, Security
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer, SecurityScopes

from app.db import Database
from app.dependencies import get_db
from app.errors import forbidden, unauthorized
from app.repositories import users

logger = logging.getLogger("tasksteams.auth")
bearer_scheme = HTTPBearer(auto_error=False)
KNOWN_ROLES = {"admin", "member"}
_known_users: set[UUID] = set()  # ids already stored in this process, so most requests skip the INSERT


@dataclass(frozen=True)
class Principal:
    """Who is calling, as the rest of the code sees it. Nothing below the HTTP layer knows about tokens."""

    user_id: UUID
    username: str
    email: str
    display_name: str
    roles: frozenset[str]
    scopes: frozenset[str]

    @property
    def is_admin(self) -> bool:
        return "admin" in self.roles


def read_claims(token: str) -> dict[str, Any]:
    """DEVELOPMENT ONLY (phase 2): reads the payload and trusts it. Phase 3 replaces this with real validation."""
    try:
        payload = token.split(".")[1]
        claims = json.loads(base64.urlsafe_b64decode(payload + "=" * (-len(payload) % 4)))
        if not isinstance(claims, dict):
            raise ValueError("payload is not an object")
        return claims
    except (IndexError, ValueError):
        raise unauthorized("The access token is malformed.") from None


def principal_from_claims(claims: dict[str, Any]) -> Principal:
    try:
        user_id = UUID(str(claims["sub"]))
    except (KeyError, ValueError):
        raise unauthorized("The access token has no valid subject.") from None
    username = str(claims.get("preferred_username") or user_id)
    roles = claims.get("realm_access", {}).get("roles", [])
    return Principal(
        user_id=user_id,
        username=username,
        email=str(claims.get("email") or f"{username}@users.invalid"),
        display_name=str(claims.get("name") or username),
        roles=frozenset(role for role in roles if role in KNOWN_ROLES),
        scopes=frozenset(str(claims.get("scope", "")).split()),
    )


def authenticate(
    security_scopes: SecurityScopes,
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: Database = Depends(get_db),
) -> Principal:
    """Dependency for every protected route: 401 without a usable token, 403 without the required scopes."""
    if credentials is None:
        raise unauthorized("A bearer access token is required.")
    principal = principal_from_claims(read_claims(credentials.credentials))
    missing = [scope for scope in security_scopes.scopes if scope not in principal.scopes]
    if missing:
        raise forbidden(f"The scope {missing[0]} is required.")
    if principal.user_id not in _known_users:
        with db.transaction() as conn:
            users.ensure_user(conn, principal.user_id, principal.username, principal.email, principal.display_name)
        _known_users.add(principal.user_id)
    request.state.user_id = str(principal.user_id)
    return principal


def require_admin(principal: Principal = Security(authenticate)) -> Principal:
    if not principal.is_admin:
        raise forbidden("The admin role is required.")
    return principal


# Route parameters: `principal: Reader` means "signed in, with scope tasks:read". The scope decides what the
# CLIENT may do, the role decides what the USER may do, and a request needs both.
Reader = Annotated[Principal, Security(authenticate, scopes=["tasks:read"])]
Writer = Annotated[Principal, Security(authenticate, scopes=["tasks:write"])]
AdminWriter = Annotated[Principal, Security(require_admin, scopes=["tasks:write"])]
AdminOnly = Annotated[Principal, Security(require_admin, scopes=["tasks:admin"])]
