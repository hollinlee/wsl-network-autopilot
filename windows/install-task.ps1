param(
    [Parameter(Mandatory = $true)]
    [string]$Distro,

    [Parameter(Mandatory = $true)]
    [string]$LinuxUser,

    [ValidateRange(1, 1440)]
    [int]$IntervalMinutes = 5,

    [string]$TaskName = "WSL Network Autopilot"
)

$ErrorActionPreference = "Stop"
$arguments = "-d $Distro -u $LinuxUser -- /home/$LinuxUser/.local/bin/wsl-network check"
$action = New-ScheduledTaskAction -Execute "wsl.exe" -Argument $arguments
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
