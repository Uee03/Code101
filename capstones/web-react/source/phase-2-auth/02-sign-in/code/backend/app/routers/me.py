from fastapi import APIRouter

from app.auth import Reader
from app.dependencies import Db
from app.repositories import members, users
from app.schemas import Me, TeamRef

router = APIRouter(prefix="/v1", tags=["Platform"])


@router.get("/me", response_model=Me)
def get_me(principal: Reader, db: Db) -> Me:
    with db.transaction() as conn:
        user = users.get_user(conn, principal.user_id)
        teams = members.teams_of(conn, principal.user_id)
    assert user is not None  # authenticate() stored the row on first use
    return Me(
        id=user["id"],
        username=user["username"],
        email=user["email"],
        display_name=user["display_name"],
        roles=sorted(principal.roles),
        scopes=sorted(principal.scopes),
        teams=[TeamRef.model_validate(team) for team in teams],
    )
