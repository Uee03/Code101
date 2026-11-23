\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir /scripts/setup.sql
INSERT INTO app.services (service, instances, pool_per_instance) VALUES ('reports', 2, 8);
SELECT sum(instances * pool_per_instance) AS demand,
       sum(instances * pool_per_instance) <= 97 - 10 AS fits
FROM app.services;
