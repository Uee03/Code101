-- Calls the stored functions inside one transaction and rolls everything back at the end.
\set ON_ERROR_STOP on
BEGIN;

SELECT assignee_id = 'ca401000-0000-4000-8000-000000000003' AS assigned_to_carol, version
FROM reassign_task('7a500000-0000-4000-8000-000000000004', 'ca401000-0000-4000-8000-000000000003', 'b0b00000-0000-4000-8000-000000000002', 1);

SELECT status, completed_at IS NOT NULL AS has_completed_at, version
FROM complete_task('7a500000-0000-4000-8000-000000000004', 'b0b00000-0000-4000-8000-000000000002', 2);

CREATE TEMP TABLE probe (step text, result text);
DO $$
BEGIN
    PERFORM complete_task('7a500000-0000-4000-8000-000000000006', 'b0b00000-0000-4000-8000-000000000002', 99);
    INSERT INTO probe VALUES ('stale version', 'accepted');
EXCEPTION WHEN SQLSTATE 'TS412' THEN
    INSERT INTO probe VALUES ('stale version', 'rejected: ' || SQLERRM);
END
$$;
SELECT step, result FROM probe;

SELECT action, entity_type, details ->> 'status' AS new_status, details ->> 'assignee_id' AS new_assignee
FROM audit_log
WHERE entity_id = '7a500000-0000-4000-8000-000000000004'
ORDER BY id DESC
LIMIT 2;

ROLLBACK;
