# Architecture 201: phase 2 - design choices

Choose how parts talk (REST, events, gRPC), where to cache, how to move work off the request, and where identity checks live.

## Prerequisites and status
Architecture 201 phase 1. All material is **written (not run)**. Lesson front matter remains `verified: not yet run`; no diagram was rendered and nothing was executed. No compiler, server, broker, database or Docker is required: the lessons are design documents, diagrams and decision records.

## Open the pack
1. Windows: right-click the ZIP and choose **Extract All**. macOS: double-click the ZIP. Linux: use the file manager's **Extract** action.
2. Each numbered lesson folder has `code/` (finished files), `exercise/starter/` (guided practice) and `exercise/solution/` (one answer). `verify.json` holds empty steps, so nothing runs.
3. Make your own `code101/architecture/201-lessonNN` folder; for practice, copy the **starter folder itself** and rename the copy `201-lessonNN-try`.
4. `.mmd` files are raw Mermaid; `diagram-sources.md` repeats them inside fences for Markdown previews. Keep both in step when you edit.

## Lessons
- **04. REST, events or gRPC: when each** - `04-rest-events-grpc/`. [Lesson](https://github.com/Uee03/Code101/blob/main/tutorials/architecture/201-hero-to-super-hero/phase-2-design-choices/04-rest-events-grpc.md).
- **05. Caching and CDNs** - `05-caching-and-cdns/`. [Lesson](https://github.com/Uee03/Code101/blob/main/tutorials/architecture/201-hero-to-super-hero/phase-2-design-choices/05-caching-and-cdns.md).
- **06. Queues, streams and async work** - `06-queues-streams-async-work/`. [Lesson](https://github.com/Uee03/Code101/blob/main/tutorials/architecture/201-hero-to-super-hero/phase-2-design-choices/06-queues-streams-async-work.md).
- **07. Authentication and authorisation architecture** - `07-authn-authz-architecture/`. [Lesson](https://github.com/Uee03/Code101/blob/main/tutorials/architecture/201-hero-to-super-hero/phase-2-design-choices/07-authn-authz-architecture.md).

## Honesty notes
Anything marked "proposal" (a gateway, a cache, an export feature, a broker) is not part of the Tasks and Teams platform. Targets come from the platform TDD or are marked "chosen from measurements". No real credentials or tokens appear anywhere.

## Verification scope
Static check only: lesson text against source files and `verify.json` parsing. No rendering, no execution.
