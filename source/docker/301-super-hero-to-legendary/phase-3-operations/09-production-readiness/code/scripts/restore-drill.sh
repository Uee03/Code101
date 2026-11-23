#!/bin/sh
set -eu
LATEST="$(ls -1 /backups/orders-*.dump 2>/dev/null | sort | tail -n 1)"
if [ -z "$LATEST" ]; then
  echo "no backup found in /backups" >&2
  exit 1
fi
echo "restoring $LATEST into scratch database restore_drill"
START="$(date +%s)"
dropdb --username="$POSTGRES_USER" --if-exists restore_drill
createdb --username="$POSTGRES_USER" restore_drill
pg_restore --username="$POSTGRES_USER" --dbname=restore_drill --no-owner "$LATEST"
END="$(date +%s)"
SOURCE_ROWS="$(psql --username="$POSTGRES_USER" --dbname="$POSTGRES_DB" --tuples-only --no-align --command='SELECT count(*) FROM orders')"
RESTORED_ROWS="$(psql --username="$POSTGRES_USER" --dbname=restore_drill --tuples-only --no-align --command='SELECT count(*) FROM orders')"
echo "source rows: $SOURCE_ROWS, restored rows: $RESTORED_ROWS"
echo "restore took $((END - START)) seconds"
if [ "$SOURCE_ROWS" != "$RESTORED_ROWS" ]; then
  echo "DRILL FAILED: row counts differ" >&2
  exit 1
fi
dropdb --username="$POSTGRES_USER" restore_drill
echo "drill passed"
