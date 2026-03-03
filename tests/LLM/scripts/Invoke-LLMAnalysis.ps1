<#
.SYNOPSIS
    Analyzes LLM test results and generates comparison reports.

.DESCRIPTION
    This script processes the results from LLM testing sessions and generates
    comprehensive comparison reports including performance metrics, cost analysis,
    and code quality assessments.

.PARAMETER SessionPath
    Path to the test session results directory

.PARAMETER OutputFormat
    Output format for the report: "markdown", "html", "json", or "all"

.EXAMPLE
    .\Invoke-LLMAnalysis.ps1 -SessionPath "..\results\2026-02-16_14-30-00_01-crud-api-with-validation"
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string]$SessionPath,

  [Parameter(Mandatory = $false)]
  [ValidateSet("markdown", "html", "json", "all")]
  [string]$OutputFormat = "all"
)

#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
$script:CmdletContext = $PSCmdlet

function New-DirectoryIfMissing {
  [CmdletBinding(SupportsShouldProcess = $true)]
  param(
    [Parameter(Mandatory)]
    [string]$Path
  )

  if ((-not (Test-Path $Path)) -and $PSCmdlet.ShouldProcess($Path, 'Create directory')) {
    New-Item -Path $Path -ItemType Directory -Force | Out-Null
  }
}

function Set-TextContent {
  [CmdletBinding(SupportsShouldProcess = $true)]
  param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory)]
    [AllowEmptyString()]
    [string]$Value
  )

  if ($PSCmdlet.ShouldProcess($Path, 'Write file')) {
    Set-Content -Path $Path -Value $Value -Encoding utf8
  }
}

function Set-JsonContent {
  [CmdletBinding(SupportsShouldProcess = $true)]
  param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory)]
    [object]$Value,

    [int]$Depth = 10
  )

  if ($PSCmdlet.ShouldProcess($Path, 'Write JSON file')) {
    $Value | ConvertTo-Json -Depth $Depth | Set-Content -Path $Path -Encoding utf8
  }
}

function Assert-SessionPath {
  if (-not (Test-Path -LiteralPath $SessionPath)) {
    Write-Error "Session path not found: $SessionPath"
    exit 1
  }
}

function Get-SessionMetadata {
  $metadataPath = Join-Path $SessionPath 'session-metadata.json'
  if (Test-Path $metadataPath) {
    return Get-Content $metadataPath -Raw | ConvertFrom-Json
  }

  return [PSCustomObject]@{
    Timestamp = 'N/A'
    PromptId  = 'N/A'
  }
}

function Get-TestResults {
  $resultsPath = Join-Path $SessionPath 'all-results.json'
  $results = @()

  if (Test-Path $resultsPath) {
    $results = Get-Content $resultsPath -Raw | ConvertFrom-Json
  }
  else {
    $llmDirs = Get-ChildItem -Path $SessionPath -Directory | Where-Object { $_.Name -ne 'reports' }
    foreach ($dir in $llmDirs) {
      $metricsFile = Join-Path $dir.FullName 'metrics.json'
      if (Test-Path $metricsFile) {
        $results += Get-Content $metricsFile -Raw | ConvertFrom-Json
      }
    }
  }

  if ($results -isnot [System.Array]) {
    return @($results)
  }

  return $results
}

function New-ReportsDirectory {
  $reportsPath = Join-Path $SessionPath 'reports'
  New-DirectoryIfMissing -Path $reportsPath

  return $reportsPath
}

function Get-QualityScore {
  param(
    [Parameter(Mandatory)]
    [object]$Result
  )

  if (-not $Result.codeQuality) {
    return 0
  }

  $checks = @(
    $Result.codeQuality.compilable
    $Result.codeQuality.followsBestPractices
    $Result.codeQuality.hasProperErrorHandling
    $Result.codeQuality.hasDocumentation
    $Result.codeQuality.usesModernFeatures
  )

  return ($checks | Where-Object { $_ -eq $true }).Count
}

function Get-StrategyScore {
  param(
    [Parameter(Mandatory)]
    [object]$Result
  )

  if ($Result.strategyAlignment -and $null -ne $Result.strategyAlignment.overallScore) {
    return [int]$Result.strategyAlignment.overallScore
  }

  return 0
}

