# Decision framework: monolith, modular monolith or microservices

Answer each question with evidence, not opinion. The default is the simplest structure that meets the evidence.

| Question | Evidence to collect | Points toward one deployable | Points toward separate services |
|---|---|---|---|
| Do teams block each other's releases? | Release history, waiting time for shared releases | Few teams, rare conflicts | Many teams with frequent conflicts over one release |
| Do parts need to scale differently? | Load and resource use per part | Similar profiles | One part needs far more instances than the rest, shown by measurement |
| Must one part keep running when another fails? | Incident history, failure effects table | Failures are rare or tolerable | A critical part is repeatedly damaged by a non-critical one |
| Are the data boundaries clear? | A table-by-table ownership map | Tables are tangled across features | Each candidate owns its data and the others rarely read it directly |
| Can the team operate many services? | Automated builds and releases, tracing, on-call rota | Little automation or observability | Mature automation, observability and incident practice |
| Must operations be strongly consistent across the candidate parts? | The consistency menu | Many operations need one atomic transaction across them | Operations cross the boundary rarely and tolerate eventual consistency |
| Is there a different technology or compliance need? | Requirements and audits | None | A part must use another runtime or be isolated for compliance |

Default: start with a modular monolith, one deployable with modules that own their data and talk through public interfaces. Extract a module only when the evidence in one or more rows justifies the cost.
