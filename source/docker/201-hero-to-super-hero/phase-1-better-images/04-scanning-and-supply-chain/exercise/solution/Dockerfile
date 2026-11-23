# syntax=docker/dockerfile:1
FROM python:3.13-slim
ARG VCS_REF=unknown
LABEL org.opencontainers.image.title="code101-supply" \
      org.opencontainers.image.description="Docker 201 supply-chain demo" \
      org.opencontainers.image.source="https://github.com/Uee03/Code101" \
      org.opencontainers.image.revision="${VCS_REF}"
WORKDIR /app
COPY --chmod=0444 app.py ./
USER 10001:10001
CMD ["python", "app.py"]
