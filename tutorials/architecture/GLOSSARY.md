# Architecture glossary

Terms are introduced in the numbered lessons. Symbols here document the small examples; they do not enforce a working system.

| Term | Plain meaning | First lesson |
|---|---|---|
| Architecture | Important arrangement of parts, responsibilities, relationships and the decisions behind them. | 01 |
| System | Cooperating parts considered together for a stated purpose. | 01 |
| Diagram | Selective picture answering a stated question. | 01 |
| Reader or audience | The people whose question the document should answer. | 01 |
| Scope | What a view includes and excludes. | 01 |
| Responsibility | A part's job. | 01 |
| Relationship | How two parts interact. | 01 |
| Flowchart | Shapes and connections showing structure or steps. | 01 |
| Node | A named shape in a flowchart. | 01 |
| Edge | A line or arrow connecting nodes. | 01 |
| Identifier | A source name used to refer to a node or other element. | 01 |
| Label | Visible text naming a shape or relationship. | 01 |
| Mermaid | A diagram notation that turns small text descriptions into pictures. | 01 |
| .mmd | File extension used here for raw Mermaid source, without Markdown fences. | 01 |
| File / folder | A saved unit of content / a grouping of files. | 01 |
| Editor / browser | A tool for changing saved text / an app for viewing websites. | 01 |
| UTF-8 | A text encoding that represents international characters. | 01 |
| Markdown / .md | Plain text with lightweight formatting markers / its usual file extension. | 01 |
| Fence | Opening or closing line of backticks around a Markdown block. | 01 |
| Preview | The displayed picture or formatted view derived from source. | 01 |
| Client | Program making a request to another program. | 02 |
| Server | Program answering requests. | 02 |
| Request / response | Message asking for work / its reply. | 02 |
| Sequence diagram | Participants across the top and messages in order down the page. | 02 |
| Participant / actor | A role or program in an interaction / the notation used for the human here. | 02 |
| HTTP | Hypertext Transfer Protocol, web request-and-response rules. | 02 |
| HTTPS | HTTP protected by encryption in transit; not a substitute for access checks. | 02 |
| GET / 200 OK | A request to retrieve a resource / an HTTP success status. | 02 |
| Scenario / happy path | One concrete interaction / a successful scenario. | 02 |
| Layer | A logical grouping of related responsibilities. | 03 |
| Presentation layer | Accepts user input and displays results. | 03 |
| Application layer | Coordinates work and applies use-case rules. | 03 |
| Data layer | Reads and saves records. | 03 |
| Logical view | Groups parts by responsibility, regardless of machines. | 03 |
| Deployment view | Shows where programs run. | 03 |
| Database | Organised records with facilities for stored relationships and rules. | 04 |
| Cache | Replaceable stored copy used to reuse earlier results. | 04 |
| Source of truth | Authoritative place to resolve conflicting copies. | 04 |
| Record / entity | One stored instance / a kind of thing represented by records. | 04 |
| ER diagram | Entity relationship diagram, showing related kinds of stored facts. | 04 |
| Primary key (PK) | Value uniquely identifying a record. | 04 |
| Foreign key (FK) | Reference to another record's key. | 04 |
| Cardinality / multiplicity | How many instances can take part in a relationship. | 04 / 05 |
| int / string | A whole-number type / a text type. | 04 |
| API | Application programming interface: an agreed way for programs to request work. | 05 |
| Web client / backend | Browser-facing presentation app / request-handling program behind its interface. | 05 |
| Token | Credential a client presents to a service; never put real ones in diagrams. | 05 |
| Technical design document (TDD) | Written account of a system design; here the platform's TDD.md. | 05 |
| Contract | Agreed description of interactions between programs. | 05 |
| Class diagram | Types of things, their properties and relationships. | 05 |
| Association | A relationship between concepts; not automatically inheritance. | 05 |
| UML | Unified Modeling Language, a family of modelling notations. | 05 |
| UUID | Universally unique identifier, used for platform record ids. | 05 |
| State / transition | Named condition / move between conditions in a stated workflow. | 05 |
| State diagram | View of one item's states and transitions over time. | 05 |
| Rendering | Turning diagram source into a picture. | 05 |
| C4 | Context, Containers, Components, Code: architecture zoom levels. | 06 |
| System boundary | Which responsibilities are inside the system being described. | 06 |
| Context diagram | One system, its people and directly connected neighbouring systems. | 06 |
| Container diagram | Main applications and data stores inside a system boundary. | 06 |
| C4 container | An application or data store, not necessarily a Docker container. | 06 |
| Docker container | A runtime packaging mechanism, different from C4 terminology. | 06 |
| Keycloak | The platform identity service, handling sign-in and token issuance. | 06 |
| PostgreSQL / Postgres | Relational database used by the platform. | 06 |
| SQL | Structured Query Language, used to read and change relational data. | 06 |
| JSON | JavaScript Object Notation, a text format for exchanged data. | 06 |
| OIDC | OpenID Connect, a sign-in standard. | 06 |
| PKCE | Proof Key for Code Exchange, binding an interactive sign-in exchange to its initiating client. | 06 |
| Public signing key | Public key used to verify a signature, not a private signing credential. | 06 |
| draw.io / diagrams.net | Diagram editor supporting editable .drawio files. | 07 |
| XML | Extensible Markup Language, structured text with elements and attributes. | 07 |
| Element / attribute | A named XML part / a named value attached to an element. | 07 |
| PNG | A common image-file format; an ordinary screenshot does not retain editable diagram shapes. | 07 |
| Cell / vertex / geometry | A drawing element / a shape / its position and size information. | 07 |
| ADR | Architecture decision record: one choice and its reasons, alternatives and consequences. | 08 |
| Context / options / consequences | Situation / alternatives / benefits and costs of a decision. | 08 |
| Status | Whether a decision is proposed, accepted or replaced. | 08 |
| Owner / review trigger | Responsible reviewer / observable reason to reconsider a decision. | 08 |
| Transaction | Changes grouped so they succeed together or not at all. | 08 |
| Constraint | Enforced data rule. | 08 |
| Migration | Controlled change to stored structure. | 08 |
| Stored function | Named work carried out in the database. | 08 |
| Authentication / authorization | Establishing identity / deciding what that identity may do. | 08 |
| OpenAPI | Format describing an HTTP API. | 08 |
| OpenAPI-first | Reviewing the agreed API description before implementing changes. | 08 |
| Superseded | Replaced by a later decision while preserving the original reasoning. | 08 |
| Quality attribute | Property describing how well a system serves a need. | 09 |
| Performance | How quickly work completes under stated load. | 09 |
| Security | Includes allowing access only to permitted people. | 09 |
| Availability | Successful service when needed under a stated measurement method. | 09 |
| Quality scenario | Situation with a checkable result. | 09 |
| Trade-off | Benefit accepted together with a cost elsewhere. | 09 |
| Weight / weighted total | Relative importance / sum of score-times-weight products. | 09 |
| Hard gate | Must-pass condition that a higher total cannot outweigh. | 09 |
| Millisecond (ms) / concurrent users | Thousandth of a second / users active at the same time. | 09 |
| Cache key | Identifier used to retrieve a cached result. | 09 |
| Invalidation / fallback | Removing or updating an obsolete copy / a safe alternative path on failure. | 09 |
| Review checklist | Concrete questions for checking agreement and reader understanding. | 10 |
| Trace | Following the same named idea across several views and decisions. | 10 |

