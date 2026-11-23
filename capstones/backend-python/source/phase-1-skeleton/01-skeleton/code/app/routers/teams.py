from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends, Response

from app.config import Settings, get_settings
from app.routers.me import ALICE_ID
from app.schemas import Team, TeamCreate

router = APIRouter(prefix="/v1/teams", tags=["Teams"])


@router.post("", response_model=Team, status_code=201)
def create_team(body: TeamCreate, response: Response, settings: Settings = Depends(get_settings)) -> Team:
    """Stub for phase 1: checks the DTO and answers like the real endpoint, but stores nothing."""
    now = datetime.now(timezone.utc)
    team = Team(
        id=uuid4(),
        name=body.name,
        description=body.description,
        member_count=1,
        created_by=ALICE_ID,
        version=1,
        created_at=now,
        updated_at=now,
    )
    response.headers["Location"] = f"{settings.public_base_url.rstrip('/')}/v1/teams/{team.id}"
    response.headers["ETag"] = f'"{team.version}"'
    return team
