FROM python:3.13-slim
ARG APP_VERSION=1.0.0
ENV APP_VERSION=${APP_VERSION} PYTHONUNBUFFERED=1
RUN useradd --system --uid 10001 --no-create-home --shell /usr/sbin/nologin app
WORKDIR /app
COPY app.py .
USER 10001:10001
EXPOSE 8080
CMD ["python", "app.py"]
