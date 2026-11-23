# Production readiness review: orders database

Reviewer: (your name)  Date: (today)

Evidence: the output of `lesson.sql` (checks and settings) and the schema in `setup.sql`.

## Findings

| # | Finding (what you saw) | Risk if left alone | Severity (blocker, high, medium, low) | Fix (one concrete step) | How you will verify the fix |
|---|---|---|---|---|---|
| 1 | `archive_mode` is off, so there is no WAL archive | No point-in-time recovery; a bad `DELETE` or a lost disk loses everything since the last dump | blocker | Enable archiving to storage in another failure domain, take a base backup, add `pg_stat_archiver` alerts | Timed restore drill to a chosen time; fingerprint query matches |
| 2 | `app.audit_events` has no primary key | Cannot be replicated logically or de-duplicated; updates and deletes by key are impossible | high | Add an identity primary key in a migration | The no_primary_key check returns no rows |
| 3 | `fk_orders_customer` has no index on `orders.customer_id` | Deleting or updating a customer scans `orders` and holds locks longer; joins on the column scan | high | `CREATE INDEX CONCURRENTLY ix_orders_customer ON app.orders (customer_id)` | The fk_without_index check returns no rows; plan for a customer delete shows an index scan |
| 4 | `orders.total` is `double precision` | Binary floating point cannot represent money exactly; totals drift by fractions of a cent | high | Migrate to `numeric(12,2)` or integer cents (expand, backfill, contract) | The float_money check returns no rows; reconciliation of totals before and after matches to the cent |
| 5 | `timestamp` columns have no time zone | Offsets are lost; ambiguous around daylight-saving changes and across regions | medium | Convert to `timestamptz`, stating the zone the old values were in | The timestamp_without_tz check returns no rows; sample rows compared before and after |
| 6 | `statement_timeout` and `idle_in_transaction_session_timeout` are 0 | A runaway query or forgotten transaction holds locks and connections indefinitely | medium | Set per-role timeouts for the application role | `SHOW` as the application role returns the new values |
| 7 | `ssl` is off and `data_checksums` is off | Traffic is unencrypted; silent disk corruption can go undetected | high for `ssl` on any network beyond loopback, medium for checksums (needs a new cluster or an offline enable) | Enable TLS with a verified certificate; plan checksums for the next rebuild | `pg_stat_ssl` shows encrypted connections; the settings table passes |

## Decision

- [ ] Ready for production
- [ ] Ready with conditions (list them)
- [x] Not ready (list blockers)

Reason for the decision (two sentences): There is no archive for point-in-time recovery, which is a blocker for any data we cannot recreate. Several schema and security findings are cheap to fix now and expensive after launch.
