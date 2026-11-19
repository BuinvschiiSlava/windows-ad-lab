Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-LabConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
        [string]$Path
    )

    $resolvedPath = (Resolve-Path -LiteralPath $Path).Path
    $configuration = Import-PowerShellDataFile -LiteralPath $resolvedPath

    foreach ($requiredKey in @('DomainName', 'NetBIOSName', 'DomainControllerIp', 'PrefixLength')) {
        if (-not $configuration.ContainsKey($requiredKey) -or [string]::IsNullOrWhiteSpace([string]$configuration[$requiredKey])) {
            throw "Required configuration key is missing: $requiredKey"
        }
    }

    return $configuration
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-Administrator {
    if (-not (Test-Administrator)) {
        throw 'Run this script from an elevated PowerShell session.'
    }
}

function Get-DomainDistinguishedName {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$DomainName)

    return (($DomainName -split '\.') | ForEach-Object { "DC=$_" }) -join ','
}