## Small notation key
- Flowchart `LR`: left to right; `TD`: top to bottom; `-->`: directed relationship.
- Sequence `->>` and `-->>`: this track uses solid for actions/requests and dashed for replies; line appearance alone is not success or failure.
- ER `||`: exactly one; `o{`: zero or many, placed beside the many-side entity.
- Class `1` and `0..*`: one and zero-or-many.
- State `[*]`: initial marker in these examples.

## Level 201 terms
First-lesson numbers read "201-NN". Terms with a 101 entry are extended here.

| Term | Plain meaning | First lesson |
|---|---|---|
| Code verifier / code challenge | A random secret kept by the client / its hash sent first, so only the client that started sign-in can redeem the code. | 201-01 |
| State (sign-in) | A random value the client checks when the browser returns from sign-in. | 201-01 |
| alt / else block | A sequence-diagram box showing mutually exclusive branches. | 201-01 |
| Self message | A sequence arrow from a participant to itself: work done internally. | 201-01 |
| Idempotent / Idempotency-Key | Repeating gives the same effect / a client-chosen value that makes a repeated create safe. | 201-01 |
| If-Match / precondition | A header that makes an update conditional on the version the client saw. | 201-01 |
| Data-flow diagram (DFD) | Outside parties, processes and stores joined by arrows that each name the data moved. | 201-02 |
| Data store | A place where data rests: a table, a queue, a file or a cache. | 201-02 |
| Link table | A table that joins two entities in a many-to-many relationship. | 201-02 |
| Deployment diagram | Where each part runs and what is reachable between parts. | 201-03 |
| Container (draw.io) | A shape that holds other shapes; children store positions relative to it. | 201-03 |
| Published port | A port a container makes reachable from the host. | 201-03 |
| Loopback (127.0.0.1) | An address reachable only from the same machine. | 201-03 |
| Connection inventory | A table with one row per arrow: protocol, port, initiator, credential. | 201-03 |
| Synchronous / asynchronous | The caller waits for the answer / the caller does not wait. | 201-04 |
| Broker | A program that stores and forwards messages. | 201-04 |
| Event / command | A fact that already happened / a request to do something. | 201-04 |
| Coupling | How much one part must know about, or wait for, another. | 201-04 |
| gRPC / Protocol Buffers | A remote-call style with a binary contract file / that contract format. | 201-04 |
| Cache hit / miss | The copy was found / it was not found. | 201-05 |
| Time to live (TTL) | How long a copy may be used without checking again. | 201-05 |
| Invalidation | Removing or replacing a copy because the original changed. | 201-05 |
| CDN | Servers near users that keep copies of files that are the same for everyone. | 201-05 |
| Cache-aside | The application reads the database on a miss and stores a copy. | 201-05 |
| Conditional request / 304 | A request that asks for data only if it changed / the answer "not modified". | 201-05 |
| Queue / worker / acknowledgement | A line of messages / a program that takes and handles them / "done, remove it". | 201-06 |
| Competing consumers | Several workers on one queue, each message to one of them. | 201-06 |
| Stream / offset / replay | An append-only log / a reader's position / starting again from an earlier position. | 201-06 |
| Dead-letter queue | A side queue for messages that failed after the allowed tries. | 201-06 |
| Backpressure | Slowing or bounding producers when consumers cannot keep up. | 201-06 |
| At-least-once delivery | A message may arrive more than once but is not lost. | 201-06 |
| OAuth 2.0 / OpenID Connect | A framework for limited API access / a standard sign-in layer on top of it. | 201-07 |
| Identity provider (IdP) | The service that signs users in and issues tokens. | 201-07 |
| Access / ID / refresh token | Sent to the API / tells the client who signed in / obtains new access tokens. | 201-07 |
| JWT and claims | A signed token with readable claims such as iss, sub, aud, exp, scope. | 201-07 |
| Scope / role | What a client's token may do / what a user is; both must allow an action. | 201-07 |
| API gateway | One entry point for shared concerns such as rate limits and token checks. | 201-07 |
| Defence in depth | Several independent layers, so one failure is not fatal. | 201-07 |
| Object-level authorisation | Deciding whether this caller may touch this particular object. | 201-07 |
| arc42 | A template with twelve sections for architecture documentation. | 201-08 |
| Docs as code | Documents kept as text files in the repository and reviewed in pull requests. | 201-08 |
| Pull request | A proposed change reviewed before it joins the main branch. | 201-08 |
| Quality scenario (six parts) | Source, stimulus, environment, artifact, response, response measure. | 201-09 |
| Utility tree | Goal, quality attributes and rated scenarios. | 201-09 |
| Risk register | Risks with likelihood, impact, mitigation, trigger and owner. | 201-09 |
| ATAM / ATAM-lite | Architecture Tradeoff Analysis Method / a short form for a small team. | 201-09 |
| Risk / non-risk / sensitivity point / trade-off point | A decision that may fail a scenario / a sound one / a setting with a large effect / a decision that helps one quality and hurts another. | 201-09 |
| Architecture package | A linked set of diagrams, ADRs, scenarios and risks with a reading order. | 201-10 |
| C4 component view | The main parts inside one container. | 201-10 |
| Traceability | Every scenario leads to a decision, a diagram and a risk. | 201-10 |

