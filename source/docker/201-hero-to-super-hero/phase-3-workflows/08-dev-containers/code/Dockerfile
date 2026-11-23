# syntax=docker/dockerfile:1
FROM python:3.13-slim
ENV PYTHONDONTWRITEBYTECODE=1
WORKDIR /srv
COPY app ./app
USER 10001:10001
EXPOSE 8000
CMD ["python", "-u", "-m", "app.main"]
