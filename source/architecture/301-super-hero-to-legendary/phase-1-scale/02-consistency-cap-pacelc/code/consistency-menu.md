# Consistency menu

Strong means the reader sees the latest accepted write or gets an error. Eventual means the reader may see an older value for a while and the copies converge.

| Operation | Choice | Why | If the deciding node is unreachable |
|---|---|---|---|
| Update a task with If-Match (platform) | Strong | The version check must see the current version, or a change is lost | Refuse the write; do not guess |
| Complete a task (platform, stored function with a row lock) | Strong | Two completions must not interleave | Refuse the write |
| List tasks of a project (platform) | Eventual, if a replica is added | A list that is briefly old does no harm | Serve from the replica and show or monitor the lag |
| Look up an idempotency key (platform) | Strong | A missed key lets a duplicate create through | Refuse the create rather than risk a duplicate |
| Read the audit log (platform, admin) | Eventual is acceptable | An entry may appear late but must never be lost | Serve what is available and say so |
| Validate an access token (platform) | Eventual by design | A revoked token works until it expires (ADR 0002) | Keep serving with cached keys until they must be refreshed |
| Reserve stock (P07 Inventory) | Strong inside Inventory's own database | Stock must never be oversold | Refuse the reservation |
| Show an order's status (P07 read model) | Eventual by design | The view is built from events and can lag | Serve the last known state and expose the projection lag |
