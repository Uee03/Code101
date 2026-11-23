# Practice capstones (TDD only, no source code)

Each project is a complete **Technical Design Document**: client brief, requirements, architecture hints, sprint plan, grading rubric,
stretch goals and pitfalls. **There is no solution code.** You build it yourself in a 1 to 3 month sprint, split into weekly phases that
each end with something you can demo. Use the Code101 lessons linked inside each TDD as your reference.

| Id | Project | Sprint | Level | Main skills |
|----|---------|--------|-------|-------------|
| [P01](P01-inventory-and-orders/TDD.md) | Inventory and orders back office | 4 weeks | 201 | relational design, order lifecycle, reports, roles, CSV |
| [P02](P02-booking-and-scheduling/TDD.md) | Booking and scheduling | 4 weeks | 201 | availability, double-booking prevention, time zones, reminders |
| [P03](P03-team-chat-and-notifications/TDD.md) | Team chat and notifications | 6 weeks | 201-301 | WebSockets/SSE, presence, pagination, rate limits, scaling |
| [P04](P04-offline-first-field-service/TDD.md) | Offline-first field-service mobile app | 8 weeks | 301 | local DB, sync queue, conflicts, background sync, PKCE |
| [P05](P05-multi-tenant-saas-billing/TDD.md) | Multi-tenant SaaS billing | 8 weeks | 301 | tenant isolation, RLS, subscriptions, webhooks, idempotency |
| [P06](P06-document-search-and-rag/TDD.md) | Document search and RAG (Ollama + pgvector) | 8 weeks | 301 | embeddings, hybrid search, citations, evaluation, prompt injection |
| [P07](P07-event-driven-order-processing/TDD.md) | Event-driven order processing (microservices) | 12 weeks | 301 | broker, outbox, saga, CQRS, observability, resilience |
| [P08](P08-iot-telemetry-dashboard/TDD.md) | IoT telemetry dashboard | 8 weeks | 301 | ingestion, time series, downsampling, alerts, backpressure |
| [P09](P09-cpp-desktop-app/TDD.md) | C++ desktop application | 6 weeks | 201-301 | RAII, CMake + vcpkg, SQLite, threads, installer |
| [P10](P10-c-systems-utility/TDD.md) | C systems utility with a desktop front end | 4 weeks | 201 | memory management, portability, sanitizers |
| [P11](P11-unity-vertical-slice/TDD.md) | Unity vertical-slice game (runs locally, never in Docker) | 8 weeks | 201-301 | ScriptableObjects, Input System, UI Toolkit, pooling, shaders |

## How to use a practice capstone

1. Read the whole TDD first, then choose one of its suggested stacks.
2. Copy the sprint plan into your own tracker and work week by week; each week ends with a demo against the exit criteria.
3. Check yourself with the rubric at the end and try the stretch goals.
4. Keep the lessons referenced in the hints nearby. If a hint points at a lesson that is not written yet, it is marked "planned".

Docker, where used, is temporary: start it for your work and remove it afterwards (`docker compose down -v`).
Host ports differ between projects; check the TDD you chose and stop one project before starting another.
