#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot '..\..\config\lab.psd1'),
    [string]$ComputerName = 'CLIENT01',
    [switch]$Restart
)

. (Join-Path $PSScriptRoot '..\common\Lab.Common.ps1')
Assert-Administrator
$config = Get-LabConfiguration -Path $ConfigPath

$adapter = Get-NetAdapter | Where-Object Status -eq 'Up' | Sort-Object ifIndex | Select-Object -First 1
Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses @($config.DomainControllerIp)

if ($env:COMPUTERNAME -ne $ComputerName) {
    Rename-Computer -NewName $ComputerName -Force
}

$credential = Get-Credential -Message "Enter an account allowed to join $($config.DomainName)"
if ($PSCmdlet.ShouldProcess($ComputerName, "Join domain $($config.DomainName)")) {
    Add-Computer -DomainName $config.DomainName -Credential $credential `
        -OUPath "OU=Computers,$(Get-DomainDistinguishedName -DomainName $config.DomainName)" -Force
}

Write-Host 'Domain join completed. Restart the client to apply it.' -ForegroundColor Green
if ($Restart) {
    Restart-Computer -Force
}

