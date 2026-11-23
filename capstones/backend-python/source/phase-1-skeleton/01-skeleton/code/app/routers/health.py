from fastapi import APIRouter, Depends

from app.config import Settings, get_settings
from app.schemas import Health

router = APIRouter(tags=["Platform"])


@router.get("/health", response_model=Health, response_model_exclude_none=True)
def get_health(settings: Settings = Depends(get_settings)) -> Health:
    return Health(status="ok", version=settings.service_version)
