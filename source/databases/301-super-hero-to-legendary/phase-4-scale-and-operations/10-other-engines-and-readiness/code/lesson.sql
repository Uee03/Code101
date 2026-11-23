\set ON_ERROR_STOP on
\pset format unaligned
\pset footer off
\pset null '(null)'
\ir setup.sql
SELECT 'abc' = 'ABC' AS equals, 'abc' LIKE 'ABC' AS like_match, 'abc' ILIKE 'ABC' AS ilike_match;
SELECT (SELECT string_agg(n::text, ',' ORDER BY n)
        FROM (SELECT n FROM generate_series(1, 5) AS n ORDER BY n LIMIT 2 OFFSET 1) AS a) AS limit_offset,
       (SELECT string_agg(n::text, ',' ORDER BY n)
        FROM (SELECT n FROM generate_series(1, 5) AS n ORDER BY n OFFSET 1 ROWS FETCH NEXT 2 ROWS ONLY) AS b) AS fetch_next;
SELECT app.attempt('SELECT ''abc''::integer') AS text_into_integer;
SELECT check_name, object FROM (
    SELECT 'no_primary_key' AS check_name, format('%I.%I', n.nspname, c.relname) AS object
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'app' AND c.relkind IN ('r', 'p')
      AND NOT EXISTS (SELECT 1 FROM pg_constraint k WHERE k.conrelid = c.oid AND k.contype = 'p')
    UNION ALL
    SELECT 'fk_without_index', format('%I.%I.%I', n.nspname, c.relname, k.conname)
    FROM pg_constraint k
    JOIN pg_class c ON c.oid = k.conrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'app' AND k.contype = 'f'
      AND NOT EXISTS (SELECT 1 FROM pg_index i WHERE i.indrelid = k.conrelid AND i.indkey[0] = k.conkey[1])
    UNION ALL
    SELECT 'timestamp_without_tz', format('%I.%I.%I', n.nspname, c.relname, a.attname)
    FROM pg_attribute a
    JOIN pg_class c ON c.oid = a.attrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'app' AND c.relkind IN ('r', 'p') AND a.attnum > 0 AND NOT a.attisdropped
      AND format_type(a.atttypid, a.atttypmod) = 'timestamp without time zone'
) AS findings
ORDER BY check_name, object;
SELECT s.name, s.setting, v.target, s.setting = v.target AS meets
FROM (VALUES ('archive_mode', 'on'), ('data_checksums', 'on'), ('fsync', 'on'), ('full_page_writes', 'on'),
             ('idle_in_transaction_session_timeout', '60000'), ('password_encryption', 'scram-sha-256'),
             ('ssl', 'on'), ('statement_timeout', '30000')) AS v(name, target)
JOIN pg_settings s ON s.name = v.name
ORDER BY s.name;
