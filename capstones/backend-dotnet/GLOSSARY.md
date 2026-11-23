# Glossary: backend-dotnet

Plain-language definitions for the ASP.NET Core backend capstone. Terms from the C# track and the platform capstone are not repeated; see `tutorials/csharp/GLOSSARY.md` and the platform TDD.

| Term | Meaning | Chapter |
|------|---------|---------|
| Endpoint | One address plus one HTTP method that does one thing, here one class per operation. | 01 |
| REPR | Request, Endpoint, Response: the pattern FastEndpoints uses; each operation has its own request class, endpoint class and response. | 01 |
| DTO | Data transfer object: a plain class or record that only carries data in or out of the API. | 01 |
| Validator | A class (FluentValidation) that checks a request before the endpoint uses it. | 01 |
| Problem details | The standard JSON error document of RFC 9457 (`type`, `title`, `status`, `detail`, `instance`). | 01 |
| JSON Pointer | A path such as `/name` that names one value inside a JSON document (RFC 6901). | 01 |
| Middleware | One step of the request pipeline; every request passes through the steps in order. | 01 |
| Dependency injection | The framework creates the objects a class asks for in its constructor and hands them over. | 01 |
| Database first | The database schema is written in SQL and owned by the database; the code maps to it and never changes it. | 02 |
| Entity | A class that maps to one table; EF Core loads rows into it and saves changes from it. | 02 |
| DbContext | The EF Core object that holds the connection and the entities of one unit of work. | 02 |
| Projection | A query that selects only the columns a DTO needs instead of whole entities. | 02 |
| Stored function | Code that runs inside Postgres (`complete_task`); the API calls it with parameters. | 02 |
| SQLSTATE | The five-character error code of a database error; `TS404`, `TS409`, `TS412` and `TS422` are this project's own. | 02 |
| Optimistic concurrency | Let several users read and change the same row, but refuse a change based on an out-of-date version. | 02 |
| ETag and If-Match | The row version as an HTTP validator, and the header that says "change it only if it is still this version". | 02 |
| Keyset pagination | Paging by "the rows after the last one you saw" instead of page numbers; the cursor holds the last sort values. | 02 |
| JSON Merge Patch | RFC 7396: a PATCH body lists only the fields to change; `null` clears a field. | 02 |
| Idempotency key | A client-chosen value that makes a repeated create return the first result instead of creating twice. | 02 |
| Bearer token | A signed access token sent in the `Authorization` header. | 03 |
| JWT | JSON Web Token: a signed token whose claims (issuer, audience, expiry, roles) the API can verify without calling Keycloak. | 03 |
| Claim | One fact inside a token, for example `sub` (the user id) or `scope`. | 03 |
| Audience | The API a token is meant for; this API accepts only tokens whose `aud` contains `tasks-api`. | 03 |
| Authorization policy | A named rule (a scope and perhaps a role) an endpoint requires. | 03 |
| Multi-stage build | A Dockerfile that builds in a big SDK image and copies only the result into a small runtime image. | 04 |
| Non-root user | A container user without administrator rights; a compromised API cannot change the container. | 04 |
| Fixed-window rate limit | A counter per client that resets every N seconds; over the limit gets 429. | 05 |
| Security header | A response header (`X-Content-Type-Options`, `Content-Security-Policy`) that tells browsers to be strict. | 05 |
| CORS | The browser rule that decides which web origins may call the API. | 05 |
