from fastapi import APIRouter, Response

from app.dependencies import AppSettings, Db
from app.schemas import Health

router = APIRouter(tags=["Platform"])


@router.get("/health", response_model=Health, response_model_exclude_none=True)
def get_health(response: Response, db: Db, settings: AppSettings) -> Health:
    if db.ping():
        return Health(status="ok", version=settings.service_version, database="up")
    response.status_code = 503
    return Health(status="degraded", version=settings.service_version, database="down")
