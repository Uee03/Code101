# Capstones: pick any backend and any client

Every capstone builds the same product, **Tasks and Teams**, against one shared contract ([platform](platform/README.md)). Because of that, **any backend works with any client**. Learn whatever you like, in any order, then apply it here.

You are never required to finish a track first. The "Recommended before you start" column is advice based on current practice, not a gate.

## Choose a pair

| | Angular (web) | React (web) | Flutter (mobile) | Kotlin + Compose (mobile) |
|---|:---:|:---:|:---:|:---:|
| **Python** (FastAPI) | yes | yes | yes | yes |
| **ASP.NET Core** | yes | yes | yes | yes |
| **Go** | yes | yes | yes | yes |
| **Rust** (Axum) | yes | yes | no | no |

The mobile capstones target the Python, ASP.NET and Go backends only. Every pair needs the [platform](platform/README.md) contract, which each capstone README explains how to copy or run.

Examples: ASP.NET + Flutter = [backend-dotnet](backend-dotnet/README.md) then [mobile-flutter](mobile-flutter/README.md). Go + React = [backend-go](backend-go/README.md) then [web-react](web-react/README.md). A client capstone can also run against any finished backend in this folder, so you can build only the half you want.

## The capstones

| Capstone | Builds | Recommended before you start |
|----------|--------|------------------------------|
| [platform](platform/README.md) | OpenAPI contract, Postgres schema, Keycloak realm, conformance script | Primers in the capstone (Git, HTTP and REST, OpenAPI, OAuth2 and OIDC); [Docker 101](../tutorials/docker/101-zero-to-hero); [Databases 101](../tutorials/databases/101-zero-to-hero) |
| [backend-python](backend-python/README.md) | FastAPI service | [Python 101](../tutorials/python/101-zero-to-hero) and [201](../tutorials/python/201-hero-to-super-hero); Databases 101 and 201 |
| [backend-dotnet](backend-dotnet/README.md) | ASP.NET Core service | [C# 101](../tutorials/csharp/101-zero-to-hero) and [201](../tutorials/csharp/201-hero-to-super-hero); Databases 101 and 201 |
| [backend-go](backend-go/README.md) | net/http service | [Go 101](../tutorials/go/101-zero-to-hero) and [201](../tutorials/go/201-hero-to-super-hero); Databases 101 and 201 |
| [backend-rust](backend-rust/README.md) | Axum service | [Rust 101](../tutorials/rust/101-zero-to-hero) and [201](../tutorials/rust/201-hero-to-super-hero); Databases 101 and 201 |
| [web-angular](web-angular/README.md) | Angular client | [Web 101](../tutorials/web/101-zero-to-hero); [Angular 101](../tutorials/angular/101-zero-to-hero) and [201](../tutorials/angular/201-hero-to-super-hero) |
| [web-react](web-react/README.md) | React client | Web 101; [React 101](../tutorials/react/101-zero-to-hero) and [201](../tutorials/react/201-hero-to-super-hero) |
| [mobile-flutter](mobile-flutter/README.md) | Flutter app | [Flutter 101](../tutorials/flutter/101-zero-to-hero) and [201](../tutorials/flutter/201-hero-to-super-hero) |
| [mobile-kotlin](mobile-kotlin/README.md) | Kotlin + Compose app | [Kotlin 101](../tutorials/kotlin/101-zero-to-hero) and [201](../tutorials/kotlin/201-hero-to-super-hero) |
| [desktop-c](desktop-c/README.md) | Native C17 desktop client (SDL3, Nuklear, libcurl) | [C 101](../tutorials/c/101-zero-to-hero) |
| [desktop-cpp](desktop-cpp/README.md) | Native C++20 desktop client (SDL3, Dear ImGui) | [C++ 101](../tutorials/cpp/101-zero-to-hero) |

Newer to coding? Add the 101 lessons of your track and the [platform primers](platform/tutorials/phase-0-primers). Already experienced? Skim the capstone TDD (`TDD.md` in each folder) and start building.

## Recommendations (current practice)

- Use Docker for Postgres and Keycloak; the capstones ship the Compose files.
- Build the backend before the client so you can see real responses, or run a finished backend from this folder.
- Read the capstone's `TDD.md` first. It lists the requirements you are building.
- Pass the conformance script (`18 passed, 0 failed`) before calling a backend done.
- Do one backend and one client first. Come back and swap in another language to compare.

## Practice capstones

[`_practice/`](_practice/README.md) holds eleven projects with a design document and no source code. Build them in your own stack once you have finished a pair.

## Learning paths

The [paths](../docs/paths) pages are optional suggested orders: [backend](../docs/paths/backend.md), [web](../docs/paths/web.md), [mobile](../docs/paths/mobile.md).
