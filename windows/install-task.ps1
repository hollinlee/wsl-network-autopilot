param(
    [Parameter(Mandatory = $true)]
    [string]$Distro,

    [Parameter(Mandatory = $true)]
    [string]$LinuxUser,

    [string]$LinuxHome,

    [ValidateRange(1, 1440)]
    [int]$IntervalMinutes = 5,

    [string]$TaskName = "WSL Network Autopilot"
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($LinuxHome)) {
    $LinuxHome = "/home/$LinuxUser"
}

$launcherSource = Join-Path $PSScriptRoot "invoke-wsl-hidden.ps1"
$launcherDirectory = Join-Path $env:LOCALAPPDATA "WSLNetworkAutopilot"
$launcherPath = Join-Path $launcherDirectory "invoke-wsl-hidden.ps1"
if (-not (Test-Path $launcherSource)) {
    throw "Missing launcher: $launcherSource"
}
New-Item -ItemType Directory -Path $launcherDirectory -Force | Out-Null
Copy-Item -Path $launcherSource -Destination $launcherPath -Force

$linuxCommand = "$LinuxHome/.local/bin/wsl-network"
$arguments = @(
    "-NoProfile"
    "-NonInteractive"
    "-WindowStyle Hidden"
    "-ExecutionPolicy Bypass"
    "-File `"$launcherPath`""
    "-Distro `"$Distro`""
    "-LinuxUser `"$LinuxUser`""
    "-LinuxCommand `"$linuxCommand`""
    "-LinuxArguments check"
) -join " "
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $arguments
$trigger = New-ScheduledTaskTrigger `
    -Once `
    -At (Get-Date).AddMinutes(1) `
    -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes)
$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 1) `
    -MultipleInstances IgnoreNew

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description "Recover WSL connectivity and optional captive-portal authentication" `
    -Force | Out-Null

Write-Output "Installed scheduled task: $TaskName"
