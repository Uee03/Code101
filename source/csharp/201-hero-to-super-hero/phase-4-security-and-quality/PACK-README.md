# C# 201, Phase 4: Security and Quality

Source pack for lessons 10 and 11 of **C# 201 (Hero to Super Hero)**. The optional originals are at https://github.com/Uee03/Code101 under `source/csharp/201-hero-to-super-hero/phase-4-security-and-quality/` (Code > Download ZIP, or `git clone`). Every file you must write is shown in the lessons, so downloading is optional.

> **Draft status.** These lessons and their code were written by reading the code and the official documentation; they have not been executed yet. If something behaves differently from the text, trust your tool's real output and report it.

| Folder | Lesson | You build |
|---|---|---|
| `10-jwt-authentication-and-authorization` | JWT bearer authentication and authorization policies | An API that validates JWTs (signature, issuer, audience, lifetime), a Development-only token endpoint for three demo users, role and permission policies, and a resource-ownership check. Exercise: a read policy, a list endpoint and `404` instead of `403`. |
| `11-testing-and-notes-api` | Testing with xUnit and the notes API mini project | A layered notes API (minimal API group, FluentValidation, `Result<T>`, ProblemDetails, options, EF Core + PostgreSQL), 12 xUnit tests (unit with a fake repository, integration with `WebApplicationFactory`), and a multi-stage non-root Docker image run with Compose. Exercise: a test-first change. |

## Inside each lesson folder
| Folder or file | What it is |
|---|---|
| `code/` | The finished project. Lesson 11 has two projects (`NotesApi`, `NotesApi.Tests`) plus Docker files. |
| `exercise/starter/` | The files to change in the Try it exercise. They replace the files of the same name in your project. |
| `exercise/solution/` | The finished exercise files; try before you look. |
| `verify/` (lesson 10) | Small scripts that call the running API and check the statuses; you do not need them to follow the lesson. |
| `verify.json` | Machine-readable list of the steps and expected output of the lesson. |

## How to run
1. You need the **.NET SDK 11.0.100**, an editor and `curl`. Lesson 11 also needs **Docker** with Compose v2 and internet access (NuGet packages: Microsoft.AspNetCore.Authentication.JwtBearer 11.0.0, FluentValidation 12.2.0, EF Core 11.0.0 with the Npgsql provider, Microsoft.AspNetCore.OpenApi 11.0.0, xunit.v3.mtp-v2 4.0.3, Microsoft.AspNetCore.Mvc.Testing 11.0.0).
2. Lesson 10: `dotnet run --project . --urls http://localhost:5081 --environment Development` in the `code` folder, then call it with `curl` from a second terminal. Lesson 11: in `code`, `dotnet test` inside `NotesApi.Tests`; for the container, copy `.env.example` to `.env`, create the migration (`dotnet tool restore`, then `dotnet ef migrations add InitialCreate --project NotesApi`) and run `docker compose up -d --build --wait`.
3. Clean up: `docker compose down -v --rmi local` removes the containers, the database volume and the built image.

**Folder: the extracted repository root `Code101` (contains `source` and `tutorials`)**
```text
cd source/csharp/201-hero-to-super-hero/phase-4-security-and-quality/11-testing-and-notes-api/code/NotesApi.Tests
dotnet test
```

## Ports used
Lesson 10: 5081 (and 5082 for the exercise). Lesson 11: API on 8085, database on 5435, both on `127.0.0.1` only.

## First-timer time
Lesson 10: 70-80 minutes; 11: 130-160 minutes in three sittings. Lesson 11 ends with a mixed review and a level wrap-up.

## Needs
.NET SDK 11.0.100 / net11.0, `curl`, Docker with Compose (lesson 11), internet for the first restore and the base images (`mcr.microsoft.com/dotnet/sdk:11.0.100-alpine3.24`, `aspnet:11.0.0-alpine3.24`, `postgres:17-alpine`). Tokens in lesson 10 are signed with a random key created at each start; nothing secret is stored. For Keycloak and the full platform see the [dotnet capstone](../../../../capstones/backend-dotnet/tutorials/phase-3-identity/03-identity.md). Source files use UTF-8 without BOM; `bin/` and `obj/` are build output and are not part of the pack.

Next: the dotnet capstone, or C# 301 when it is available.
