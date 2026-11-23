from collections.abc import Callable

from fastapi import FastAPI, Response, status

from taskservice import __version__


def create_app(dependency_ok: Callable[[], bool] = lambda: True) -> FastAPI:
    app = FastAPI(title="taskservice", docs_url=None, redoc_url=None)

    @app.get("/healthz")
    def healthz() -> dict[str, str]:
        return {"status": "alive"}

    @app.get("/readyz")
    def readyz(response: Response) -> dict[str, str]:
        if not dependency_ok():
            response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
            return {"status": "not ready"}
        return {"status": "ready"}

    @app.get("/version")
    def version() -> dict[str, str]:
        return {"version": __version__}

    return app


app = create_app()
