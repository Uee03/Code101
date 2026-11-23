param(
    [string]$BackendDirectory,
    [ValidatePattern('^[a-z0-9][a-z0-9-]+$')][string]$Project = 'code101-kotlin-manual',
    [switch]$PrintPlan
)
$ErrorActionPreference = 'Stop'
if ($PrintPlan) {
    Write-Output 'Manual only: hold the tasksteams lock, start one backend, wait for the user, then remove its stack and API image.'
    exit 0
}
if (-not $BackendDirectory) { throw 'Pass -BackendDirectory pointing at a finished backend code folder.' }
$backend = (Resolve-Path $BackendDirectory).Path
$compose = @('--project-directory', $backend, '--env-file', (Join-Path $backend '.env.example'),
    '-p', $Project, '-f', (Join-Path $backend 'docker-compose.yml'),
    '-f', (Join-Path $backend 'docker-compose.override.yml'))
$previousNetwork = $env:TASKS_NETWORK
$env:TASKS_NETWORK = $Project + '-net'
try {
    & docker compose @compose up -d --build --wait
    if ($LASTEXITCODE -ne 0) { throw 'Backend did not become ready; see the Compose output.' }
    & docker compose @compose ps
    if ($LASTEXITCODE -ne 0) { throw 'Compose status failed.' }
    Write-Host 'Keep this terminal open: it owns the port lock. Use a second terminal for Android.'
    [void](Read-Host 'After device checks and adb cleanup, press Enter to remove this temporary backend')
} finally {
    & docker compose @compose down -v --remove-orphans
    & docker image rm ($Project + '-api')
    if ($null -eq $previousNetwork) { Remove-Item Env:TASKS_NETWORK -ErrorAction SilentlyContinue }
    else { $env:TASKS_NETWORK = $previousNetwork }
}