function Get-Statistics {
  param(
    [Parameter(Mandatory)]
    [object[]]$Results
  )

  return @{
    TotalTests      = $Results.Count
    FreeModels      = ($Results | Where-Object { $_.category -eq 'free' }).Count
    CheapModels     = ($Results | Where-Object { $_.category -eq 'cheap' }).Count
    StandardModels  = ($Results | Where-Object { $_.category -eq 'standard' }).Count
    AverageDuration = ($Results | Measure-Object -Property durationSeconds -Average).Average
    AverageStrategy = (@($Results | ForEach-Object { Get-StrategyScore -Result $_ }) | Measure-Object -Average).Average
    FastestModel    = ($Results | Sort-Object durationSeconds | Select-Object -First 1)
    SlowestModel    = ($Results | Sort-Object durationSeconds -Descending | Select-Object -First 1)
    TotalCost       = ($Results | Where-Object { $_.totalCost } | Measure-Object -Property totalCost -Sum).Sum
  }
}

function Get-MarkdownHeader {
  param(
    [Parameter(Mandatory)]
    [object]$Metadata,

    [Parameter(Mandatory)]
    [hashtable]$Stats
  )

  $sessionLabel = if ($Metadata.PromptTimestamp) { $Metadata.PromptTimestamp } elseif ($Metadata.Timestamp) { $Metadata.Timestamp } elseif ($Metadata.RunTimestamp) { $Metadata.RunTimestamp } else { 'N/A' }
  $promptLabel = if ($Metadata.PromptId) { $Metadata.PromptId } else { 'N/A' }

  return @"
# LLM Comparison Report

**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Session**: $sessionLabel  
**Test Prompt**: $promptLabel

---

## Executive Summary

- **Total Models Tested**: $($Stats.TotalTests)
- **Free Models**: $($Stats.FreeModels)
- **Cheap Models**: $($Stats.CheapModels)
- **Standard Models**: $($Stats.StandardModels)
- **Average Response Time**: $([math]::Round($Stats.AverageDuration, 2))s
- **Average Strategy Score**: $([math]::Round($Stats.AverageStrategy, 2))/5
- **Total Cost (Paid Models)**: `$$([math]::Round($Stats.TotalCost, 4))

### Performance Leaders

- **⚡ Fastest**: $($Stats.FastestModel.llmName) ($($Stats.FastestModel.durationSeconds)s)
- **🐌 Slowest**: $($Stats.SlowestModel.llmName) ($($Stats.SlowestModel.durationSeconds)s)

---

## Detailed Results (All Categories Joined)
"@
}

function Get-MarkdownJoinedResultsSection {
  param(
    [Parameter(Mandatory)]
    [object[]]$SortedResults
  )

  $text = @"

| Rank | Category | Model | Duration | Cost | Completeness | Quality Score | Notes |
|------|----------|-------|----------|------|--------------|---------------|-------|

"@

  $rank = 1
  foreach ($result in $SortedResults) {
    $cost = if ($result.totalCost) { "`$$($result.totalCost)" } else { 'Free' }
    $completeness = if ($result.responseCompleteness) { $result.responseCompleteness } else { 'N/A' }
    $qualityScore = Get-QualityScore -Result $result
    $notes = if ($result.observations) { $result.observations.Substring(0, [Math]::Min(50, $result.observations.Length)) } else { '' }
    $text += "| $rank | $($result.category) | $($result.llmName) | $($result.durationSeconds)s | $cost | $completeness | $qualityScore/5 | $notes |`n"
    $rank++
  }

  return $text
}

function Get-MarkdownQualitySection {
  param(
    [Parameter(Mandatory)]
    [object[]]$SortedResults
  )

  $text = @"

---

## Code Quality Analysis

| Model | Compilable | Best Practices | Error Handling | Documentation | Modern Features | Overall |
|-------|------------|----------------|----------------|---------------|-----------------|---------|

"@

  foreach ($result in $SortedResults) {
    if (-not $result.codeQuality) {
      continue
    }

    $cq = $result.codeQuality
    $compilable = if ($cq.compilable) { '✅' } else { '❌' }
    $bestPractices = if ($cq.followsBestPractices) { '✅' } else { '❌' }
    $errorHandling = if ($cq.hasProperErrorHandling) { '✅' } else { '❌' }
    $documentation = if ($cq.hasDocumentation) { '✅' } else { '❌' }
    $modernFeatures = if ($cq.usesModernFeatures) { '✅' } else { '❌' }
    $score = Get-QualityScore -Result $result

    $text += "| $($result.llmName) | $compilable | $bestPractices | $errorHandling | $documentation | $modernFeatures | $score/5 |`n"
  }

  return $text
}

