# syntax=docker/dockerfile:1
FROM python:3.13-slim
ENV PYTHONDONTWRITEBYTECODE=1
RUN --mount=type=secret,id=build_token test -s /run/secrets/build_token && echo "build token received, not stored in the image"
WORKDIR /app
COPY --chmod=0444 app.py ./
USER 10001:10001
EXPOSE 8000
CMD ["python", "-u", "app.py"]
