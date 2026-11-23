# C# 201, Phase 3: Data

Source pack for lessons 08 and 09 of **C# 201 (Hero to Super Hero)**. The optional originals are at https://github.com/Uee03/Code101 under `source/csharp/201-hero-to-super-hero/phase-3-data/` (Code > Download ZIP, or `git clone`). Every lesson shows all its code and configuration, so downloading is optional.

> **Draft status.** These lessons and their code were written by reading the code and the official documentation; they have not been executed yet. If something behaves differently from the text, trust your tool's real output and report it.

| Folder | Lesson | You build |
|---|---|---|
| `08-ef-core-and-postgres` | EF Core and PostgreSQL | PostgreSQL in Docker (`docker-compose.yml` + `.env.example`), a code-first model with one-to-many and many-to-many relations, a migration, tracking vs no-tracking queries and bulk updates. Exercise: add a column with a second migration. |
| `09-stored-procedures-and-raw-sql` | Stored procedures and raw SQL | A database with a function and a procedure created by an init script, called with Dapper and EF Core (`SqlQuery`, `ExecuteSql`), and a SQL-injection demonstration with its fix. Exercise: three more parameterized queries. |

## Inside each lesson folder
| Folder or file | What it is |
|---|---|
| `code/` | The finished project, including the Compose file, `.env.example` and (lesson 09) `db/init.sql`. |
| `exercise/starter/` | The files to change in the Try it exercise, with `TODO` comments. They replace the files of the same name in your project. |
| `exercise/solution/` | The finished exercise files; try before you look. |
| `verify.json` | Machine-readable list of the steps and expected output of the lesson. |

## How to run
1. You need the **.NET SDK 11.0.100**, an editor and **Docker** with Compose v2 (Docker Desktop on Windows/macOS, Docker Engine on Linux). `docker --version` and `docker compose version` must both work, and Docker must be running.
2. In the lesson's `code` folder copy `.env.example` to `.env` (`Copy-Item .env.example .env` in PowerShell, `cp .env.example .env` in bash). The values are disposable practice values; `.env` is ignored by Git.
3. Start the database: `docker compose up -d --wait`. Set the connection string in your terminal as the lesson shows (`NOTES_CONNECTION`), then `dotnet run --project . --nologo`. Lesson 08 first needs the EF Core tool: `dotnet tool restore`, then `dotnet ef migrations add InitialCreate`.
4. Clean up: `docker compose down -v` stops the database and deletes its data.

**Folder: the extracted repository root `Code101` (contains `source` and `tutorials`)**
```text
cd source/csharp/201-hero-to-super-hero/phase-3-data/09-stored-procedures-and-raw-sql/code
docker compose up -d --wait
```

## Ports used
Lesson 08: database on host port 5433. Lesson 09: 5434. Both listen on `127.0.0.1` only, so the two lessons can run at the same time.

## First-timer time
Lesson 08: 80-90 minutes (two sittings); 09: 70-80. The last lesson of the phase ends with a mixed review.

## Needs
.NET SDK 11.0.100 / net11.0, Docker with Compose, internet access for packages and the `postgres:17-alpine` image (about 100 MB). NuGet packages: Npgsql.EntityFrameworkCore.PostgreSQL 11.0.0, Microsoft.EntityFrameworkCore.Design 11.0.0, Npgsql 11.0.0, Dapper 2.1.100; local tool `dotnet-ef` 11.0.0. No real credentials anywhere. Source files use UTF-8 without BOM; `bin/` and `obj/` are build output and are not part of the pack.

Next: Phase 4, Security and quality (lessons 10 and 11).
