#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot '..\..\config\lab.psd1'),
    [switch]$Restart
)

. (Join-Path $PSScriptRoot '..\common\Lab.Common.ps1')
Assert-Administrator
$config = Get-LabConfiguration -Path $ConfigPath

$adapter = Get-NetAdapter | Where-Object Status -eq 'Up' | Sort-Object ifIndex | Select-Object -First 1
if (-not $adapter) {
    throw 'No active network adapter was found.'
}

if ($PSCmdlet.ShouldProcess($adapter.Name, 'Configure static IPv4 and DNS')) {
    Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object PrefixOrigin -ne 'WellKnown' |
        Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
    Get-NetRoute -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object DestinationPrefix -eq '0.0.0.0/0' |
        Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue

    New-NetIPAddress -InterfaceIndex $adapter.ifIndex -IPAddress $config.DomainControllerIp `
        -PrefixLength $config.PrefixLength -DefaultGateway $config.LabGateway | Out-Null
    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses @($config.DomainControllerIp)
}

if ($env:COMPUTERNAME -ne $config.DomainController) {
    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Rename to $($config.DomainController)")) {
        Rename-Computer -NewName $config.DomainController -Force
    }
}

Write-Host 'Domain controller preparation completed. Restart before installing the forest.' -ForegroundColor Green
if ($Restart) {
    Restart-Computer -Force
}

