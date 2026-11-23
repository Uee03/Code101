# Databases glossary

Plain-language definitions introduced in Databases 101. PostgreSQL runs only in Docker.

| Term | Meaning | First lesson |
|---|---|---|
| database | An organised collection of saved facts. | 01 |
| database server | A program that stores data and answers client requests. | 01 |
| PostgreSQL (Postgres) | The relational database server used in this track. | 01 |
| SQL | Structured Query Language, used to read and change relational data. | 01 |
| query | A request written in SQL. | 01 |
| client | A program that sends requests to a server. | 01 |
| psql | The text-based PostgreSQL client, run inside Docker here. | 01 |
| image | A packaged starting point for a container. | 01 |
| container | An isolated running instance of an image. | 01 |
| Compose | Docker tool that starts services described in a YAML file. | 01 |
| YAML | The indentation-based file format used by Compose. | 01 |
| service | A named application component in Compose, here db. | 01 |
| port | A numbered network entrance to a program. | 01 |
| host | The computer running Docker, or a connection address field. | 01 |
| localhost | A name for the machine on which the client is running. | 01 |
| named volume | Docker-managed storage that outlives a container. | 01 |
| bind mount | A host folder made visible inside a container. | 01 |
| healthcheck | A repeated readiness check on a running service. | 01 |
| environment variable | A named setting supplied to a program. | 01 |
| literal | A value written directly in a query. | 01 |
| result column alias | An output heading assigned using AS. | 01 |
| connection | A communication channel between client and server. | 02 |
| connection string | Connection settings expressed in one string. | 02 |
| driver | A client library that communicates with a database server. | 02 |
| IDE | Integrated development environment: an editor plus development tools. | 02 |
| authentication | Checking who is connecting. | 02 |
| SSL/TLS | Encryption protocols for network connections. | 02 |
| function | A named operation that returns a result. | 02 |
| socket | An internal communication endpoint; psql can use a local Unix socket inside the container. | 02 |
| table | A collection of rows with the same named columns. | 03 |
| row | One record in a table. | 03 |
| column | A named kind of fact in a table. | 03 |
| schema | A named group of database objects. | 03 |
| data type | A rule for what kind of value a column stores. | 03 |
| integer | A whole-number type. | 03 |
| bigint | A whole-number type with a larger range than integer. | 03 |
| text | A type for character strings. | 03 |
| numeric(p,s) | An exact decimal type with p total digits and s fractional digits. | 03 |
| boolean | A true/false type. | 03 |
| date | A calendar date without a time of day. | 03 |
| NULL | A marker for a missing or unknown value. | 03 |
| statement | One complete SQL instruction, usually ending in a semicolon. | 03 |
| CASCADE | Also remove dependent objects when dropping a schema here. | 03 |
| filter | A condition that determines which rows are kept. | 04 |
| condition | An expression tested by WHERE, JOIN or HAVING. | 04 |
| pattern | A template used for text matching, for example F%. | 04 |
| ORDER BY | The clause that sorts results. | 04 |
| LIMIT | The clause that caps the number of returned rows. | 04 |
| DESC | Descending sort order, from larger to smaller values. | 04 |
| UPDATE | A statement that changes existing rows. | 05 |
| SET | The assignment clause in UPDATE, or a session-setting statement in other contexts. | 05 |
| DELETE | A statement that removes matching rows. | 05 |
| RETURNING | A clause that returns rows affected by a write. | 05 |
| primary key | A unique, non-NULL identifier for each row. | 06 |
| identity | A column whose values are generated automatically by PostgreSQL. | 06 |
| foreign key | A rule requiring a non-NULL reference to match a key in another table. | 06 |
| relationship | A connection between related rows in different tables. | 06 |
| one-to-many | A relationship where one parent row can have several child rows. | 06 |
| constraint | A rule enforced by the database. | 06 |
| RESTRICT | Reject an operation that would break a referenced relationship. | 06 |
| join | A query operation that combines matching rows from tables. | 07 |
| table alias | A short query-local name for a table. | 07 |
| INNER JOIN | A join that returns only matched pairs. | 07 |
| LEFT JOIN | A join that also keeps unmatched rows from its left table. | 07 |
| ON | The clause giving a join matching condition. | 07 |
| aggregate | An operation that combines multiple rows into one result. | 08 |
| COUNT | An aggregate that counts rows, or non-NULL values of a column. | 08 |
| SUM | An aggregate that adds values. | 08 |
| AVG | An aggregate that calculates the arithmetic mean of non-NULL values. | 08 |
| GROUP BY | A clause that forms groups for aggregates. | 08 |
| HAVING | A condition applied after grouping. | 08 |
| ROUND | A function that rounds a numeric value to a requested number of decimal places. | 08 |
| normalization | Organising facts to reduce duplication and conflicting updates. | 09 |
| NOT NULL | A constraint requiring a value. | 09 |
| UNIQUE | A constraint rejecting duplicate values or combinations. | 09 |
| CHECK | A constraint requiring an expression not to be false. | 09 |
| DEFAULT | A value supplied when a column is omitted or DEFAULT is requested. | 09 |
| snake_case | Lowercase names with words separated by underscores. | 09 |
| CURRENT_DATE | The current calendar date according to the database session. | 09 |
| transaction | A group of changes treated as one all-or-nothing unit. | 10 |
| BEGIN | Start an explicit transaction. | 10 |
| COMMIT | Make the current transaction permanent. | 10 |
| ROLLBACK | Cancel the current uncommitted transaction. | 10 |
| autocommit | The default behaviour of committing each statement separately outside an explicit transaction. | 10 |
| index | An extra lookup structure that can speed some queries while adding maintenance cost. | 11 |
| planner | The database component that chooses an execution strategy. | 11 |
| query plan | The operations PostgreSQL proposes for answering a query. | 11 |
| sequential scan | Reading a table through rather than using an index lookup. | 11 |
| index scan | Using an index to locate rows. | 11 |
| ANALYZE | A command that gathers table statistics for the planner. | 11 |
| EXPLAIN | A command that displays a query plan; EXPLAIN ANALYZE also executes it. | 11 |
| entity | A kind of thing about which we store facts, such as a member or book. | 12 |
| seed | An initial dataset used to populate a database. | 12 |
| parameterized query | A query whose input values are bound separately from its SQL structure. | 12 |
| prepared statement | A named SQL statement that can receive parameter values in a session. | 12 |
| role | A PostgreSQL permission identity, with or without login ability. | 12 |
| NOLOGIN | A role property that prevents using that role to log in directly. | 12 |
| GRANT | A statement giving a role a permission. | 12 |
| least privilege | Giving only the permissions needed for a task. | 12 |
| backup | A separate copy from which data can be recovered. | 12 |
| restore | Reconstructing a database from a backup. | 12 |
| pg_dump | The PostgreSQL tool that exports one database. | 12 |
| pg_restore | The PostgreSQL tool that restores a custom-format dump. | 12 |
| ACL | Access control list: stored permission grants. | 12 |

