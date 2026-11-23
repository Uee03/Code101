\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
SELECT current_setting('max_connections')::int AS max_connections,
       current_setting('superuser_reserved_connections')::int AS superuser_reserved,
       current_setting('reserved_connections')::int AS reserved;
SELECT service, instances * pool_per_instance AS connections FROM app.services ORDER BY service;
SELECT sum(instances * pool_per_instance) AS demand,
       current_setting('max_connections')::int - current_setting('superuser_reserved_connections')::int
         - current_setting('reserved_connections')::int AS available,
       10 AS ops_reserve,
       sum(instances * pool_per_instance) <= current_setting('max_connections')::int
         - current_setting('superuser_reserved_connections')::int
         - current_setting('reserved_connections')::int - 10 AS fits
FROM app.services;
WITH base AS (
    SELECT (SELECT pool_per_instance FROM app.services WHERE service = 'api') AS api_pool,
           (SELECT sum(instances * pool_per_instance) FROM app.services WHERE service <> 'api') AS others,
           current_setting('max_connections')::int - current_setting('superuser_reserved_connections')::int
             - current_setting('reserved_connections')::int - 10 AS budget
)
SELECT n AS api_instances, n * api_pool + others AS demand, n * api_pool + others <= budget AS fits
FROM base, generate_series(4, 10, 2) AS n
ORDER BY n;
SELECT round(500 * 0.020, 1) AS busy_connections, ceil(500 * 0.020 / 0.7) AS pool_at_70_percent;
SET app.tenant_id = 'leaky';
BEGIN;
SET LOCAL app.tenant_id = 'scoped';
SELECT current_setting('app.tenant_id') AS inside_transaction;
COMMIT;
SELECT current_setting('app.tenant_id') AS after_commit_session_set;
RESET app.tenant_id;
SELECT nullif(current_setting('app.tenant_id', true), '') AS after_reset;
