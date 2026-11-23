from uuid import UUID

from fastapi import APIRouter

from app.schemas import Me

router = APIRouter(prefix="/v1", tags=["Platform"])

ALICE_ID = UUID("a11ce000-0000-4000-8000-000000000001")


@router.get("/me", response_model=Me)
def get_me() -> Me:
    """Stub for phase 1: always alice. Phase 2 reads the real user, phase 3 the real token."""
    return Me(
        id=ALICE_ID,
        username="alice",
        email="alice@tasksteams.test",
        display_name="Alice Admin",
        roles=["admin"],
        scopes=["tasks:read", "tasks:write", "tasks:admin"],
        teams=[],
    )
