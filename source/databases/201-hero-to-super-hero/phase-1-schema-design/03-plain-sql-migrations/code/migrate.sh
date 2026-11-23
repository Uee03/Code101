#!/bin/sh
set -eu
exec psql -X -q -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /scripts/migrate.sql
