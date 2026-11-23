#!/bin/sh
set -eu
LATEST="$(ls -1 /backups/orders-*.dump 2>/dev/null | sort | tail -n 1)"
if [ -z "$LATEST" ]; then
  echo "no backup found in /backups" >&2
  exit 1
fi
echo "recovering from $LATEST"
pg_restore --username="$POSTGRES_USER" --dbname="$POSTGRES_DB" --clean --if-exists --no-owner "$LATEST"
psql --username="$POSTGRES_USER" --dbname="$POSTGRES_DB" --tuples-only --no-align --command='SELECT count(*) FROM orders'