function Get-MarkdownStrategySection {
  param(
    [Parameter(Mandatory)]
    [object[]]$SortedResults
  )

  $text = @"

---

## Strategy Alignment Analysis

| Model | Spec Artifacts | Expected Structure | MartiX Reuse | Plan→Implementation | Skills/Agents | Overall |
|-------|----------------|--------------------|--------------|---------------------|---------------|---------|

"@

  foreach ($result in $SortedResults) {
    if (-not $result.strategyAlignment) {
      continue
    }

    $sa = $result.strategyAlignment
    $specArtifacts = if ($sa.hasSpecArtifacts) { '✅' } else { '❌' }
    $structure = if ($sa.followsExpectedStructure) { '✅' } else { '❌' }
    $martixReuse = if ($sa.reusesMartixPatterns) { '✅' } else { '❌' }
    $continuity = if ($sa.planningImplementationContinuity) { '✅' } else { '❌' }
    $skillsAgents = if ($sa.referencesSkillsOrAgents) { '✅' } else { '❌' }
    $score = Get-StrategyScore -Result $result

    $text += "| $($result.llmName) | $specArtifacts | $structure | $martixReuse | $continuity | $skillsAgents | $score/5 |`n"
  }

  return $text
}

function Get-MarkdownPerformanceSections {
  param(
    [Parameter(Mandatory)]
    [object[]]$SortedResults
  )

  $text = @"

---

## Performance vs Cost Analysis

### Free Models Performance

| Model | Duration (s) | Quality | Value Rating |
|-------|--------------|---------|--------------|

"@

  $freeModels = @($SortedResults | Where-Object { $_.category -eq 'free' })
  foreach ($model in $freeModels) {
    $quality = if ($model.codeQuality) { "$(Get-QualityScore -Result $model)/5" } else { 'N/A' }

    $valueRating = if ($model.durationSeconds -lt 10) { '⭐⭐⭐⭐⭐' }
    elseif ($model.durationSeconds -lt 20) { '⭐⭐⭐⭐' }
    elseif ($model.durationSeconds -lt 30) { '⭐⭐⭐' }
    else { '⭐⭐' }

    $text += "| $($model.llmName) | $($model.durationSeconds) | $quality | $valueRating |`n"
  }

  $text += @"

### Cheap Models Performance (Cost vs Quality)

| Model | Duration (s) | Cost | Quality | Cost Efficiency |
|-------|--------------|------|---------|-----------------|

"@

  $cheapModels = @($SortedResults | Where-Object { $_.category -eq 'cheap' })
  foreach ($model in $cheapModels) {
    $quality = if ($model.codeQuality) { "$(Get-QualityScore -Result $model)/5" } else { 'N/A' }
    $cost = if ($model.totalCost) { "`$$($model.totalCost)" } else { '$0' }
    $efficiency = if ($model.totalCost -and $model.totalCost -gt 0) {
      [math]::Round((Get-QualityScore -Result $model) / $model.totalCost, 2)
    }
    else {
      'N/A'
    }

    $text += "| $($model.llmName) | $($model.durationSeconds) | $cost | $quality | $efficiency |`n"
  }

  return @{
    Text        = $text
    FreeModels  = $freeModels
    CheapModels = $cheapModels
  }
}

function Get-MarkdownRecommendations {
  param(
    [Parameter(Mandatory)]
    [object[]]$SortedResults,

    [Parameter()]
    [object[]]$FreeModels,

    [Parameter()]
    [object[]]$CheapModels
  )

  $text = @"

---

## Recommendations

### Best Free Model
"@

  $bestFree = $FreeModels | Sort-Object -Property durationSeconds | Select-Object -First 1
  if ($bestFree) {
    $text += "`n**$($bestFree.llmName)** - Fastest response time at $($bestFree.durationSeconds)s with no cost.`n"
  }

  $text += @"

### Best Value Cheap Model
"@

  $bestCheap = $CheapModels | Sort-Object -Property {
    if ($_.totalCost -and $_.totalCost -gt 0 -and $_.codeQuality) {
      - ((Get-QualityScore -Result $_) / $_.totalCost)
    }
    else {
      0
    }
  } | Select-Object -First 1

  if ($bestCheap) {
    $text += "`n**$($bestCheap.llmName)** - Best quality-to-cost ratio at `$$($bestCheap.totalCost) per request.`n"
  }

  $text += @"

### Overall Winner
"@

  $winner = $SortedResults | Sort-Object -Property { - (Get-QualityScore -Result $_) } | Select-Object -First 1
  if ($winner) {
    $costText = if ($winner.totalCost) { "at `$$($winner.totalCost) per request" } else { 'with no cost' }
    $text += "`n**$($winner.llmName)** - Highest code quality score $costText.`n"
  }

  $text += @"

---

## Next Steps

1. **Review Generated Code** - Examine the code in each model's directory
2. **Run Compilation Tests** - Verify all code compiles successfully
3. **Run Unit Tests** - If available, test functionality
4. **Update Configuration** - Enable/disable models based on results
5. **Rerun Tests** - Test with different prompts for comprehensive evaluation

---

*Report generated by LLM Comparison Framework v1.0*
"@

  return $text
}

