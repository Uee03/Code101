#!/usr/bin/env sh
set -eu

STAMP="$(date +%Y%m%d-%H%M%S)"
FILE="backups/notes-${STAMP}.dump"

mkdir -p backups
docker compose exec -T db pg_dump -U learner -d workshop -Fc -f /tmp/notes.dump
docker compose cp db:/tmp/notes.dump "$FILE"
docker compose exec -T db rm -f /tmp/notes.dump
echo "wrote $FILE"
