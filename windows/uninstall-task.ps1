param(
    [string]$TaskName = "WSL Network Autopilot"
)

$ErrorActionPreference = "Stop"
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false

$launcherDirectory = Join-Path $env:LOCALAPPDATA "WSLNetworkAutopilot"
if (Test-Path $launcherDirectory) {
    Remove-Item -Path $launcherDirectory -Recurse -Force
}

Write-Output "Removed scheduled task: $TaskName"
