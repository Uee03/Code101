# syntax=docker/dockerfile:1
FROM python:3.14-slim AS build
WORKDIR /src
COPY pyproject.toml requirements.txt ./
COPY src ./src
RUN pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt .

FROM python:3.14-slim AS runtime
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
RUN useradd --system --uid 10001 --no-create-home app
COPY --from=build /wheels /wheels
RUN pip install --no-cache-dir --no-index --find-links=/wheels taskservice \
    && rm -rf /wheels
USER 10001
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz', timeout=2)"]
CMD ["uvicorn", "taskservice.app:app", "--host", "0.0.0.0", "--port", "8000"]
