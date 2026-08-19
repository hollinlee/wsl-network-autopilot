param(
    [Parameter(Mandatory = $true)]
    [string]$Distro,

    [Parameter(Mandatory = $true)]
    [string]$LinuxUser,

    [Parameter(Mandatory = $true)]
    [string]$LinuxCommand,

    [string]$LinuxArguments = ""
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($LinuxArguments)) {
    & wsl.exe -d $Distro -u $LinuxUser -- $LinuxCommand
} else {
    & wsl.exe -d $Distro -u $LinuxUser -- $LinuxCommand $LinuxArguments
}
exit $LASTEXITCODE
