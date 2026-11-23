#!/bin/sh
set -eu
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
FILE="/backups/orders-${STAMP}.dump"
START="$(date +%s)"
pg_dump --username="$POSTGRES_USER" --dbname="$POSTGRES_DB" --format=custom --file="$FILE"
pg_restore --list "$FILE" > /dev/null
END="$(date +%s)"
echo "backup written: $FILE"
echo "backup took $((END - START)) seconds"
