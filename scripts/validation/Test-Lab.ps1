#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot '..\..\config\lab.psd1')
)

. (Join-Path $PSScriptRoot '..\common\Lab.Common.ps1')
$config = Get-LabConfiguration -Path $ConfigPath
$results = [System.Collections.Generic.List[object]]::new()

function Add-Result {
    param([string]$Check, [bool]$Passed, [string]$Details)
    $results.Add([pscustomobject]@{ Check = $Check; Passed = $Passed; Details = $Details })
}

try {
    $dns = Resolve-DnsName "$($config.DomainController).$($config.DomainName)" -Type A -ErrorAction Stop
    Add-Result 'Domain controller DNS' ($dns.IPAddress -contains $config.DomainControllerIp) ($dns.IPAddress -join ', ')
} catch { Add-Result 'Domain controller DNS' $false $_.Exception.Message }

try {
    $ldap = Test-NetConnection -ComputerName $config.DomainControllerIp -Port 389 -WarningAction SilentlyContinue
    Add-Result 'LDAP port 389' $ldap.TcpTestSucceeded "RemoteAddress=$($ldap.RemoteAddress)"
} catch { Add-Result 'LDAP port 389' $false $_.Exception.Message }

try {
    $smb = Test-NetConnection -ComputerName $config.DomainControllerIp -Port 445 -WarningAction SilentlyContinue
    Add-Result 'SMB port 445' $smb.TcpTestSucceeded "RemoteAddress=$($smb.RemoteAddress)"
} catch { Add-Result 'SMB port 445' $false $_.Exception.Message }

$domain = Get-CimInstance Win32_ComputerSystem
Add-Result 'Client joined to domain' ($domain.PartOfDomain -and $domain.Domain -eq $config.DomainName) "Domain=$($domain.Domain)"
Add-Result 'Company share reachable' (Test-Path "\\$($config.DomainController)\$($config.ShareName)") "Share=$($config.ShareName)"

$results | Format-Table -AutoSize
if ($results.Where({ -not $_.Passed }).Count -gt 0) {
    throw 'One or more lab validation checks failed.'
}

Write-Host 'All lab validation checks passed.' -ForegroundColor Green

