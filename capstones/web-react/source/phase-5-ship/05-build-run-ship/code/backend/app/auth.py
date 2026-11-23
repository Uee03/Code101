import logging
from dataclasses import dataclass
from typing import Annotated, Any
from uuid import UUID

from fastapi import Depends, Request, Security
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer, SecurityScopes

from app.dependencies import AppSettings, Db, Limiter, Verifier
from app.errors import ProblemError, forbidden, unauthorized
from app.logging_config import log_fields
from app.ratelimit import FixedWindowLimiter
from app.repositories import users
from app.tokens import KeysUnavailable, TokenRejected

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


def principal_from_claims(claims: dict[str, Any]) -> Principal:
    """Turn the claims of an already verified token into a Principal."""
    try:
        user_id = UUID(str(claims["sub"]))
    except (KeyError, ValueError):
        raise unauthorized("The access token has no valid subject.") from None
    username = str(claims.get("preferred_username") or user_id)
    realm_access = claims.get("realm_access")
    roles = realm_access.get("roles", []) if isinstance(realm_access, dict) else []
    return Principal(
        user_id=user_id,
        username=username,
        email=str(claims.get("email") or f"{username}@users.invalid"),
        display_name=str(claims.get("name") or username),
        roles=frozenset(role for role in roles if isinstance(role, str) and role in KNOWN_ROLES),
        scopes=frozenset(str(claims.get("scope", "")).split()),
    )


def client_address(request: Request) -> str:
    return request.client.host if request.client else "unknown"


def enforce_limit(request: Request, limiter: FixedWindowLimiter, key: str, limit: int) -> None:
    """Count this request. The RateLimit-* headers are added to the response by RequestContextMiddleware."""
    decision = limiter.hit(key, limit)
    request.state.rate_headers = decision.headers()
    if not decision.allowed:
        raise ProblemError(429, f"Too many requests. Try again in {decision.reset_seconds} seconds.",
                           headers={"Retry-After": str(decision.reset_seconds), **decision.headers()})


def authenticate(
    security_scopes: SecurityScopes,
    request: Request,
    verifier: Verifier,
    db: Db,
    limiter: Limiter,
    settings: AppSettings,
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> Principal:
    """Dependency for every protected route: 429 when over the limit, 401 without a valid token, 403 without the required scopes."""
    anonymous_key = f"ip:{client_address(request)}"
    if credentials is None:
        enforce_limit(request, limiter, anonymous_key, settings.rate_limit_anonymous)
        raise unauthorized("A bearer access token is required.")
    try:
        claims = verifier.verify(credentials.credentials)
    except TokenRejected as rejected:
        enforce_limit(request, limiter, anonymous_key, settings.rate_limit_anonymous)
        logger.warning("token rejected", extra=log_fields(event="token_rejected", reason=rejected.reason))
        raise unauthorized(rejected.public, {"WWW-Authenticate": 'Bearer realm="tasksteams", error="invalid_token"'}) from None
    except KeysUnavailable as unavailable:
        logger.error("signing keys unavailable: %s", unavailable)
        raise ProblemError(503, "The sign-in keys cannot be fetched right now.", headers={"Retry-After": "5"}) from None
    principal = principal_from_claims(claims)
    request.state.user_id = str(principal.user_id)
    enforce_limit(request, limiter, f"user:{principal.user_id}", settings.rate_limit_user)
    missing = [scope for scope in security_scopes.scopes if scope not in principal.scopes]
    if missing:
        raise forbidden(f"The scope {missing[0]} is required.")
    if principal.user_id not in _known_users:
        with db.transaction() as conn:
            users.ensure_user(conn, principal.user_id, principal.username, principal.email, principal.display_name)
        _known_users.add(principal.user_id)
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
