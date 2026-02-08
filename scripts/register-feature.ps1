#Requires -Version 7.0
<#
.SYNOPSIS
    Registers a SpecKit feature for overnight execution.

.DESCRIPTION
    Adds a feature entry (specDir + branch) to overnight-config.json. Avoids duplicates
    unless -Force is provided.

.PARAMETER SpecDir
    Path to the feature spec directory (e.g., specs/001-user-profile).

.PARAMETER Branch
    Feature branch name (e.g., feature/001-user-profile).

.PARAMETER ConfigPath
    Path to overnight-config.json, relative to repo root.

.PARAMETER Force
    Overwrite existing feature entry if it already exists.

.EXAMPLE
  .\scripts\Register-Feature.ps1 -SpecDir "specs/001-user-profile" -Branch "feature/001-user-profile"
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$SpecDir,

  [Parameter(Mandatory)]
  [string]$Branch,

  [string]$ConfigPath = "overnight-config.json",

  [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$configFullPath = Join-Path $repoRoot $ConfigPath

if (-not (Test-Path $configFullPath -PathType Leaf)) {
  throw "Config file not found: $configFullPath"
}

$config = Get-Content $configFullPath -Raw | ConvertFrom-Json
if (-not $config.features) {
  $config | Add-Member -NotePropertyName features -NotePropertyValue @()
}

$existing = $config.features | Where-Object {
  $_.specDir -eq $SpecDir -or $_.branch -eq $Branch
}

if ($existing -and -not $Force) {
  Write-Host "Feature already registered. Use -Force to overwrite." -ForegroundColor Yellow
  return
}

# Remove existing entries with the same specDir or branch
if ($existing) {
  $config.features = @($config.features | Where-Object {
      $_.specDir -ne $SpecDir -and $_.branch -ne $Branch
    })
}

$config.features += [PSCustomObject]@{
  specDir = $SpecDir
  branch  = $Branch
}

$config | ConvertTo-Json -Depth 10 | Set-Content -Path $configFullPath -Encoding utf8
Write-Host "Registered feature: $SpecDir -> $Branch" -ForegroundColor Green
