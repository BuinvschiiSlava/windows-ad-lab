#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$ServerIsoPath,

    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$ClientIsoPath,

    [string]$ConfigPath = (Join-Path $PSScriptRoot '..\..\config\lab.psd1'),
    [string]$VmRoot = 'C:\HyperV\WindowsADLab'
)

$ErrorActionPreference = 'Stop'

$prerequisitesScript = Join-Path $PSScriptRoot 'Test-LabPrerequisites.ps1'
$networkScript = Join-Path $PSScriptRoot 'New-LabNetwork.ps1'
$virtualMachinesScript = Join-Path $PSScriptRoot 'New-LabVirtualMachines.ps1'

Write-Host '1/3 Checking host prerequisites...' -ForegroundColor Cyan
& $prerequisitesScript

Write-Host '2/3 Preparing the isolated Hyper-V network...' -ForegroundColor Cyan
& $networkScript -ConfigPath $ConfigPath

Write-Host '3/3 Creating DC01 and CLIENT01...' -ForegroundColor Cyan
& $virtualMachinesScript `
    -ServerIsoPath $ServerIsoPath `
    -ClientIsoPath $ClientIsoPath `
    -ConfigPath $ConfigPath `
    -VmRoot $VmRoot

if ($WhatIfPreference) {
    Write-Host 'Preview completed. Run again without -WhatIf to create the lab.' -ForegroundColor Yellow
}
else {
    Write-Host 'Bootstrap completed. Start DC01 and install Windows Server with Desktop Experience.' -ForegroundColor Green
}
