param(
    [ValidateRange(0, 16)][int]$NumParallel = 0,
    [ValidateRange(0, 8)][int]$MaxLoadedModels = 0,
    [ValidateRange(0, 4096)][int]$MaxQueue = 0,
    [string]$KeepAlive = "",
    [switch]$Remove
)

$names = @("OLLAMA_NUM_PARALLEL", "OLLAMA_MAX_LOADED_MODELS", "OLLAMA_MAX_QUEUE", "OLLAMA_KEEP_ALIVE")

if ($Remove) {
    foreach ($name in $names) {
        [Environment]::SetEnvironmentVariable($name, $null, "User")
    }
    Write-Host "Removed the four OLLAMA_* variables from your user environment."
}
else {
    if ($NumParallel -gt 0) { [Environment]::SetEnvironmentVariable("OLLAMA_NUM_PARALLEL", "$NumParallel", "User") }
    if ($MaxLoadedModels -gt 0) { [Environment]::SetEnvironmentVariable("OLLAMA_MAX_LOADED_MODELS", "$MaxLoadedModels", "User") }
    if ($MaxQueue -gt 0) { [Environment]::SetEnvironmentVariable("OLLAMA_MAX_QUEUE", "$MaxQueue", "User") }
    if ($KeepAlive -match '^-?\d+[smh]?$') { [Environment]::SetEnvironmentVariable("OLLAMA_KEEP_ALIVE", $KeepAlive, "User") }
    elseif ($KeepAlive -ne "") { throw "KeepAlive must look like 10m, 3600 or -1" }
}

foreach ($name in $names) {
    $value = [Environment]::GetEnvironmentVariable($name, "User")
    if ($value) { Write-Host "$name = $value" } else { Write-Host "$name = (not set)" }
}
Write-Host "Quit Ollama from the tray icon and start it again for changes to take effect."
