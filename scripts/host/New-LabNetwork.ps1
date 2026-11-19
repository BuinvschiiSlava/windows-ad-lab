#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot '..\..\config\lab.psd1')
)

. (Join-Path $PSScriptRoot '..\common\Lab.Common.ps1')
Assert-Administrator
$config = Get-LabConfiguration -Path $ConfigPath

if (-not (Get-VMSwitch -Name $config.HyperVSwitch -ErrorAction SilentlyContinue)) {
    if ($PSCmdlet.ShouldProcess($config.HyperVSwitch, 'Create internal Hyper-V switch')) {
        New-VMSwitch -Name $config.HyperVSwitch -SwitchType Internal | Out-Null
    }
}

$adapterName = "vEthernet ($($config.HyperVSwitch))"
$adapter = Get-NetAdapter -Name $adapterName -ErrorAction Stop
if (-not (Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object IPAddress -eq $config.LabGateway)) {
    if ($PSCmdlet.ShouldProcess($adapterName, "Assign $($config.LabGateway)/$($config.PrefixLength)")) {
        New-NetIPAddress -InterfaceIndex $adapter.ifIndex -IPAddress $config.LabGateway -PrefixLength $config.PrefixLength | Out-Null
    }
}

if (-not (Get-NetNat -Name $config.NatName -ErrorAction SilentlyContinue)) {
    if ($PSCmdlet.ShouldProcess($config.NatName, "Create NAT for $($config.LabSubnet)")) {
        New-NetNat -Name $config.NatName -InternalIPInterfaceAddressPrefix $config.LabSubnet | Out-Null
    }
}

Write-Host "Lab network is ready: $($config.HyperVSwitch), $($config.LabSubnet)" -ForegroundColor Green