## Databases 201 additions

Lesson numbers below refer to level 201, not the existing 101 entries.

| Term | Meaning | First lesson |
|---|---|---|
| functional dependency | A rule that each value of one set of columns determines one value of another set. | 201.01 |
| candidate key | A minimal set of columns that uniquely identifies a row. | 201.01 |
| business key | An identifier meaningful to the domain, such as a product SKU. | 201.01 |
| surrogate key | An identifier without business meaning, such as a generated identity. | 201.01 |
| update anomaly | A contradiction risk caused by storing one logical fact in several places. | 201.01 |
| first normal form (1NF) | For the stated model, rows have atomic attribute values rather than repeating groups or encoded lists. | 201.01 |
| second normal form (2NF) | 1NF with no non-key attribute depending on only part of a candidate key. | 201.01 |
| third normal form (3NF) | For each nontrivial dependency X -> A, X is a superkey or A belongs to some candidate key. | 201.01 |
| partial dependency | A dependency of a non-key fact on only part of a candidate key. | 201.01 |
| transitive dependency | A dependency that passes through another non-key fact, as order -> customer -> current name. | 201.01 |
| historical snapshot | A stored fact as it was at an event, distinct from a mutable current value. | 201.01 |
| domain | A reusable PostgreSQL base type with optional constraints. | 201.02 |
| enum | A named ordered set of type-safe labels. | 201.02 |
| composite type | A named row-shaped value with field names and types, not automatic table constraints. | 201.02 |
| invariant | A condition that must remain true for valid data. | 201.02 |
| lookup table | A referenced table of allowed values, often including descriptions or retirement state. | 201.02 |
| bool_and | An aggregate that returns true when all non-NULL input Boolean values are true. | 201.02 |
| migration | A versioned schema or data change applied in a controlled order. | 201.03 |
| migration ledger | A table recording versions that committed successfully. | 201.03 |
| idempotency | Repeating an operation has the same final effect as applying it once. | 201.03 |
| schema drift | Unexpected differences between the intended and actual schema. | 201.03 |
| expand/backfill/contract | Evolve compatibly: add a new shape, populate it, migrate clients, then remove the old shape. | 201.03 |
| CTE (common table expression) | A named query result available for one SQL statement through WITH. | 201.04 |
| recursive query | A query whose recursive term consumes prior working results until no new work remains. | 201.04 |
| anchor | The non-recursive starting term of a recursive query. | 201.04 |
| adjacency list | A hierarchy representation storing each node with its immediate parent reference. | 201.04 |
| cycle | A path that returns to a previously visited node. | 201.04 |
| CTE materialization | Evaluating a CTE separately for reuse within one statement rather than folding it into the parent. | 201.04 |
| window function | A calculation over related query rows that retains individual result rows. | 201.05 |
| partition | The group of related rows selected by a window PARTITION BY clause. | 201.05 |
| window frame | The subset of a window partition used for a frame-sensitive calculation at a row. | 201.05 |
| peer rows | Rows equal according to a window ORDER BY, such as tied sale amounts. | 201.05 |
| row_number | A window function assigning a distinct sequential position within a partition. | 201.05 |
| rank | A window function assigning equal rank to peers and leaving gaps afterward. | 201.05 |
| dense_rank | A window function ranking peer groups without gaps. | 201.05 |
| lag | A window function reading a prior row in the partition order. | 201.05 |
| JSONB | PostgreSQL decomposed binary JSON storage supporting document operations and indexes. | 201.06 |
| JSON containment | Testing whether one JSONB value contains another with @>. | 201.06 |
| JSON null | An explicit JSON value, distinct from missing extraction yielding SQL NULL. | 201.06 |
| GIN | Generalized Inverted Index: a lookup structure mapping document components to rows. | 201.06 |
| expression index | An index storing the value of an expression, usable by matching predicates. | 201.06 |
| operator class | The operations and semantics an index supports for a data type. | 201.06 |
| B-tree | An ordered index suitable for equality, range and compatible ordering operations. | 201.07 |
| partial index | An index containing only rows that satisfy its predicate. | 201.07 |
| covering index | An index holding all values required by a particular query, often using INCLUDE payload. | 201.07 |
| heap | The table row storage, separate from a PostgreSQL index. | 201.07 |
| index-only scan | A scan obtaining needed values from the index, with possible heap visibility checks. | 201.07 |
| visibility map | Per-heap-page visibility information that can let index-only scans avoid heap visits. | 201.07 |
| selectivity | How small a fraction of rows a predicate matches. | 201.07 |
| buffer hit | A page request satisfied from PostgreSQL shared buffers. | 201.07 |
| bitmap scan | An index/heap access strategy collecting locations before visiting table pages. | 201.07 |
| view | A stored query definition whose rows are computed when referenced. | 201.08 |
| materialized view | A stored query result replaced only by explicit refresh. | 201.08 |
| refresh | Replacing a materialized view result by rerunning its defining query. | 201.08 |
| PL/pgSQL | PostgreSQL procedural language adding branching, variables and exceptions around SQL. | 201.09 |
| stored procedure | A named database operation invoked with CALL rather than as a SELECT expression. | 201.09 |
| SQLSTATE | A five-character machine-readable status/error code, including application-defined errors. | 201.09 |
| STRICT function | A function returning NULL without executing its body if any input argument is NULL. | 201.09 |
| IMMUTABLE function | A function promising equal results for equal inputs without mutable external dependencies. | 201.09 |
| SECURITY INVOKER | Routine or view behavior using the caller privileges for the relevant access checks. | 201.09 |
| trigger | A database event hook that automatically calls a function. | 201.10 |
| row trigger | A trigger invoked once per affected row rather than once per statement. | 201.10 |
| audit trail | Stored change history; this example is transactional and not tamper-proof security logging. | 201.10 |
| RLS (row-level security) | Policies that filter/check rows in addition to ordinary object privileges. | 201.11 |
| policy | An RLS rule using USING for existing rows and WITH CHECK for proposed rows. | 201.11 |
| BYPASSRLS | A role attribute that bypasses row security; superusers bypass it too. | 201.11 |
| connection pool | A bounded reusable set of database connections shared across application work. | 201.11 |
| transaction pooling | A pooling mode in which a server connection can be reassigned after each transaction. | 201.11 |
| logical backup | An export of database definitions/data, distinct from continuous physical recovery. | 201.11 |
| superkey | Any set of columns that uniquely identifies a row, not necessarily a minimal one. | 201.01 |

