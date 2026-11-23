$ErrorActionPreference = "Stop"

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$file = "backups\notes-$stamp.dump"

New-Item -ItemType Directory -Force backups | Out-Null
docker compose exec -T db pg_dump -U learner -d workshop -Fc -f /tmp/notes.dump
if ($LASTEXITCODE -ne 0) { throw "pg_dump failed" }
docker compose cp db:/tmp/notes.dump $file
if ($LASTEXITCODE -ne 0) { throw "docker compose cp failed" }
docker compose exec -T db rm -f /tmp/notes.dump
Write-Host "wrote $file"
