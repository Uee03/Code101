#!/usr/bin/env sh
set -eu

STAMP="$(date +%Y%m%d-%H%M%S)"
FILE="backups/notes-${STAMP}.dump"

mkdir -p backups
docker compose exec -T db pg_dump -U learner -d workshop -Fc -f /tmp/notes.dump
docker compose cp db:/tmp/notes.dump "$FILE"
docker compose exec -T db rm -f /tmp/notes.dump
echo "wrote $FILE"
ls -1t backups/notes-*.dump | tail -n +4 | while read -r old; do rm -f "$old"; done
echo "kept $(ls -1 backups/notes-*.dump | wc -l | tr -d ' ') dumps"
