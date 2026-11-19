#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })][string]$ServerIsoPath,
    [Parameter(Mandatory)][ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })][string]$ClientIsoPath,
    [string]$ConfigPath = (Join-Path $PSScriptRoot '..\..\config\lab.psd1'),
    [string]$VmRoot = 'C:\HyperV\WindowsADLab'
)

. (Join-Path $PSScriptRoot '..\common\Lab.Common.ps1')
Assert-Administrator
$config = Get-LabConfiguration -Path $ConfigPath

$definitions = @(
    @{ Name = 'DC01'; Memory = 4GB; Cpu = 2; Disk = 80GB; Iso = $ServerIsoPath },
    @{ Name = 'CLIENT01'; Memory = 4GB; Cpu = 2; Disk = 64GB; Iso = $ClientIsoPath }
)

foreach ($definition in $definitions) {
    if (Get-VM -Name $definition.Name -ErrorAction SilentlyContinue) {
        Write-Host "VM already exists: $($definition.Name)" -ForegroundColor Yellow
        continue
    }

    $vmPath = Join-Path $VmRoot $definition.Name
    $diskPath = Join-Path $vmPath "$($definition.Name).vhdx"
    if ($PSCmdlet.ShouldProcess($definition.Name, "Create Generation 2 VM in $vmPath")) {
        New-Item -ItemType Directory -Path $vmPath -Force | Out-Null
        New-VM -Name $definition.Name -Generation 2 -MemoryStartupBytes $definition.Memory `
            -NewVHDPath $diskPath -NewVHDSizeBytes $definition.Disk -Path $vmPath `
            -SwitchName $config.HyperVSwitch | Out-Null
        Set-VMProcessor -VMName $definition.Name -Count $definition.Cpu
        Set-VM -Name $definition.Name -AutomaticCheckpointsEnabled $false
        Add-VMDvdDrive -VMName $definition.Name -Path $definition.Iso | Out-Null
        Set-VMFirmware -VMName $definition.Name -EnableSecureBoot On -SecureBootTemplate MicrosoftWindows
    }
}

Get-VM -Name $definitions.Name | Select-Object Name, State, ProcessorCount, MemoryStartup | Format-Table -AutoSize

