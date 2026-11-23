# Databases 101, Phase 2: Shaping Data

PostgreSQL only in Docker. Four independent lessons for complete beginners. Each includes runnable code, a starter, a full solution and verify.json. Status: **verified** on 2026-11-23: all four lesson smoke checks PASS, including their exercise solutions. See the matching tutorial for real output.

| Folder | Lesson | Outcome |
|---|---|---|
| `05-changing-data` | Changing data | A targeted price increase, one deleted book, and a final catalogue showing what remains. |
| `06-keys-and-relationships` | Keys and relationships | Members with generated identifiers, loans with their own identifiers, and a one-to-many relationship between them. |
| `07-joining-tables` | Joining tables | One report of members with loans and another that keeps members who have no loans. |
| `08-summaries` | Summaries | Overall sales totals and a per-category report, then exclude categories with too few items sold. |

## Prerequisites and extraction
- Complete Docker 101 lesson 01; Docker must be running in Linux-container mode. Author baseline: CLI/Engine 29.9.3, Compose 5.7.0, official postgres:17-alpine (Docker Hub checked 2026-11-23).
- No system-wide PostgreSQL, psql, Python or .NET install. IDEs are optional; lesson 02 shows JetBrains/VS Code settings and an honest Visual Studio provider note.
- Windows: right-click zip > Extract All to your home folder's code101 folder. macOS: double-click and move its extracted folder to code101. Linux: Extract Here, then move the folder to code101.
- Open a lesson's code folder; keep the adjacent exercise folder. A code folder alone is not the complete lab because Compose also mounts ../exercise.
- Only one database lab at a time: every lesson binds 127.0.0.1:5432:5432. Docker 101 does not publish this port. Finish the previous project with down -v before the next.

## Run (PowerShell 5.1; macOS/Linux differences shown)
**Terminal (folder: `05-changing-data/code`)**
```powershell
Set-Location "$HOME\code101\databases-101-phase-2-shaping-data\05-changing-data\code"
Copy-Item .env.example .env
docker compose -p code101-db05 up -d --wait
docker compose -p code101-db05 ps --format "{{.Service}} {{.State}} {{.Health}}"
docker compose -p code101-db05 logs --no-log-prefix --tail 2 db
docker compose -p code101-db05 exec -T db psql -X -q -v ON_ERROR_STOP=1 -U learner -d code101 -f /scripts/lesson.sql
```

On macOS/Linux use `cd "$HOME/code101/databases-101-phase-2-shaping-data/05-changing-data/code"` and `cp .env.example .env`; Docker commands are identical. For another lesson, change the folder and use its project code101-dbNN (NN is the two-digit lesson number). Lessons 01-11 run lesson.sql; lesson 12 runs run.sql. Do not change only one command's project name.

## Exercises
Copy exercise/starter/exercise.sql into code/exercise.sql. Read the matching tutorial, replace its TODO and save. Run the same psql command with -f /scripts/exercise.sql. The solution is exercise/solution/exercise.sql. It can also be run from code with -f /exercises/solution/exercise.sql. Exercise include files reset the sample so repeated attempts are independent. Lesson 12's full project is a first-run script; reset its disposable volume before running run.sql again.

## Safety and cleanup
The example password is public, disposable and local-only; never reuse it. Copy .env.example to .env; .gitignore excludes .env and dump archives. POSTGRES_USER is an administrative bootstrap role, not an application login recommendation. SQL setup resets the named sample schema. Never run these scripts against real data. stop keeps the data; down -v deletes it. After your exercise:
**Terminal (folder: `05-changing-data/code`; substitute the correct code101-dbNN for other lessons)**
```powershell
docker compose -p code101-db05 stop
docker compose -p code101-db05 down -v --remove-orphans
```


## For maintainers
verify.json requires docker, checks the engine, copies .env.example to .env in a temporary clean copy, starts a code101-verify-* Compose project with --wait, runs the SQL once and the exercise solution once, and always removes the project with down -v --remove-orphans. Run lessons sequentially because of host port 5432. No unit suites, linters or benchmarks. No custom images are built. No art is used. Full SQL result tables and actual errors are in the tutorials; author captures are tracked under tutorials/databases.