function New-MarkdownReport {
  param(
    [Parameter(Mandatory)]
    [string]$ReportsPath,

    [Parameter(Mandatory)]
    [object]$Metadata,

    [Parameter(Mandatory)]
    [hashtable]$Stats,

    [Parameter(Mandatory)]
    [object[]]$SortedResults
  )

  Write-Host 'Generating Markdown report...' -ForegroundColor Cyan

  $content = Get-MarkdownHeader -Metadata $Metadata -Stats $Stats
  $content += Get-MarkdownJoinedResultsSection -SortedResults $SortedResults
  $content += Get-MarkdownQualitySection -SortedResults $SortedResults
  $content += Get-MarkdownStrategySection -SortedResults $SortedResults

  $performanceSections = Get-MarkdownPerformanceSections -SortedResults $SortedResults
  $content += $performanceSections.Text
  $content += Get-MarkdownRecommendations -SortedResults $SortedResults -FreeModels $performanceSections.FreeModels -CheapModels $performanceSections.CheapModels

  $mdReportPath = Join-Path $ReportsPath 'comparison-report.md'
  Set-TextContent -Path $mdReportPath -Value $content
  Write-Host "  ✓ Markdown report saved: $mdReportPath" -ForegroundColor Green

  return $mdReportPath
}

function New-JsonReport {
  param(
    [Parameter(Mandatory)]
    [string]$ReportsPath,

    [Parameter(Mandatory)]
    [object]$Metadata,

    [Parameter(Mandatory)]
    [hashtable]$Stats,

    [Parameter(Mandatory)]
    [object[]]$SortedResults
  )

  Write-Host 'Generating JSON report...' -ForegroundColor Cyan

  $jsonReport = @{
    Metadata    = $Metadata
    Statistics  = $Stats
    Results     = $SortedResults
    GeneratedAt = Get-Date -Format 'o'
  }

  $jsonReportPath = Join-Path $ReportsPath 'comparison-report.json'
  Set-JsonContent -Path $jsonReportPath -Value $jsonReport
  Write-Host "  ✓ JSON report saved: $jsonReportPath" -ForegroundColor Green
}

