#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })][string]$MsiPath,
    [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedSha256,
    [string]$ConfigPath = (Join-Path $PSScriptRoot '..\..\config\lab.psd1'),
    [string]$HostName = $env:COMPUTERNAME
)

. (Join-Path $PSScriptRoot '..\common\Lab.Common.ps1')
Assert-Administrator
$config = Get-LabConfiguration -Path $ConfigPath

$actualHash = (Get-FileHash -LiteralPath $MsiPath -Algorithm SHA256).Hash
if ($actualHash -ne $ExpectedSha256.ToUpperInvariant()) {
    throw "Zabbix agent MSI checksum mismatch. Expected $ExpectedSha256, received $actualHash."
}

$arguments = @(
    '/i', ('"{0}"' -f (Resolve-Path -LiteralPath $MsiPath).Path),
    '/qn', '/norestart',
    'SERVER={0}' -f $config.ZabbixServer,
    'SERVERACTIVE={0}' -f $config.ZabbixServer,
    'HOSTNAME={0}' -f $HostName
)

if ($PSCmdlet.ShouldProcess($HostName, "Install Zabbix Agent 2 from $MsiPath")) {
    $process = Start-Process -FilePath msiexec.exe -ArgumentList $arguments -Wait -PassThru
    if ($process.ExitCode -notin 0, 3010) {
        throw "Zabbix agent installation failed with exit code $($process.ExitCode)."
    }
}

Get-Service -Name 'Zabbix Agent 2' -ErrorAction Stop | Select-Object Name, Status, StartType