## Level 301 terms
First-lesson numbers read "301-NN".

| Term | Plain meaning | First lesson |
|---|---|---|
| Stateless instance | Keeps nothing between requests that another instance would need. | 301-01 |
| Load balancer / health check | Spreads requests over instances / removes a failing instance from the pool. | 301-01 |
| Sticky session | Pinning a user to one instance; undoes statelessness. | 301-01 |
| Read replica / replica lag | A copy of the database that serves reads / how far it is behind. | 301-01 |
| Connection pool | A bounded set of reusable database connections. | 301-01 |
| Vertical / horizontal scaling | A bigger machine / more machines. | 301-01 |
| Sharding / shard key / hot shard | Splitting data across databases / the value that picks the shard / a shard holding disproportionate load. | 301-01 |
| Resharding | Moving data between shards. | 301-01 |
| Partition (network) | Parts of the system cannot talk although each runs. | 301-02 |
| CAP theorem | During a partition a system must give up consistency or availability. | 301-02 |
| PACELC | If partitioned choose A or C; else choose latency or consistency. | 301-02 |
| Strong / eventual consistency | The reader sees the latest write or an error / copies converge and readers may see older values meanwhile. | 301-02 |
| Read-your-writes | A client sees its own earlier writes. | 301-02 |
| Quorum | Reads and writes confirmed by enough copies that they overlap (R + W > N). | 301-02 |
| Split brain | Two nodes both act as the primary. | 301-02 |
| Dual write | Changing two systems with no shared transaction. | 301-03 |
| Transactional outbox | The change and an event record saved in one transaction, published later. | 301-03 |
| Change data capture (CDC) | Publishing from the database's change log. | 301-03 |
| Idempotent consumer / inbox | A consumer that makes a repeated message harmless, often by recording handled ids. | 301-03 |
| Saga / compensation | A process of local transactions / a new action that undoes an earlier step. | 301-03 |
| Choreography / orchestration | Services react to events / a coordinator sends commands. | 301-03 |
| Pivot step | A step that cannot be undone; the saga can only go forward after it. | 301-03 |
| Timeout / deadline | Longest wait for one call / the time by which the whole request must finish. | 301-04 |
| Backoff and jitter | Waiting longer after each failure / adding randomness so clients do not retry together. | 301-04 |
| Circuit breaker | A switch with states closed, open and half-open that stops calls to a failing dependency. | 301-04 |
| Bulkhead | Separate pools of capacity per dependency. | 301-04 |
| Fail fast / load shedding | Refuse quickly when success is unlikely / deliberately refuse some requests to protect the rest. | 301-04 |
| Graceful degradation | Keeping important functions and visibly giving up optional ones. | 301-04 |
| Cascading failure | One failure spreads and is amplified by retries and exhaustion. | 301-04 |
| Failure mode | A way in which a part can fail. | 301-04 |
| Observability | Asking new questions of a running system from the data it emits. | 301-05 |
| Metric / log / trace / span | A number over time / a record of one event / the path of one request / one timed step in it. | 301-05 |
| Cardinality | The number of distinct values of a label. | 301-05 |
| Golden signals | Latency, traffic, errors and saturation. | 301-05 |
| SLI / SLO / SLA | A measured good-over-valid ratio / the target for it / a contract with consequences. | 301-05 |
| Error budget / burn rate | The badness the SLO allows / how fast it is used. | 301-05 |
| Trust boundary | A line where the level of trust changes. | 301-06 |
| Zero trust | No request is trusted because of where it comes from. | 301-06 |
| Least privilege | Only the rights that are needed. | 301-06 |
| Threat model / STRIDE | A structured list of what could go wrong / six threat categories. | 301-06 |
| Tenant / row-level security | A customer whose data must be kept apart / database rules that filter rows by caller. | 301-06 |
| Modular monolith | One deployable with modules that own their data and talk through interfaces. | 301-07 |
| Distributed monolith | Services that must deploy together or share a database. | 301-07 |
| Seam / strangler fig / facade | Where a system can be cut / replacing a system piece by piece / the front that routes to old or new. | 301-07 |
| Anti-corruption layer | A translation layer that keeps the old model's quirks out of the new part. | 301-07 |
| Throughput / concurrency | Work completed per second / work in progress at one moment. | 301-08 |
| Little's law | L = lambda x W: in flight equals rate times time in the system. | 301-08 |
| Peak factor / headroom | Busiest second over the average second / unused capacity kept in reserve. | 301-08 |
| Saturation point | The load at which latency climbs sharply or errors start. | 301-08 |
| Back-of-envelope estimate | A quick calculation with stated assumptions. | 301-08 |
| Design review / lens | A written critique of a design / a question set such as scale or security. | 301-09 |
| Finding / severity / verdict | An observation with evidence / its consequence rating / accept, accept with conditions or rework. | 301-09 |