function New-HtmlReport {
  param(
    [Parameter(Mandatory)]
    [string]$ReportsPath,

    [Parameter(Mandatory)]
    [object]$Metadata,

    [Parameter(Mandatory)]
    [hashtable]$Stats,

    [Parameter(Mandatory)]
    [string]$MarkdownReportPath
  )

  Write-Host 'Generating HTML report...' -ForegroundColor Cyan

  if ((-not (Test-Path $MarkdownReportPath)) -and (-not $WhatIfPreference)) {
    return
  }

  $htmlReport = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>LLM Comparison Report</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }
        h2 { color: #34495e; margin-top: 30px; border-bottom: 2px solid #ecf0f1; padding-bottom: 8px; }
        h3 { color: #7f8c8d; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th { background: #3498db; color: white; padding: 12px; text-align: left; }
        td { padding: 10px; border-bottom: 1px solid #ecf0f1; }
        tr:hover { background: #f8f9fa; }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0; }
        .stat-card { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 8px; }
        .stat-card h3 { color: white; margin: 0; font-size: 14px; }
        .stat-card p { font-size: 28px; font-weight: bold; margin: 10px 0 0 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 LLM Comparison Report</h1>
        <p><strong>Generated:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        <p><strong>Test Prompt:</strong> $($Metadata.PromptId)</p>
        
        <div class="stats">
            <div class="stat-card">
                <h3>Total Models</h3>
                <p>$($Stats.TotalTests)</p>
            </div>
            <div class="stat-card" style="background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);">
                <h3>Avg Response Time</h3>
                <p>$([math]::Round($Stats.AverageDuration, 1))s</p>
            </div>
            <div class="stat-card" style="background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);">
                <h3>Total Cost</h3>
                <p>`$$([math]::Round($Stats.TotalCost, 4))</p>
            </div>
        </div>
        
        <p>For detailed analysis, please see the Markdown report.</p>
    </div>
</body>
</html>
"@

  $htmlReportPath = Join-Path $ReportsPath 'comparison-report.html'
  Set-TextContent -Path $htmlReportPath -Value $htmlReport
  Write-Host "  ✓ HTML report saved: $htmlReportPath" -ForegroundColor Green
}

function Show-Summary {
  param(
    [Parameter(Mandatory)]
    [string]$ReportsPath,

    [Parameter(Mandatory)]
    [string]$OutputFormat
  )

  Write-Host "`n========================================" -ForegroundColor Magenta
  Write-Host '  Analysis Complete!' -ForegroundColor Magenta
  Write-Host '========================================' -ForegroundColor Magenta
  Write-Host "`nReports generated in: $ReportsPath" -ForegroundColor Yellow
  Write-Host ''
  Write-Host 'View reports:' -ForegroundColor Cyan

  $mdPath = Join-Path $ReportsPath 'comparison-report.md'
  $htmlPath = Join-Path $ReportsPath 'comparison-report.html'
  $jsonPath = Join-Path $ReportsPath 'comparison-report.json'

  if (($OutputFormat -in @('markdown', 'all')) -and ((Test-Path $mdPath) -or $WhatIfPreference)) {
    $mdSuffix = if ($WhatIfPreference -and -not (Test-Path $mdPath)) { ' (WhatIf)' } else { '' }
    Write-Host "  Markdown: $mdPath$mdSuffix" -ForegroundColor White
  }
  if (($OutputFormat -in @('html', 'all')) -and ((Test-Path $htmlPath) -or $WhatIfPreference)) {
    $htmlSuffix = if ($WhatIfPreference -and -not (Test-Path $htmlPath)) { ' (WhatIf)' } else { '' }
    Write-Host "  HTML: $htmlPath$htmlSuffix" -ForegroundColor White
  }
  if (($OutputFormat -in @('json', 'all')) -and ((Test-Path $jsonPath) -or $WhatIfPreference)) {
    $jsonSuffix = if ($WhatIfPreference -and -not (Test-Path $jsonPath)) { ' (WhatIf)' } else { '' }
    Write-Host "  JSON: $jsonPath$jsonSuffix" -ForegroundColor White
  }

  Write-Host ''
}

Assert-SessionPath

Write-Host 'Analyzing LLM Test Results' -ForegroundColor Cyan
Write-Host "Session: $SessionPath" -ForegroundColor Yellow
Write-Host ''

$metadata = Get-SessionMetadata
Write-Host "Prompt: $($metadata.PromptId)" -ForegroundColor Green
Write-Host "Timestamp: $($metadata.Timestamp)" -ForegroundColor Green
Write-Host ''

$results = Get-TestResults
if ($results.Count -eq 0) {
  Write-Warning 'No results found in session'
  exit 1
}

Write-Host "Found $($results.Count) test results" -ForegroundColor Green
Write-Host ''

$reportsPath = New-ReportsDirectory
$sortedResults = $results | Sort-Object -Property durationSeconds, category
$stats = Get-Statistics -Results $results

$markdownPath = Join-Path $reportsPath 'comparison-report.md'
if ($OutputFormat -in @('markdown', 'all')) {
  $markdownPath = New-MarkdownReport -ReportsPath $reportsPath -Metadata $metadata -Stats $stats -SortedResults $sortedResults
}

if ($OutputFormat -in @('json', 'all')) {
  New-JsonReport -ReportsPath $reportsPath -Metadata $metadata -Stats $stats -SortedResults $sortedResults
}

if ($OutputFormat -in @('html', 'all')) {
  New-HtmlReport -ReportsPath $reportsPath -Metadata $metadata -Stats $stats -MarkdownReportPath $markdownPath
}

Show-Summary -ReportsPath $reportsPath -OutputFormat $OutputFormat
