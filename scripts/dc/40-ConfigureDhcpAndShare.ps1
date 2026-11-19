#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot '..\..\config\lab.psd1')
)

. (Join-Path $PSScriptRoot '..\common\Lab.Common.ps1')
Assert-Administrator
$config = Get-LabConfiguration -Path $ConfigPath

Install-WindowsFeature DHCP, FS-FileServer -IncludeManagementTools | Out-Null
Import-Module DhcpServer
Import-Module ActiveDirectory

if (-not (Get-DhcpServerv4Scope -ScopeId (($config.LabSubnet -split '/')[0]) -ErrorAction SilentlyContinue)) {
    if ($PSCmdlet.ShouldProcess($config.DhcpScopeName, 'Create DHCP scope')) {
        Add-DhcpServerv4Scope -Name $config.DhcpScopeName -StartRange $config.DhcpScopeStart `
            -EndRange $config.DhcpScopeEnd -SubnetMask $config.DhcpSubnetMask -State Active | Out-Null
    }
}

$scopeId = ($config.LabSubnet -split '/')[0]
Set-DhcpServerv4OptionValue -ScopeId $scopeId -Router $config.LabGateway `
    -DnsServer $config.DomainControllerIp -DnsDomain $config.DomainName

$dcFqdn = "$($config.DomainController).$($config.DomainName)"
if (-not (Get-DhcpServerInDC -ErrorAction SilentlyContinue | Where-Object DnsName -eq $dcFqdn)) {
    Add-DhcpServerInDC -DnsName $dcFqdn -IPAddress $config.DomainControllerIp
}

if (-not (Test-Path -LiteralPath $config.SharePath)) {
    New-Item -ItemType Directory -Path $config.SharePath -Force | Out-Null
}

$modifyGroup = "$($config.NetBIOSName)\GG-Shared-Modify"
$readGroup = "$($config.NetBIOSName)\GG-Shared-Read"
$acl = Get-Acl -LiteralPath $config.SharePath
$acl.SetAccessRuleProtection($true, $false)
$acl.SetAccessRule([Security.AccessControl.FileSystemAccessRule]::new(
    'BUILTIN\Administrators', 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow'))
$acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new(
    $modifyGroup, 'Modify', 'ContainerInherit,ObjectInherit', 'None', 'Allow'))
$acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new(
    $readGroup, 'ReadAndExecute', 'ContainerInherit,ObjectInherit', 'None', 'Allow'))
Set-Acl -LiteralPath $config.SharePath -AclObject $acl

if (-not (Get-SmbShare -Name $config.ShareName -ErrorAction SilentlyContinue) -and
    $PSCmdlet.ShouldProcess($config.ShareName, 'Create SMB share')) {
    New-SmbShare -Name $config.ShareName -Path $config.SharePath `
        -FullAccess 'BUILTIN\Administrators' -ChangeAccess $modifyGroup -ReadAccess $readGroup | Out-Null
}

Write-Host "DHCP and SMB share are ready: \\$($config.DomainController)\$($config.ShareName)" -ForegroundColor Green

