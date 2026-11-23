# syntax=docker/dockerfile:1
ARG BASE_IMAGE=python:3.13-slim
FROM ${BASE_IMAGE}
ARG VCS_REF=unknown
LABEL org.opencontainers.image.title="code101-provenance-demo" \
      org.opencontainers.image.source="https://github.com/Uee03/Code101" \
      org.opencontainers.image.revision="${VCS_REF}"
RUN useradd --system --uid 10001 --no-create-home --shell /usr/sbin/nologin app
WORKDIR /app
COPY app.py .
USER 10001:10001
CMD ["python", "app.py"]
