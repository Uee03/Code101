# C# 301, Phase 4: Production

Source pack for lessons 09 and 10 of **C# 301 (Super Hero to Legendary)**. The optional originals are at https://github.com/Uee03/Code101 under `source/csharp/301-super-hero-to-legendary/phase-4-production/` (Code > Download ZIP, or git clone). Every file is also shown in full in the lesson (the SDK pin `global.json` of lesson 09 is identical to lesson 01 and is not repeated).

**Status: written (not run).** Expected outputs were derived from the code and the documentation. The Keycloak realm import, the Alpine image tags and the Native AOT container build are the parts most worth checking when you first run them.

| Folder | Lesson | You build |
|---|---|---|
| `09-modular-monolith-to-microservices` | Modular monolith to microservices | A shop monolith with a billing module behind a contract, then the same module as its own service with Keycloak client-credentials tokens, audience and role checks; exercise: parse a JWT `aud` claim. |
| `10-native-aot-analyzers-and-production-readiness` | Native AOT, analyzers, EditorConfig and a production readiness review | An AOT minimal API with `Directory.Build.props`, `.editorconfig`, a multi-stage Dockerfile, a hardened compose file and a production checklist; exercise: review a flawed service. |

## Inside each lesson folder
| Folder or file | What it is |
|---|---|
| `code/` | The finished project. |
| `exercise/starter/` | Starting files (lesson 09: a small console project; lesson 10: the flawed files to review). |
| `exercise/solution/` | The answer (lesson 09: the finished `Audience.cs`; lesson 10: `FINDINGS.md`). |
| `verify.json` | Maintainer check data. |

## How to run
1. Install the .NET SDK **11.0.100**; Docker with Compose and `curl` for the container parts.
2. Lesson 09, part 1: in `code`, `dotnet build src/Shop.Host`, `dotnet run --project src/Shop.Host --no-build`, then `curl` to port 5309. Part 2 needs `.env` (copy `.env.example` and change both secrets), `docker compose up -d --wait`, the Billing service on port 5319, and the host with `Billing__Mode=Remote` and `Billing__Remote__ClientSecret` set in the terminal. Keycloak uses host port 8180 (stop the capstone stack first).
3. Lesson 10: in `code`, `dotnet build src/Inventory.Api -c Release`, `dotnet run --project src/Inventory.Api -c Release --no-build`, `curl` to port 5310. Container: `docker compose up -d --build --wait`, `curl` to port 8310, then `docker compose down --rmi local`. A local `dotnet publish -r <rid>` needs the C++ toolchain for your OS.
4. Never commit `.env`. Delete `bin`, `obj` and `outbox.db`-style leftovers before zipping your own copies.

## Needs
.NET SDK 11.0.100 / net11.0. NuGet: Microsoft.AspNetCore.Authentication.JwtBearer 11.0.0 (09); none for lesson 10. Images: `quay.io/keycloak/keycloak:26.8.2` (09); `mcr.microsoft.com/dotnet/sdk:11.0.100-alpine3.24` and `mcr.microsoft.com/dotnet/runtime-deps:11.0.0-alpine3.24` (10). No lockfiles are included.

## First-timer time
Lesson 09: 90-120 minutes in two sittings; lesson 10: 90-120 minutes in two sittings.

Next: End of C# 301. Continue with the capstones in `capstones/`.
