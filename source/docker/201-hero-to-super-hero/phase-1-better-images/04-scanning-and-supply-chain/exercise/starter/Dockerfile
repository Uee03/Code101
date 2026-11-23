FROM python:latest
# TODO 1: replace the floating tag above with the pinned version-family tag python:3.13-slim
# TODO 2: add an ARG VCS_REF and a LABEL block with title, description, source and revision (org.opencontainers.image.*)
RUN apt-get update && apt-get install -y curl git build-essential
# TODO 3: delete the line above; this program uses no extra packages
WORKDIR /app
COPY app.py ./
# TODO 4: run as the numeric user 10001:10001
CMD ["python", "app.py"]
