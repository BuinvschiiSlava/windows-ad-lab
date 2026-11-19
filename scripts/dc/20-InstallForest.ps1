#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot '..\..\config\lab.psd1')
)

. (Join-Path $PSScriptRoot '..\common\Lab.Common.ps1')
Assert-Administrator
$config = Get-LabConfiguration -Path $ConfigPath

$computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
if ($computerSystem.DomainRole -ge 4) {
    Write-Host 'An Active Directory domain is already available. No change was made.' -ForegroundColor Yellow
    return
}

if ($PSCmdlet.ShouldProcess($config.DomainName, 'Install AD DS forest and DNS')) {
    Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools | Out-Null
    Import-Module ADDSDeployment
    $safeModePassword = Read-Host 'Enter a unique Directory Services Restore Mode password' -AsSecureString
    Install-ADDSForest -DomainName $config.DomainName -DomainNetbiosName $config.NetBIOSName `
        -InstallDns -SafeModeAdministratorPassword $safeModePassword -Force
}

