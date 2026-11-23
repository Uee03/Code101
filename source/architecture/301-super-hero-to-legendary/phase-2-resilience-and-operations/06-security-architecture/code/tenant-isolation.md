# Tenant isolation options

In Tasks and Teams the access boundary is the team. A product with paying customers would add a tenant above it, such as a company that owns several teams.

| Option | How data is separated | Isolation strength | Cost and operations | Main risk |
|---|---|---|---|---|
| Shared tables, checks in application code | Every query filters by team and the code checks membership | Depends on every code path | Cheapest, one schema to migrate | One missed check exposes another team's data |
| Shared tables plus database row-level security | The database itself filters rows by the caller's team | Stronger, the database refuses a missed check | One schema, extra policies to design and test | Policies and the application's idea of the caller can disagree |
| Schema per tenant | Each tenant has its own schema in one database | Strong between tenants | Many schemas to migrate and monitor | Migration time and connection handling grow with tenants |
| Database per tenant | Each tenant has its own database | Strongest, including backup and restore per tenant | Highest cost and most operations | Fleet management and cross-tenant reporting |

What the platform does today: shared tables, with team membership checked in the application, a 404 for objects the caller cannot see, and a limited database role. Row-level security is a proposal worth evaluating, not a feature of the platform.

Questions to answer before choosing: how strong must the guarantee be, who audits it, what happens to one tenant's data on deletion, and how are cross-tenant administrator queries controlled and logged?
