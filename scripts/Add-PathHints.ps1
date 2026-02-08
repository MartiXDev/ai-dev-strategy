#Requires -Version 7.0
<#
.SYNOPSIS
    Adds [PATH:...] hints to tasks.md lines based on conventional locations.

.DESCRIPTION
    Scans a SpecKit tasks.md file and appends PATH hints for tasks missing them.
    Path hints are inferred from task category and feature name conventions.

.PARAMETER TasksFile
    Path to tasks.md.

.PARAMETER FeatureName
    Optional feature name used for C# folder (e.g., UserProfile -> src/Features/UserProfile).

.PARAMETER FeatureSlug
    Optional feature slug used for frontend paths (e.g., user-profile -> src/app/features/user-profile).

.PARAMETER DryRun
    If set, prints changes without modifying the file.

.EXAMPLE
    .\scripts\Add-PathHints.ps1 -TasksFile "specs/001-user-profile/tasks.md"
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$TasksFile,

  [string]$FeatureName,

  [string]$FeatureSlug,

  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path $TasksFile -PathType Leaf)) {
  throw "Tasks file not found: $TasksFile"
}

function To-PascalCase {
  param([string]$Value)
  $parts = $Value -split '[-_\s]+'
  $parts = $parts | Where-Object { $_ }
  return ($parts | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1) }) -join ''
}

function Infer-FeatureSlug {
  param([string]$Path)
  $folder = Split-Path -Parent $Path | Split-Path -Leaf
  if ($folder -match '^\d+[-_](.+)$') {
    return $Matches[1].ToLowerInvariant()
  }
  return $folder.ToLowerInvariant()
}

if (-not $FeatureSlug) {
  $FeatureSlug = Infer-FeatureSlug -Path $TasksFile
}

if (-not $FeatureName) {
  $FeatureName = To-PascalCase -Value $FeatureSlug
}

$pathMap = @{
  "BACKEND"    = "src/Features/$FeatureName"
  "FRONTEND"   = "src/app/features/$FeatureSlug"
  "FULLSTACK"  = "src/Features/$FeatureName, src/app/features/$FeatureSlug"
  "TEST-UNIT"  = "tests/Features/$FeatureName"
  "TEST-INTEG" = "tests/Integration/$FeatureName"
  "TEST-E2E"   = "e2e"
  "DEVOPS"     = ".github/workflows"
  "DOCS"       = "docs"
}

$lines = Get-Content -Path $TasksFile -Encoding utf8
$updated = @()
$changed = $false

foreach ($line in $lines) {
  if ($line -match '^\s*-\s+\[[ xX]\]\s+(.+)$') {
    if ($line -notmatch '\[PATH:[^\]]+\]') {
      if ($line -match '\[(BACKEND|FRONTEND|FULLSTACK|TEST-UNIT|TEST-INTEG|TEST-E2E|SECURITY|A11Y|DEVOPS|DOCS)\]') {
        $category = $Matches[1]
        if ($pathMap.ContainsKey($category)) {
          $pathHint = $pathMap[$category]
          if ($pathHint) {
            $updated += ($line + " [PATH:$pathHint]")
            $changed = $true
            continue
          }
        }
      }
    }
  }

  $updated += $line
}

if ($DryRun) {
  if ($changed) {
    Write-Host "[DryRun] PATH hints would be added to: $TasksFile" -ForegroundColor Yellow
  }
  else {
    Write-Host "[DryRun] No changes needed: $TasksFile" -ForegroundColor Green
  }
  return
}

if ($changed) {
  $updated | Set-Content -Path $TasksFile -Encoding utf8
  Write-Host "PATH hints added: $TasksFile" -ForegroundColor Green
}
else {
  Write-Host "No PATH hints needed: $TasksFile" -ForegroundColor Green
}
