#Requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$checks = [System.Collections.Generic.List[object]]::new()

function Add-Check {
    param([string]$Name, [bool]$Passed, [string]$Details)
    $checks.Add([pscustomobject]@{ Check = $Name; Passed = $Passed; Details = $Details })
}

$isAdministrator = ([Security.Principal.WindowsPrincipal]::new(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Add-Check -Name 'Administrator session' -Passed $isAdministrator -Details 'Required for Hyper-V changes'

$hyperVModule = Get-Module -ListAvailable -Name Hyper-V | Select-Object -First 1
$hyperVVersion = if ($hyperVModule) { $hyperVModule.Version.ToString() } else { 'Not installed' }
Add-Check -Name 'Hyper-V PowerShell module' -Passed ($null -ne $hyperVModule) -Details $hyperVVersion

$hypervisor = (Get-CimInstance -ClassName Win32_ComputerSystem).HypervisorPresent
Add-Check -Name 'Hypervisor present' -Passed $hypervisor -Details "HypervisorPresent=$hypervisor"

$memoryGb = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
Add-Check -Name 'At least 12 GB RAM' -Passed ($memoryGb -ge 12) -Details "$memoryGb GB detected"

$systemDrive = Get-PSDrive -Name $env:SystemDrive.TrimEnd(':')
$freeGb = [math]::Round($systemDrive.Free / 1GB, 1)
Add-Check -Name 'At least 80 GB free' -Passed ($freeGb -ge 80) -Details "$freeGb GB free on $($env:SystemDrive)"

$checks | Format-Table -AutoSize
if ($checks.Where({ -not $_.Passed }).Count -gt 0) {
    throw 'One or more prerequisites failed. Resolve them before creating the lab.'
}

Write-Host 'All prerequisites passed.' -ForegroundColor Green

