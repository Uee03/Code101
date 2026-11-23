from typing import Annotated

from fastapi import Depends, FastAPI, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jwt.exceptions import InvalidTokenError

from security import validate_token
from settings import Settings


def create_app(settings: Settings | None = None) -> FastAPI:
    config = settings if settings is not None else Settings()
    app = FastAPI(title="Bearer basics")
    bearer = HTTPBearer(auto_error=False)

    def current_subject(
        credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer)],
    ) -> str:
        if credentials is not None:
            try:
                return validate_token(credentials.credentials, config.jwt_secret.get_secret_value())
            except InvalidTokenError:
                pass
        raise HTTPException(status_code=401, detail="invalid credentials", headers={"WWW-Authenticate": "Bearer"})

    @app.get("/me")
    def me(subject: Annotated[str, Depends(current_subject)]) -> dict[str, str]:
        return {"subject": subject}

    return app