Terms introduced in Databases 301 (Super Hero to Legendary):

| Term | Meaning | First lesson |
|---|---|---|
| pg_stat_statements | An extension keeping cumulative counters (calls, time, rows, buffers) per normalised statement. | 301.01 |
| normalised statement | A query text with constants replaced by placeholders (`$1`), so queries differing only in values share one entry. | 301.01 |
| plan node | One step of a query plan (a scan, join or sort); a plan is a tree of nodes. | 301.01 |
| buffer hit / read | A page found in PostgreSQL's shared buffers versus a page requested from the operating system. | 301.01 |
| sargable | A predicate in a form an index can answer, such as `column op constant` without a function on the column. | 301.01 |
| keyset pagination | Paging with `WHERE key > last_seen ORDER BY key LIMIT n` instead of a growing `OFFSET`. | 301.01 |
| dead tuple | An old row version that no transaction can see any more and that vacuum can reclaim. | 301.02 |
| bloat | Table or index space occupied by dead or unused row versions. | 301.02 |
| vacuum / autovacuum | The job that reclaims dead tuples, updates visibility information and freezes old transaction IDs; autovacuum runs it in the background. | 301.02 |
| extended statistics | Multi-column planner statistics created with `CREATE STATISTICS` (dependencies, ndistinct, mcv). | 301.02 |
| functional dependency | A relationship where one column's value determines another's, which breaks the planner's independence assumption. | 301.02 |
| xmin horizon | The oldest snapshot still in use; vacuum cannot remove row versions newer than it. | 301.02 |
| HOT update | A heap-only tuple update that avoids index changes when the new version fits on the same page. | 301.02 |
| partition key | The column or expression that decides which partition holds a row. | 301.03 |
| partition pruning | The planner or executor skipping partitions that cannot match the query's conditions on the key. | 301.03 |
| default partition | The partition that receives rows matching no other partition. | 301.03 |
| attach / detach | Turning an existing table into a partition of a partitioned table, and back. | 301.03 |
| isolation level | How much of other sessions' concurrent work a transaction can see (Read Committed, Repeatable Read, Serializable). | 301.04 |
| snapshot | The set of committed changes a statement or transaction can see. | 301.04 |
| lost update | Two sessions read a value and write results computed from it, so the second write silently overwrites the first. | 301.04 |
| row lock | A lock on a row version taken by `UPDATE`, `DELETE` or `SELECT ... FOR UPDATE`; plain reads do not wait for it. | 301.04 |
| deadlock | Two or more transactions each waiting for a lock the other holds; PostgreSQL aborts one. | 301.04 |
| serialization failure | An abort (SQLSTATE 40001) that protects the isolation guarantee; the application retries the whole transaction. | 301.04 |
| advisory lock | An application-defined lock on a number that PostgreSQL stores but gives no meaning. | 301.04 |
| SKIP LOCKED | A locking option that skips rows already locked, used for work queues. | 301.04 |
| connection budget | The server's connections minus reserved ones, shared by every client pool. | 301.05 |
| Little's law | Average busy servers equal arrival rate times average time in the system; used to size pools. | 301.05 |
| pool mode | When a pooled server connection returns to the pool: session, transaction or statement. | 301.05 |
| permissive / restrictive policy | RLS policies combined with OR (permissive) or AND (restrictive). | 301.06 |
| leakproof function | A function that cannot reveal its arguments through errors or side channels, so the planner may run it before a policy filter. | 301.06 |
| context claim | A per-request value such as `app.tenant_id` that RLS policies trust; a claim, not authentication. | 301.06 |
| tenant | One customer organisation whose data must stay separate from other customers'. | 301.07 |
| pool model / silo model | Tenants sharing tables with a `tenant_id`, versus one schema or database per tenant. | 301.07 |
| noisy neighbour | One tenant's load degrading the others sharing the same resources. | 301.07 |
| composite key | A key made of several columns, such as `(tenant_id, id)`, used so references cannot cross tenants. | 301.07 |
| fan-out migration | A change that must be repeated for every tenant schema or database. | 301.07 |
| ADR (architecture decision record) | A short record of a decision: context, decision, consequences and when to revisit. | 301.07 |
| WAL (write-ahead log) | The sequential record of every change, written before the data files change. | 301.08 |
| LSN | A position in the WAL. | 301.08 |
| streaming replication | A standby receiving and replaying WAL from the primary continuously. | 301.08 |
| replication slot | A server-side bookmark that makes the primary keep the WAL a consumer still needs. | 301.08 |
| base backup | A physical copy of the whole data directory taken while the server runs. | 301.08 |
| PITR (point-in-time recovery) | Restoring a base backup and replaying archived WAL up to a chosen moment. | 301.08 |
| RPO / RTO | How much recent data you can afford to lose, and how long you can afford to be down. | 301.08 |
| failover / fencing / split brain | Promoting a standby; making sure the old primary cannot write; two nodes both acting as primary. | 301.08 |
| embedding | A list of numbers a model produces for text so that similar meaning gives nearby vectors. | 301.09 |
| distance operator | A pgvector operator ordering rows by distance: `<->` L2, `<=>` cosine, `<#>` negative inner product. | 301.09 |
| ANN (approximate nearest neighbour) | An index-based search that trades some recall for speed. | 301.09 |
| recall | The fraction of the true nearest neighbours an approximate search returns. | 301.09 |
| hnsw / ivfflat | pgvector index types: a multi-layer graph, and clusters (lists) searched by probes. | 301.09 |
| tsvector / tsquery | The processed document and processed query of PostgreSQL full-text search. | 301.09 |
| stemming | Reducing a word to a root so that variants match. | 301.09 |
| hybrid search | Combining keyword and vector signals in one search. | 301.09 |
| T-SQL | SQL Server's SQL dialect and procedural language. | 301.10 |
| type affinity | SQLite's rule by which a declared column type influences, but does not enforce, the type of stored values. | 301.10 |
| catalog | The system tables in which a database describes itself, such as `pg_class` and `pg_settings`. | 301.10 |
| readiness review | A structured check of a system against operational criteria before it takes real traffic, ending in a decision. | 301.10 |
