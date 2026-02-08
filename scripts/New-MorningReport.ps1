#Requires -Version 7.0
<#
.SYNOPSIS
    Creates a morning report from overnight run summary JSON.

.DESCRIPTION
    Reads logs/overnight-summary.json and produces morning-report.md in the repo root.

.PARAMETER SummaryPath
    Path to the summary JSON file (relative to repo root).

.PARAMETER OutputPath
    Path to the markdown report output (relative to repo root).
#>

[CmdletBinding()]
param(
  [string]$SummaryPath = "logs/overnight-summary.json",
  [string]$OutputPath = "morning-report.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$summaryFullPath = Join-Path $repoRoot $SummaryPath
$outputFullPath = Join-Path $repoRoot $OutputPath

if (-not (Test-Path $summaryFullPath -PathType Leaf)) {
  throw "Summary not found: $summaryFullPath"
}

$summary = Get-Content $summaryFullPath -Raw | ConvertFrom-Json

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("# Morning Report - $($summary.date)")
$lines.Add("")
$lines.Add("## Summary")
$lines.Add("- Features processed: $($summary.features.Count)")
$lines.Add("- Total tasks completed: $($summary.totals.completed)")
$lines.Add("- Total tasks failed: $($summary.totals.failed)")
$lines.Add("- Total tasks skipped: $($summary.totals.skipped)")
$lines.Add("- Total runtime: $($summary.totals.runtime)")
$lines.Add("- Estimated cost: $($summary.totals.estimatedCost) / $($summary.totals.budgetDollars)")
$lines.Add("- Premium requests: $($summary.totals.premiumRequests) / $($summary.totals.maxPremiumRequests)")
$lines.Add("")

if ($summary.modelUsage) {
  $lines.Add("## Model Usage")
  foreach ($model in $summary.modelUsage.PSObject.Properties.Name) {
    $lines.Add("- $model: $($summary.modelUsage.$model)")
  }
  $lines.Add("")
}

foreach ($feature in $summary.features) {
  $lines.Add("## Feature: $($feature.branch)")
  $lines.Add("- Spec: $($feature.specDir)")
  $lines.Add("- Worktree: $($feature.worktreePath)")
  $lines.Add("- Completed: $($feature.completed)")
  $lines.Add("- Failed: $($feature.failed)")
  $lines.Add("- Skipped: $($feature.skipped)")
  if ($feature.draftPrUrl) {
    $lines.Add("- Draft PR: $($feature.draftPrUrl)")
  }
  $lines.Add("")

  $lines.Add("### Tasks")
  foreach ($task in $feature.tasks) {
    $status = $task.status
    $lines.Add("- [$status] $($task.id) [$($task.category)] $($task.description)")
  }
  $lines.Add("")
}

$lines | Set-Content -Path $outputFullPath -Encoding utf8
Write-Host "Morning report generated: $outputFullPath" -ForegroundColor Green
