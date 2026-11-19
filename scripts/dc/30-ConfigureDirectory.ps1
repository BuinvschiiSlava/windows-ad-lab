#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot '..\..\config\lab.psd1')
)

. (Join-Path $PSScriptRoot '..\common\Lab.Common.ps1')
Assert-Administrator
$config = Get-LabConfiguration -Path $ConfigPath

Import-Module ActiveDirectory
Import-Module DnsServer
Import-Module GroupPolicy

$domainDn = Get-DomainDistinguishedName -DomainName $config.DomainName
$userPassword = Read-Host 'Enter a temporary password for the disposable lab users' -AsSecureString

foreach ($ouName in $config.OrganizationalUnits) {
    $existingOu = Get-ADOrganizationalUnit -LDAPFilter "(ou=$ouName)" -SearchBase $domainDn -SearchScope OneLevel -ErrorAction SilentlyContinue
    if (-not $existingOu -and $PSCmdlet.ShouldProcess($ouName, 'Create organizational unit')) {
        New-ADOrganizationalUnit -Name $ouName -Path $domainDn -ProtectedFromAccidentalDeletion $true | Out-Null
    }
}

$groupsOu = "OU=Groups,$domainDn"
foreach ($groupName in $config.SecurityGroups) {
    if (-not (Get-ADGroup -Identity $groupName -ErrorAction SilentlyContinue) -and
        $PSCmdlet.ShouldProcess($groupName, 'Create global security group')) {
        New-ADGroup -Name $groupName -SamAccountName $groupName -GroupCategory Security `
            -GroupScope Global -Path $groupsOu | Out-Null
    }
}

$usersOu = "OU=Users,$domainDn"
foreach ($definition in $config.LabUsers) {
    $sam = $definition.SamAccountName
    if (-not (Get-ADUser -Identity $sam -ErrorAction SilentlyContinue) -and
        $PSCmdlet.ShouldProcess($sam, 'Create disposable lab user')) {
        New-ADUser -Name $definition.DisplayName -DisplayName $definition.DisplayName `
            -SamAccountName $sam -UserPrincipalName "$sam@$($config.DomainName)" `
            -Department $definition.Department -Path $usersOu -AccountPassword $userPassword `
            -Enabled $true -ChangePasswordAtLogon $true | Out-Null
    }
    foreach ($group in $definition.Groups) {
        if ($PSCmdlet.ShouldProcess("$sam -> $group", 'Add user to security group')) {
            Add-ADGroupMember -Identity $group -Members $sam -ErrorAction SilentlyContinue
        }
    }
}

$subnetParts = $config.LabSubnet -split '/'
if ($subnetParts[1] -ne '24') {
    throw 'The automatic reverse-zone setup currently expects a /24 lab subnet.'
}
$networkOctets = $subnetParts[0] -split '\.'
$reverseZoneName = "$($networkOctets[2]).$($networkOctets[1]).$($networkOctets[0]).in-addr.arpa"
$zoneNetworkId = $config.LabSubnet
if (-not (Get-DnsServerZone | Where-Object ZoneName -eq $reverseZoneName) -and
    $PSCmdlet.ShouldProcess($zoneNetworkId, 'Create reverse DNS zone')) {
    Add-DnsServerPrimaryZone -NetworkId $zoneNetworkId -ReplicationScope Domain | Out-Null
}

Set-DnsServerForwarder -IPAddress $config.DnsForwarders -PassThru | Out-Null

$baselineGpoName = 'CORP - Workstation Baseline'
if (-not (Get-GPO -Name $baselineGpoName -ErrorAction SilentlyContinue) -and
    $PSCmdlet.ShouldProcess($baselineGpoName, 'Create and link workstation baseline GPO')) {
    $gpo = New-GPO -Name $baselineGpoName
    New-GPLink -Name $gpo.DisplayName -Target "OU=Computers,$domainDn" -LinkEnabled Yes | Out-Null
    Set-GPRegistryValue -Name $gpo.DisplayName `
        -Key 'HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System' `
        -ValueName 'DontDisplayLastUserName' -Type DWord -Value 1 | Out-Null
}

Write-Host 'Directory structure, groups, users, DNS forwarders and baseline GPO are configured.' -ForegroundColor Green

