# C# 201, Phase 2: Web APIs

Source pack for lessons 05 to 07 of **C# 201 (Hero to Super Hero)**. The optional originals are at https://github.com/Uee03/Code101 under `source/csharp/201-hero-to-super-hero/phase-2-web-apis/` (Code > Download ZIP, or `git clone`). Every lesson shows all its code, so downloading is optional.

> **Draft status.** These lessons and their code were written by reading the code and the official documentation; they have not been executed yet. If something behaves differently from the text, trust your tool's real output and report it.

| Folder | Lesson | You build |
|---|---|---|
| `05-first-aspnet-core-api` | First ASP.NET Core API | The same three-endpoint notes API three times: a minimal API, controllers and FastEndpoints (REPR). Exercise: `DELETE /notes/{id}`. |
| `06-dtos-validation-result-problemdetails` | DTOs, validation, the Result pattern and ProblemDetails | A notes API with request/response DTOs, FluentValidation, `Result<T>` mapped to `404`/`409`, and a safe `500` handler. Exercise: `Map` and `Match` for `Result<T>` (console project). |
| `07-dependency-injection-and-options` | Dependency injection and configuration | A web app that proves singleton, scoped and transient lifetimes with an instance counter and reads validated options from the file, the command line and the environment. Exercise: a console DI container with scopes. |

## Inside each lesson folder
| Folder or file | What it is |
|---|---|
| `code/` | The finished project(s) from the lesson's Steps. Lesson 05 has three project folders. |
| `exercise/starter/` | The starting files of the Try it exercise, with `TODO` comments. |
| `exercise/solution/` | The finished exercise; try before you look. |
| `verify.json` | Machine-readable list of the steps and expected output of the lesson. |

## How to run any program
1. You need the **.NET SDK 11.0.100** (or a later 11.0.1xx patch), an editor, and `curl` (Windows 10/11 include `curl.exe`; in Windows PowerShell type `curl.exe`). The first build downloads NuGet packages: lesson 05 (FastEndpoints) and lesson 06 (FluentValidation) need internet access once.
2. Extract the zip, open a terminal in the project folder (the folder with the `.csproj`) and run the command the lesson gives, for example `dotnet run --project MinimalNotes --urls http://localhost:5051`. The server keeps running; stop it with Ctrl+C. Call it from a **second** terminal with `curl`.
3. For an exercise, copy the folder named in the lesson (for example `MinimalNotes` for lesson 05) to your own folder, or use the `exercise/starter` project, and run it there.

**Folder: the extracted repository root `Code101` (contains `source` and `tutorials`)**
```text
cd source/csharp/201-hero-to-super-hero/phase-2-web-apis/06-dtos-validation-result-problemdetails/code
dotnet run --project . --urls http://localhost:5061
```

## Ports used
Lesson 05: 5051 (minimal), 5052 (controllers), 5053 (FastEndpoints). Lesson 06: 5061. Lesson 07: 5071 and 5072. Servers listen on `localhost` only. If a port is busy, pick another in `--urls`.

## First-timer time
Lesson 05: 70-80 minutes; 06: 70-80; 07: 60-70. The last lesson of the phase ends with a mixed review.

## Needs
.NET SDK 11.0.100 / net11.0, `curl`, internet access for the first package restore. NuGet packages used: FastEndpoints 9.0.0, FluentValidation.DependencyInjectionExtensions 12.2.0, Microsoft.Extensions.DependencyInjection 11.0.0 (lesson 07 exercise). No Docker. No secrets: the sample data is invented. Source files use UTF-8 without BOM; `bin/` and `obj/` are build output and are not part of the pack.

Next: Phase 3, Data (lessons 08 and 09), which needs Docker.
