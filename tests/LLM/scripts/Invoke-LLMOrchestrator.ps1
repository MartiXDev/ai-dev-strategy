<#
.SYNOPSIS
    Orchestrates LLM testing using a single CLI instance loop (Copilot CLI or Codex CLI).

.DESCRIPTION
    This script automates LLM testing by running one CLI test at a time in loop-based
    orchestration, eliminating the need for manual switching between models. It supports both
    GitHub Copilot CLI and Codex CLI.

.PARAMETER TestPromptId
    ID of the test prompt to use (e.g., "01-crud-api-with-validation").
    When omitted, ALL prompts in the prompts/ directory are run sequentially.

.PARAMETER LLMCategory
    Category of LLMs to test: "free", "cheap", "standard", or "all"

.PARAMETER SpecificModels
    Array of specific model IDs to test (overrides LLMCategory)

.PARAMETER ReasoningModes
    Optional reasoning modes to benchmark for supported models. Accepted values are
    "low", "medium", "high", and "extra-high". When omitted, supported models expand to the
    configured benchmarkReasoningModes from llm-config.json. Copilot runs still keep
    reasoningModeApplied = false because current automation does not document a non-interactive
    reasoning-effort override.

.PARAMETER MaxParallel
    Maximum number of concurrent model tests (default: 8, max: 16).

.PARAMETER ShowCLIProgress
    When set, each model run shows live CLI output in visible windows.
    Default mode is passive (no CLI windows shown).

.PARAMETER CLIType
    Type of CLI to use: "copilot" or "codex" (default: "copilot")

.PARAMETER CopilotAgent
  Copilot chat agent name used with `--agent` when CLIType is "copilot".
  Set an empty value to omit `--agent`.

.PARAMETER OutputFormat
    Output format for results: "markdown", "json", or "all" (default: "all")

.PARAMETER RequirementPacks
    Optional requirement-pack markdown files to append to each model prompt contract.
    If omitted, all markdown files in tests/LLM/requirements are applied automatically.

.PARAMETER BenchmarkProfile
    Strategy benchmark profile to run (e.g., "baseline", "overnight-spec-driven").

.EXAMPLE
    .\Invoke-LLMOrchestrator.ps1 -LLMCategory "all"
    Runs ALL prompts against all enabled models.

.EXAMPLE
    .\Invoke-LLMOrchestrator.ps1 -TestPromptId "01-crud-api-with-validation" -LLMCategory "all"

.EXAMPLE
    .\Invoke-LLMOrchestrator.ps1 -SpecificModels @("gpt-4.1", "claude-haiku-4.5") -MaxParallel 2

.EXAMPLE
    .\Invoke-LLMOrchestrator.ps1 -SpecificModels @("gpt-5.4") -CLIType "codex" -ReasoningModes @("low", "high")

.EXAMPLE
    .\Invoke-LLMOrchestrator.ps1 -LLMCategory "cheap" -CLIType "codex"

.EXAMPLE
    .\Invoke-LLMOrchestrator.ps1 -LLMCategory "all" -ShowCLIProgress
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [Parameter(Mandatory = $false)]
  [string]$TestPromptId,

  [Parameter(Mandatory = $false)]
  [ValidateSet("free", "cheap", "standard", "all")]
  [string]$LLMCategory = "all",

  [Parameter(Mandatory = $false)]
  [string[]]$SpecificModels,

  [Parameter(Mandatory = $false)]
  [ValidateSet("low", "medium", "high", "extra-high")]
  [string[]]$ReasoningModes = @(),

  [Parameter(Mandatory = $false)]
  [ValidateRange(1, 16)]
  [int]$MaxParallel = 8,

  [Parameter(Mandatory = $false)]
  [ValidateSet("copilot", "codex")]
  [string]$CLIType = "copilot",

  [Parameter(Mandatory = $false)]
  [AllowEmptyString()]
  [string]$CopilotAgent = 'C# Expert',

  [Parameter(Mandatory = $false)]
  [ValidateSet("markdown", "json", "all")]
  [string]$OutputFormat = "all",

  [Parameter(Mandatory = $false)]
  [string[]]$RequirementPacks = @(),

  [Parameter(Mandatory = $false)]
  [string]$BenchmarkProfile = 'baseline',

  [Parameter(Mandatory = $false)]
  [switch]$ShowCLIProgress
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

function Copy-FileSafe {
  [CmdletBinding(SupportsShouldProcess = $true)]
  param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory)]
    [string]$Destination
  )

  if ($PSCmdlet.ShouldProcess($Destination, "Copy file from $Path")) {
    Copy-Item -Path $Path -Destination $Destination -Force
  }
}

function Format-DurationText {
  param(
    [Parameter(Mandatory)]
    [timespan]$Duration
  )

  $totalSeconds = [int][Math]::Max(0, [Math]::Round($Duration.TotalSeconds))
  $normalized = [timespan]::FromSeconds($totalSeconds)
  if ($normalized.TotalHours -ge 1) {
    return $normalized.ToString('hh\:mm\:ss')
  }

  return $normalized.ToString('mm\:ss')
}

function Resolve-CopilotAgentName {
  param(
    [Parameter()]
    [string]$Agent
  )

  if ([string]::IsNullOrWhiteSpace($Agent)) {
    return ''
  }

  $normalized = $Agent.Trim()
  $normalized = $normalized -replace '#', 'Sharp'
  $normalized = $normalized -replace '[^A-Za-z0-9_-]', ''

  return $normalized
}

function Get-EstimatedRemaining {
  param(
    [Parameter(Mandatory)]
    [datetime]$StartTime,

    [Parameter(Mandatory)]
    [int]$Completed,

    [Parameter(Mandatory)]
    [int]$Total
  )

  if ($Completed -le 0 -or $Total -le $Completed) {
    return [timespan]::Zero
  }

  $elapsed = (Get-Date) - $StartTime
  $elapsedSeconds = [Math]::Max($elapsed.TotalSeconds, 1)
  $ratePerSecond = $Completed / $elapsedSeconds
  if ($ratePerSecond -le 0) {
    return [timespan]::Zero
  }

  $remainingCount = $Total - $Completed
  $remainingSeconds = $remainingCount / $ratePerSecond
  return [timespan]::FromSeconds([Math]::Max(0, $remainingSeconds))
}

function Get-LiveSessionStatus {
  param(
    [Parameter(Mandatory)]
    [string]$ModelName,

    [Parameter(Mandatory)]
    [string]$OutputDir,

    [Parameter(Mandatory)]
    [datetime]$StartedAt
  )

  $statusPath = Join-Path $OutputDir 'logs\instance-status.json'
  $state = 'starting'
  $attempt = 0
  $cliPid = 0
  $message = 'Waiting for status file...'
  $reasoningMode = ''
  $reasoningModeApplied = $true

  if (Test-Path $statusPath) {
    try {
      $status = Get-Content -Path $statusPath -Raw | ConvertFrom-Json
      if ($status.state) { $state = [string]$status.state }
      if ($status.attempt) { $attempt = [int]$status.attempt }
      if ($status.cliProcessId) { $cliPid = [int]$status.cliProcessId }
      if ($status.message) { $message = [string]$status.message }
      if ($status.PSObject.Properties['reasoningMode'] -and $status.reasoningMode) { $reasoningMode = [string]$status.reasoningMode }
      if ($status.PSObject.Properties['reasoningModeApplied']) { $reasoningModeApplied = [bool]$status.reasoningModeApplied }
    }
    catch {
      $message = "Status parse error: $($_.Exception.Message)"
    }
  }

  if (-not [string]::IsNullOrWhiteSpace($reasoningMode) -and -not $reasoningModeApplied) {
    $message = "reasoning=$reasoningMode (recorded-only) | $message"
  }

  if ($message.Length -gt 90) {
    $message = $message.Substring(0, 90) + '...'
  }

  return [PSCustomObject]@{
    ModelName = $ModelName
    State     = $state
    Attempt   = $attempt
    Pid       = $cliPid
    Elapsed   = Format-DurationText -Duration ((Get-Date) - $StartedAt)
    Message   = $message
  }
}

function Get-LiveSessionProgressDetails {
  param(
    [Parameter(Mandatory)]
    [object[]]$RunningJobs,

    [Parameter(Mandatory)]
    [hashtable]$JobMetadata,

    [Parameter()]
    [ValidateRange(1, 5)]
    [int]$MaxItems = 2
  )

  if ($RunningJobs.Count -eq 0) {
    return 'No active sessions'
  }

  $details = [System.Collections.Generic.List[string]]::new()
  foreach ($job in ($RunningJobs | Sort-Object Name)) {
    if (-not $JobMetadata.ContainsKey($job.Id)) {
      continue
    }

    $meta = $JobMetadata[$job.Id]
    $status = Get-LiveSessionStatus -ModelName $meta.ModelName -OutputDir $meta.OutputDir -StartedAt $meta.StartedAt
    $details.Add(("{0}:{1} a{2} pid={3} t={4} {5}" -f $status.ModelName, $status.State, $status.Attempt, $status.Pid, $status.Elapsed, $status.Message))
    if ($details.Count -ge $MaxItems) {
      break
    }
  }

  if ($details.Count -eq 0) {
    return 'Waiting for status updates...'
  }

  $remaining = [Math]::Max(0, $RunningJobs.Count - $details.Count)
  if ($remaining -gt 0) {
    return ('{0} (+{1} more)' -f ($details -join ' | '), $remaining)
  }

  return ($details -join ' | ')
}

function Initialize-OrchestratorPaths {
  $scriptDir = $PSScriptRoot
  $testRoot = Split-Path $scriptDir -Parent
  $resultsDir = Join-Path $testRoot 'results'

  New-DirectoryIfMissing -Path $resultsDir

  return [PSCustomObject]@{
    ScriptDir            = $scriptDir
    TestRoot             = $testRoot
    ConfigPath           = Join-Path $testRoot 'llm-config.json'
    CliConfigPath        = Join-Path $testRoot 'cli-config.json'
    StrategyProfilesPath = Join-Path $testRoot 'strategy-profiles.json'
    ExternalAssetsPath   = Join-Path $testRoot 'external-assets.json'
    PromptsDir           = Join-Path $testRoot 'prompts'
    RequirementsDir      = Join-Path $testRoot 'requirements'
    ResultsDir           = $resultsDir
    HelperScript         = Join-Path $scriptDir 'Invoke-CLITest.ps1'
    AnalysisScript       = Join-Path $scriptDir 'Invoke-LLMAnalysis.ps1'
  }
}

function Get-StrategyProfiles {
  param(
    [Parameter(Mandatory)]
    [string]$StrategyProfilesPath
  )

  if (-not (Test-Path $StrategyProfilesPath)) {
    return [PSCustomObject]@{
      profiles = [PSCustomObject]@{
        baseline = [PSCustomObject]@{
          name             = 'Baseline'
          description      = 'Default benchmark profile with standard requirement packs.'
          requirementPacks = @()
        }
      }
    }
  }

  return Get-Content -Path $StrategyProfilesPath -Raw | ConvertFrom-Json
}

function Get-BenchmarkProfileConfig {
  param(
    [Parameter(Mandatory)]
    [object]$StrategyProfiles,

    [Parameter(Mandatory)]
    [string]$ProfileId
  )

  if (-not $StrategyProfiles.profiles) {
    throw 'Invalid strategy profiles file: missing "profiles" object.'
  }

  $benchmarkProfileConfig = $StrategyProfiles.profiles.$ProfileId
  if ($null -eq $benchmarkProfileConfig) {
    $available = @($StrategyProfiles.profiles.PSObject.Properties.Name) -join ', '
    throw "Unknown benchmark profile '$ProfileId'. Available profiles: $available"
  }

  return $benchmarkProfileConfig
}

function Get-ExternalAssetsCatalog {
  param(
    [Parameter(Mandatory)]
    [string]$CatalogPath
  )

  if (-not (Test-Path $CatalogPath)) {
    return [PSCustomObject]@{
      assets = @()
    }
  }

  return Get-Content -Path $CatalogPath -Raw | ConvertFrom-Json
}

function Get-RequirementPackPaths {
  param(
    [Parameter(Mandatory)]
    [string]$RequirementsDir,

    [Parameter(Mandatory)]
    [string]$TestRoot,

    [Parameter()]
    [object[]]$ProfileRequirementPacks = @(),

    [Parameter()]
    [string[]]$ExplicitPacks = @()
  )

  $requestedPacks = [System.Collections.Generic.List[string]]::new()
  foreach ($pack in @($ProfileRequirementPacks)) {
    if (-not [string]::IsNullOrWhiteSpace([string]$pack)) {
      $requestedPacks.Add([string]$pack)
    }
  }
  foreach ($pack in @($ExplicitPacks)) {
    if (-not [string]::IsNullOrWhiteSpace([string]$pack)) {
      $requestedPacks.Add([string]$pack)
    }
  }

  if ($requestedPacks.Count -eq 0) {
    if (-not (Test-Path $RequirementsDir)) {
      return @()
    }

    return @(
      Get-ChildItem -Path $RequirementsDir -File -Filter '*.md' |
      Sort-Object Name |
      Select-Object -ExpandProperty FullName
    )
  }

  $resolved = [System.Collections.Generic.List[string]]::new()
  $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

  foreach ($pack in $requestedPacks) {
    $candidate = $pack
    if (-not [System.IO.Path]::IsPathRooted($candidate)) {
      $candidateFromRoot = Join-Path $TestRoot $pack
      $candidateFromRequirements = Join-Path $RequirementsDir $pack
      $candidateFromRequirementsName = Join-Path $RequirementsDir ([System.IO.Path]::GetFileName($pack))

      if (Test-Path $candidateFromRoot) {
        $candidate = $candidateFromRoot
      }
      elseif (Test-Path $candidateFromRequirements) {
        $candidate = $candidateFromRequirements
      }
      elseif (Test-Path $candidateFromRequirementsName) {
        $candidate = $candidateFromRequirementsName
      }
    }

    if (-not (Test-Path $candidate)) {
      throw "Requirement pack not found: $pack"
    }

    $fullPath = (Get-Item -Path $candidate).FullName
    if ($seen.Add($fullPath)) {
      $resolved.Add($fullPath)
    }
  }

  return @($resolved)
}

function Get-ResultQualityScore {
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

function Get-ResultStrategyScore {
  param(
    [Parameter(Mandatory)]
    [object]$Result
  )

  if ($Result.strategyAlignment -and $null -ne $Result.strategyAlignment.overallScore) {
    return [int]$Result.strategyAlignment.overallScore
  }

  return 0
}

function Get-RunAggregatedData {
  param(
    [Parameter(Mandatory)]
    [string]$RunDir,

    [Parameter(Mandatory)]
    [object[]]$PromptFiles
  )

  $entries = [System.Collections.Generic.List[object]]::new()
  $promptStats = [System.Collections.Generic.List[object]]::new()

  foreach ($promptFile in $PromptFiles) {
    $promptId = $promptFile.BaseName
    $sessionDir = Join-Path $RunDir $promptId
    $sessionMetadataPath = Join-Path $sessionDir 'session-metadata.json'
    $resultsPath = Join-Path $sessionDir 'all-results.json'

    $expectedModels = 0
    if (Test-Path $sessionMetadataPath) {
      try {
        $sessionMetadata = Get-Content -Path $sessionMetadataPath -Raw | ConvertFrom-Json
        if ($sessionMetadata.ModelsCount) {
          $expectedModels = [int]$sessionMetadata.ModelsCount
        }
      }
      catch {
        Write-Warning "Could not parse session metadata for $($promptId): $($_.Exception.Message)"
      }
    }

    $promptResults = @()
    if (Test-Path $resultsPath) {
      $promptResults = Get-Content -Path $resultsPath -Raw | ConvertFrom-Json
      if ($promptResults -isnot [System.Array]) {
        $promptResults = @($promptResults)
      }
    }

    foreach ($entry in @($promptResults)) {
      if ($entry.PSObject.Properties.Name -contains 'testPromptId') {
        if ([string]::IsNullOrWhiteSpace($entry.testPromptId)) {
          $entry.testPromptId = $promptId
        }
      }
      else {
        $entry | Add-Member -NotePropertyName testPromptId -NotePropertyValue $promptId
      }

      $entries.Add($entry)
    }

    $capturedResults = @($promptResults).Count
    $promptStats.Add([PSCustomObject]@{
        PromptId          = $promptId
        ExpectedModels    = $expectedModels
        CapturedResults   = $capturedResults
        CompletionPercent = if ($expectedModels -gt 0) { [math]::Round(($capturedResults / $expectedModels) * 100, 1) } else { 0 }
      })
  }

  return [PSCustomObject]@{
    Entries     = @($entries)
    PromptStats = @($promptStats)
  }
}

function Get-ProfileComparisonRows {
  param(
    [Parameter(Mandatory)]
    [string]$ResultsDir,

    [Parameter(Mandatory)]
    [string]$CurrentRunTimestamp,

    [Parameter(Mandatory)]
    [string]$CurrentBenchmarkProfile
  )

  if (-not (Test-Path $ResultsDir)) {
    return @()
  }

  $rows = [System.Collections.Generic.List[object]]::new()
  $runDirs = Get-ChildItem -Path $ResultsDir -Directory | Sort-Object Name -Descending
  foreach ($runDir in $runDirs) {
    if ($runDir.Name -eq $CurrentRunTimestamp) {
      continue
    }

    $summaryPath = Join-Path $runDir.FullName 'run-summary.json'
    if (-not (Test-Path $summaryPath)) {
      continue
    }

    try {
      $summary = Get-Content -Path $summaryPath -Raw | ConvertFrom-Json
      if (-not $summary.BenchmarkProfile -or $summary.BenchmarkProfile -eq $CurrentBenchmarkProfile) {
        continue
      }

      $rows.Add([PSCustomObject]@{
          BenchmarkProfile = [string]$summary.BenchmarkProfile
          RunTimestamp     = [string]$summary.RunTimestamp
          AverageQuality   = [double]$summary.GlobalTotals.AverageQuality
          AverageStrategy  = [double]$summary.GlobalTotals.AverageStrategy
          AverageDuration  = [double]$summary.GlobalTotals.AverageDuration
          TotalCost        = [double]$summary.GlobalTotals.TotalCost
          CompletionRate   = [double]$summary.GlobalTotals.CompletionRate
        })
    }
    catch {
      Write-Warning "Skipping invalid run summary: $summaryPath"
    }
  }

  return @($rows | Group-Object -Property BenchmarkProfile | ForEach-Object { $_.Group | Sort-Object RunTimestamp -Descending | Select-Object -First 1 })
}

function New-RunSummaryReport {
  param(
    [Parameter(Mandatory)]
    [string]$RunDir,

    [Parameter(Mandatory)]
    [string]$RunTimestamp,

    [Parameter(Mandatory)]
    [object[]]$PromptFiles,

    [Parameter(Mandatory)]
    [string]$CLIType,

    [Parameter()]
    [string]$CopilotAgent,

    [Parameter(Mandatory)]
    [string]$BenchmarkProfile,

    [Parameter()]
    [object]$StrategyProfile,

    [Parameter()]
    [object]$ExternalAssetsCatalog,

    [Parameter()]
    [string[]]$RequirementPackPaths = @()
  )

  $aggregated = Get-RunAggregatedData -RunDir $RunDir -PromptFiles $PromptFiles
  $entries = @($aggregated.Entries)
  $promptStats = @($aggregated.PromptStats | Sort-Object PromptId)
  $totalPrompts = [Math]::Max($PromptFiles.Count, 1)

  $modelRows = @()
  foreach ($group in ($entries | Group-Object -Property llmModel)) {
    if ([string]::IsNullOrWhiteSpace($group.Name)) {
      continue
    }

    $first = $group.Group | Select-Object -First 1
    $qualityScores = @($group.Group | ForEach-Object { Get-ResultQualityScore -Result $_ })
    $strategyScores = @($group.Group | ForEach-Object { Get-ResultStrategyScore -Result $_ })
    $coverageCount = @($group.Group | ForEach-Object { $_.testPromptId } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique).Count
    $completeCount = @($group.Group | Where-Object { $_.responseCompleteness -eq 'complete' }).Count
    $durationAverage = ($group.Group | Measure-Object -Property durationSeconds -Average).Average
    $costSum = ($group.Group | Where-Object { $null -ne $_.totalCost } | Measure-Object -Property totalCost -Sum).Sum
    $qualityAverage = ($qualityScores | Measure-Object -Average).Average
    $strategyAverage = ($strategyScores | Measure-Object -Average).Average

    $modelRows += [PSCustomObject]@{
      ModelName        = $first.llmName
      ModelId          = $group.Name
      BaseModelName    = if ($first.PSObject.Properties['baseModelName']) { $first.baseModelName } else { $first.llmName }
      ReasoningMode    = if ($first.PSObject.Properties['reasoningMode']) { $first.reasoningMode } else { $null }
      Category         = $first.category
      Runs             = $group.Count
      PromptCoverage   = "$coverageCount/$totalPrompts"
      AvgDuration      = if ($durationAverage) { [math]::Round($durationAverage, 3) } else { 0 }
      AvgQuality       = if ($qualityAverage) { [math]::Round($qualityAverage, 2) } else { 0 }
      AvgStrategy      = if ($strategyAverage) { [math]::Round($strategyAverage, 2) } else { 0 }
      TotalCost        = if ($costSum) { [math]::Round($costSum, 6) } else { 0 }
      CompletenessRate = if ($group.Count -gt 0) { [math]::Round(($completeCount / $group.Count) * 100, 1) } else { 0 }
    }
  }

  $modelSortOrder = @(
    @{ Expression = 'AvgQuality'; Descending = $true }
    @{ Expression = 'AvgStrategy'; Descending = $true }
    @{ Expression = 'AvgDuration'; Descending = $false }
    @{ Expression = 'TotalCost'; Descending = $false }
    @{ Expression = 'ModelName'; Descending = $false }
  )
  $rankedRows = @($modelRows | Sort-Object -Property $modelSortOrder)

  $totalExecutions = $entries.Count
  $completeTotal = @($entries | Where-Object { $_.responseCompleteness -eq 'complete' }).Count
  $partialTotal = @($entries | Where-Object { $_.responseCompleteness -in @('partial', 'truncated') }).Count
  $errorTotal = @($entries | Where-Object { $_.responseCompleteness -in @('failed', 'error') }).Count
  $avgDurationAll = if ($totalExecutions -gt 0) {
    [math]::Round((($entries | Measure-Object -Property durationSeconds -Average).Average), 3)
  }
  else {
    0
  }
  $totalCostAll = if ($totalExecutions -gt 0) {
    [math]::Round((($entries | Where-Object { $null -ne $_.totalCost } | Measure-Object -Property totalCost -Sum).Sum), 6)
  }
  else {
    0
  }
  $avgQualityAll = if ($totalExecutions -gt 0) {
    [math]::Round(((@($entries | ForEach-Object { Get-ResultQualityScore -Result $_ }) | Measure-Object -Average).Average), 2)
  }
  else {
    0
  }
  $avgStrategyAll = if ($totalExecutions -gt 0) {
    [math]::Round(((@($entries | ForEach-Object { Get-ResultStrategyScore -Result $_ }) | Measure-Object -Average).Average), 2)
  }
  else {
    0
  }
  $completionRateAll = if ($totalExecutions -gt 0) {
    [math]::Round(($completeTotal / $totalExecutions) * 100, 1)
  }
  else {
    0
  }

  $profileName = if ($StrategyProfile -and $StrategyProfile.name) { [string]$StrategyProfile.name } else { $BenchmarkProfile }
  $profileDescription = if ($StrategyProfile -and $StrategyProfile.description) { [string]$StrategyProfile.description } else { 'N/A' }
  $effectiveCopilotAgent = if ($CLIType -eq 'copilot') { Resolve-CopilotAgentName -Agent $CopilotAgent } else { '' }
  $profileAssetIds = @()
  if ($StrategyProfile -and $StrategyProfile.externalAssets) {
    $profileAssetIds = @($StrategyProfile.externalAssets | ForEach-Object { [string]$_ })
  }

  $externalAssets = @()
  if ($ExternalAssetsCatalog -and $ExternalAssetsCatalog.assets) {
    $externalAssets = @($ExternalAssetsCatalog.assets)
  }

  $selectedAssets = @()
  if ($profileAssetIds.Count -gt 0 -and $externalAssets.Count -gt 0) {
    $selectedAssets = @($externalAssets | Where-Object { $profileAssetIds -contains [string]$_.id })
  }

  $requirementPackList = if ($RequirementPackPaths.Count -gt 0) {
    (@($RequirementPackPaths | ForEach-Object { "- ``$([System.IO.Path]::GetFileName($_))``" }) -join "`n")
  }
  else {
    '- _No requirement packs applied_'
  }

  $externalAssetList = if ($selectedAssets.Count -gt 0) {
    (@($selectedAssets | ForEach-Object {
        $assetName = if ($_.name) { $_.name } else { $_.id }
        $assetPath = if ($_.path) { $_.path } else { 'N/A' }
        "- ``$assetName`` -> ``$assetPath``"
      }) -join "`n")
  }
  else {
    '- _No external assets mapped for this profile_'
  }

  $content = @"
# LLM Run Summary Report

**Generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  
**Run Timestamp**: $RunTimestamp  
**CLI Type**: $CLIType  
**Copilot Agent**: $(if ($CLIType -eq 'copilot' -and -not [string]::IsNullOrWhiteSpace($effectiveCopilotAgent)) { $effectiveCopilotAgent } else { 'N/A' })  
**Benchmark Profile**: $BenchmarkProfile

## Benchmark Profile Context

- **Profile Name**: $profileName
- **Profile Description**: $profileDescription

### External Assets in Profile
$externalAssetList

## Global Totals (All LLMs + All Prompts)

- **Total Prompts**: $($PromptFiles.Count)
- **Total Benchmark Targets**: $($rankedRows.Count)
- **Total Executions**: $totalExecutions
- **Completed**: $completeTotal
- **Partial/Truncated**: $partialTotal
- **Failed/Error**: $errorTotal
- **Completion Rate**: $completionRateAll%
- **Average Duration**: $avgDurationAll s
- **Average Quality Score**: $avgQualityAll / 5
- **Average Strategy Score**: $avgStrategyAll / 5
- **Total Cost**: `$$totalCostAll

## Requirement Packs Used

$requirementPackList

## Per-Benchmark-Target Totals Across All Prompts

| Rank | Target | Base Model | Reasoning | Category | Prompt Coverage | Runs | Completeness % | Avg Quality | Avg Strategy | Avg Duration (s) | Total Cost |
|------|--------|------------|-----------|----------|-----------------|------|----------------|-------------|--------------|------------------|------------|
"@

  $rank = 1
  foreach ($row in $rankedRows) {
    $reasoningLabel = if ([string]::IsNullOrWhiteSpace($row.ReasoningMode)) { '-' } else { $row.ReasoningMode }
    $content += "| $rank | $($row.ModelName) | $($row.BaseModelName) | $reasoningLabel | $($row.Category) | $($row.PromptCoverage) | $($row.Runs) | $($row.CompletenessRate) | $($row.AvgQuality) | $($row.AvgStrategy) | $($row.AvgDuration) | `$$($row.TotalCost) |`n"
    $rank++
  }

  if ($rankedRows.Count -eq 0) {
    $content += "| - | _No results_ | - | - | - | - | - | - | - | - | - | - |`n"
  }

  $content += @"

## Prompt Coverage Summary

| Prompt | Captured Results | Expected Models | Completion % |
|--------|------------------|-----------------|--------------|
"@

  foreach ($prompt in $promptStats) {
    $content += "| $($prompt.PromptId) | $($prompt.CapturedResults) | $($prompt.ExpectedModels) | $($prompt.CompletionPercent) |`n"
  }

  if ($promptStats.Count -eq 0) {
    $content += "| _No prompts_ | 0 | 0 | 0 |`n"
  }

  $comparisonRows = Get-ProfileComparisonRows -ResultsDir (Split-Path -Path $RunDir -Parent) -CurrentRunTimestamp $RunTimestamp -CurrentBenchmarkProfile $BenchmarkProfile
  $content += @"

## Profile Comparison (Latest Run Per Other Profile)

| Profile | Run Timestamp | Avg Quality | Avg Strategy | Avg Duration (s) | Completion % | Total Cost |
|---------|---------------|-------------|--------------|------------------|--------------|------------|
"@
  foreach ($comparison in $comparisonRows) {
    $content += "| $($comparison.BenchmarkProfile) | $($comparison.RunTimestamp) | $($comparison.AverageQuality) | $($comparison.AverageStrategy) | $($comparison.AverageDuration) | $($comparison.CompletionRate) | `$$($comparison.TotalCost) |`n"
  }
  if ($comparisonRows.Count -eq 0) {
    $content += "| _No comparison runs yet_ | - | - | - | - | - | - |`n"
  }

  $reportPath = Join-Path $RunDir 'run-summary.md'
  Set-TextContent -Path $reportPath -Value $content

  $summaryPayload = [ordered]@{
    RunTimestamp     = $RunTimestamp
    BenchmarkProfile = $BenchmarkProfile
    ProfileName      = $profileName
    PromptCount      = $PromptFiles.Count
    ModelCount       = $rankedRows.Count
    BenchmarkTargetCount = $rankedRows.Count
    GlobalTotals     = [ordered]@{
      TotalExecutions = $totalExecutions
      Completed       = $completeTotal
      Partial         = $partialTotal
      Failed          = $errorTotal
      CompletionRate  = $completionRateAll
      AverageDuration = $avgDurationAll
      AverageQuality  = $avgQualityAll
      AverageStrategy = $avgStrategyAll
      TotalCost       = $totalCostAll
    }
  }

  $summaryJsonPath = Join-Path $RunDir 'run-summary.json'
  Set-JsonContent -Path $summaryJsonPath -Value $summaryPayload
  Write-Host "Run summary report saved: $reportPath" -ForegroundColor Green
}

function New-RunDirectory {
  param(
    [Parameter(Mandatory)]
    [string]$ResultsDir
  )

  $runTimestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $runDir = Join-Path $ResultsDir $runTimestamp
  New-DirectoryIfMissing -Path $runDir

  return [PSCustomObject]@{
    RunTimestamp = $runTimestamp
    RunDir       = $runDir
  }
}

function Start-OrchestratorTranscript {
  param(
    [Parameter(Mandatory)]
    [string]$ResultsDir
  )

  $script:orchestratorTranscriptStarted = $false
  $script:orchestratorTranscriptPath = Join-Path $ResultsDir ("orchestrator-transcript-{0}.log" -f (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'))

  try {
    Start-Transcript -Path $script:orchestratorTranscriptPath -Force | Out-Null
    $script:orchestratorTranscriptStarted = $true
  }
  catch {
    Write-Warning "Unable to start orchestrator transcript: $($_.Exception.Message)"
  }
}

function Stop-OrchestratorTranscript {
  if ($script:orchestratorTranscriptStarted) {
    try {
      Stop-Transcript | Out-Null
    }
    catch {
      Write-Warning "Unable to stop orchestrator transcript: $($_.Exception.Message)"
    }
    finally {
      $script:orchestratorTranscriptStarted = $false
    }
  }
}

function Show-OrchestratorHeader {
  Write-Host '==================================================' -ForegroundColor Cyan
  Write-Host '   LLM Testing Orchestrator - Parallel Mode       ' -ForegroundColor Cyan
  Write-Host '==================================================' -ForegroundColor Cyan
  Write-Host ''
}

function Assert-CliAvailable {
  Write-Host "Checking CLI availability ($CLIType)..." -ForegroundColor Yellow
  try {
    if ($CLIType -eq 'copilot') {
      $null = copilot --version 2>&1
      Write-Host '✓ Copilot CLI found' -ForegroundColor Green
      return
    }

    $null = codex --version 2>&1
    Write-Host '✓ Codex CLI found' -ForegroundColor Green
  }
  catch {
    Write-Error "CLI not found. Please install $CLIType CLI first."
    Stop-OrchestratorTranscript
    exit 1
  }
}

function Get-OrchestratorConfig {
  param(
    [Parameter(Mandatory)]
    [string]$ConfigPath
  )

  if (-not (Test-Path $ConfigPath)) {
    Write-Error "Configuration file not found: $ConfigPath"
    Stop-OrchestratorTranscript
    exit 1
  }

  return Get-Content $ConfigPath -Raw | ConvertFrom-Json
}

function Show-CliConfigStatus {
  param(
    [Parameter(Mandatory)]
    [string]$CliConfigPath
  )

  if (Test-Path $CliConfigPath) {
    Write-Host "✓ CLI config found: $(Split-Path $CliConfigPath -Leaf)" -ForegroundColor Green
  }
  else {
    Write-Host "CLI config not found at $CliConfigPath — using defaults" -ForegroundColor Yellow
  }
}

function Get-PromptFiles {
  param(
    [Parameter(Mandatory)]
    [string]$PromptsDir
  )

  if ($TestPromptId) {
    $found = Get-ChildItem -Path $PromptsDir -Filter "$TestPromptId.md" | Select-Object -First 1
    if (-not $found) {
      Write-Error "Prompt not found: $TestPromptId"
      Stop-OrchestratorTranscript
      exit 1
    }

    return @($found)
  }

  $promptFiles = @(Get-ChildItem -Path $PromptsDir -Filter '*.md' | Sort-Object Name)
  if ($promptFiles.Count -eq 0) {
    Write-Error "No prompt files found in $PromptsDir"
    Stop-OrchestratorTranscript
    exit 1
  }

  return $promptFiles
}

function Show-PromptList {
  param(
    [Parameter(Mandatory)]
    [object[]]$PromptFiles
  )

  Write-Host "Prompts to run: $($PromptFiles.Count)" -ForegroundColor Cyan
  foreach ($pf in $PromptFiles) {
    Write-Host "  - $($pf.BaseName)" -ForegroundColor Yellow
  }
  Write-Host ''
}

function Get-PromptText {
  param(
    [Parameter(Mandatory)]
    [string]$PromptPath,

    [Parameter(Mandatory)]
    [string]$PromptName
  )

  $promptContent = Get-Content $PromptPath -Raw
  $promptMatch = [regex]::Match(
    $promptContent,
    '(?s)##\s+Prompt Text\s*\r?\n\r?\n(.*?)(?=\r?\n##|\z)'
  )

  if ($promptMatch.Success) {
    return $promptMatch.Groups[1].Value.Trim()
  }

  Write-Error "Could not extract prompt text from $PromptName"
  Stop-OrchestratorTranscript
  exit 1
}

function Get-ModelStringProperty {
  param(
    [Parameter(Mandatory)]
    [object]$InputObject,

    [Parameter(Mandatory)]
    [string]$PropertyName
  )

  $property = $InputObject.PSObject.Properties[$PropertyName]
  if ($null -eq $property -or $null -eq $property.Value) {
    return ''
  }

  return [string]$property.Value
}

function Get-ModelStringArrayProperty {
  param(
    [Parameter(Mandatory)]
    [object]$InputObject,

    [Parameter(Mandatory)]
    [string]$PropertyName
  )

  $property = $InputObject.PSObject.Properties[$PropertyName]
  if ($null -eq $property -or $null -eq $property.Value) {
    return @()
  }

  return @(
    @($property.Value | ForEach-Object { [string]$_ }) |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
  )
}

function ConvertTo-CodexReasoningEffort {
  param(
    [Parameter(Mandatory)]
    [ValidateSet('low', 'medium', 'high', 'extra-high')]
    [string]$ReasoningMode
  )

  switch ($ReasoningMode) {
    'extra-high' { return 'xhigh' }
    default { return $ReasoningMode }
  }
}

function Get-ResultFolderName {
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$BaseModelId,

    [Parameter()]
    [AllowNull()]
    [AllowEmptyString()]
    [string]$ReasoningMode
  )

  $folderName = if ([string]::IsNullOrWhiteSpace($ReasoningMode)) {
    $BaseModelId
  }
  else {
    '{0}-{1}' -f $BaseModelId, $ReasoningMode
  }

  return ($folderName -replace '[^a-zA-Z0-9._-]', '-')
}
function New-ModelBenchmarkTargets {
  param(
    [Parameter(Mandatory)]
    [object]$Model,

    [Parameter(Mandatory)]
    [string]$CategoryName,

    [Parameter()]
    [string[]]$RequestedReasoningModes = @()
  )

  $baseModelId = [string]$Model.model
  $baseModelName = [string]$Model.name
  $notes = Get-ModelStringProperty -InputObject $Model -PropertyName 'notes'
  $cost = if ($Model.PSObject.Properties['costPerRequest']) { $Model.costPerRequest } else { 0 }
  $supportedReasoningModes = Get-ModelStringArrayProperty -InputObject $Model -PropertyName 'supportedReasoningModes'
  $benchmarkReasoningModes = Get-ModelStringArrayProperty -InputObject $Model -PropertyName 'benchmarkReasoningModes'
  $defaultReasoningMode = Get-ModelStringProperty -InputObject $Model -PropertyName 'defaultReasoningMode'
  $selectedReasoningModes = @()

  if ($supportedReasoningModes.Count -gt 0) {
    if ($RequestedReasoningModes.Count -gt 0) {
      $selectedReasoningModes = @($RequestedReasoningModes)
    }
    elseif ($benchmarkReasoningModes.Count -gt 0) {
      $selectedReasoningModes = @($benchmarkReasoningModes)
    }
    elseif (-not [string]::IsNullOrWhiteSpace($defaultReasoningMode)) {
      $selectedReasoningModes = @($defaultReasoningMode)
    }
  }

  if ($CLIType -eq 'copilot' -and $selectedReasoningModes.Count -gt 0) {
    Write-Warning "Reasoning benchmark targets for '$baseModelId' will run as separate Copilot sessions, but current Copilot CLI automation does not document a non-interactive reasoning-effort override. These runs keep reasoningModeApplied = false and record the limitation in status/reporting."
  }

  foreach ($mode in $selectedReasoningModes) {
    if ($supportedReasoningModes.Count -gt 0 -and $supportedReasoningModes -notcontains $mode) {
      throw "Reasoning mode '$mode' is not supported for model '$baseModelId'. Supported values: $($supportedReasoningModes -join ', ')"
    }
  }

  if ($selectedReasoningModes.Count -eq 0) {
    return @(
      [PSCustomObject]@{
        Name                 = $baseModelName
        ModelId              = $baseModelId
        BaseModelId          = $baseModelId
        BaseModelName        = $baseModelName
        Category             = $CategoryName
        Enabled              = $Model.enabled
        Cost                 = $cost
        Notes                = $notes
        ReasoningMode        = $null
        CodexReasoningEffort = $null
      }
    )
  }

  $targets = [System.Collections.Generic.List[object]]::new()
  foreach ($mode in $selectedReasoningModes) {
    $targets.Add([PSCustomObject]@{
        Name                 = "$baseModelName [$mode]"
        ModelId              = "$baseModelId--$mode"
        BaseModelId          = $baseModelId
        BaseModelName        = $baseModelName
        Category             = $CategoryName
        Enabled              = $Model.enabled
        Cost                 = $cost
        Notes                = $notes
        ReasoningMode        = $mode
        CodexReasoningEffort = ConvertTo-CodexReasoningEffort -ReasoningMode $mode
      })
  }

  return @($targets)
}

function New-ModelResultObject {
  param(
    [Parameter(Mandatory)]
    [object]$Model,

    [Parameter(Mandatory)]
    [string]$CategoryName
  )

  return [PSCustomObject]@{
    Name                 = $Model.Name
    ModelId              = $Model.ModelId
    BaseModelId          = $Model.BaseModelId
    BaseModelName        = $Model.BaseModelName
    Category             = $CategoryName
    Enabled              = $Model.Enabled
    Cost                 = $Model.Cost
    Notes                = $Model.Notes
    ReasoningMode        = $Model.ReasoningMode
    CodexReasoningEffort = $Model.CodexReasoningEffort
  }
}

function Get-ModelsToTest {
  param(
    [Parameter(Mandatory)]
    [object]$Config
  )

  $modelsToTest = @()

  if ($SpecificModels) {
    foreach ($modelId in $SpecificModels) {
      $found = $false
      $lookupModelId = $modelId
      $requestedModesForModel = @($ReasoningModes)

      if ($modelId -match '^(?<base>.+)--(?<mode>low|medium|high|extra-high)$') {
        $lookupModelId = $Matches.base
        $requestedModesForModel = @($Matches.mode)
      }

      foreach ($category in $Config.llmCategories.PSObject.Properties) {
        $model = $category.Value.models | Where-Object { $_.model -eq $lookupModelId -or $_.name -eq $lookupModelId }
        if ($model) {
          foreach ($target in (New-ModelBenchmarkTargets -Model $model -CategoryName $category.Name -RequestedReasoningModes $requestedModesForModel)) {
            $modelsToTest += New-ModelResultObject -Model $target -CategoryName $category.Name
          }
          $found = $true
          break
        }
      }

      if (-not $found) {
        Write-Warning "Model not found in configuration: $modelId"
      }
    }
  }
  else {
    $categories = if ($LLMCategory -eq 'all') {
      $Config.llmCategories.PSObject.Properties.Name
    }
    else {
      @($LLMCategory)
    }

    foreach ($catName in $categories) {
      $category = $Config.llmCategories.$catName
      foreach ($model in $category.models) {
        if ($model.enabled) {
          foreach ($target in (New-ModelBenchmarkTargets -Model $model -CategoryName $catName -RequestedReasoningModes $ReasoningModes)) {
            $modelsToTest += New-ModelResultObject -Model $target -CategoryName $catName
          }
        }
      }
    }
  }

  $seenModelIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
  $dedupedModelsToTest = [System.Collections.Generic.List[object]]::new()
  foreach ($model in $modelsToTest) {
    if ($seenModelIds.Add([string]$model.ModelId)) {
      $dedupedModelsToTest.Add($model)
    }
  }
  $modelsToTest = @($dedupedModelsToTest)

  if ($modelsToTest.Count -eq 0) {
    Write-Error 'No models selected for testing'
    Stop-OrchestratorTranscript
    exit 1
  }

  return $modelsToTest
}

function Show-ModelsToTest {
  param(
    [Parameter(Mandatory)]
    [object[]]$Models
  )

  Write-Host "`nModels to Test: $($Models.Count)" -ForegroundColor Cyan
  foreach ($model in $Models) {
    $reasoningLabel = if (-not [string]::IsNullOrWhiteSpace($model.ReasoningMode)) {
      if ($CLIType -eq 'copilot') {
        " | reasoning: $($model.ReasoningMode) (recorded-only in Copilot CLI)"
      }
      else {
        " | reasoning: $($model.ReasoningMode)"
      }
    } else { '' }
    Write-Host "  - $($model.Name) ($($model.Category)$reasoningLabel)" -ForegroundColor Yellow
  }
}

function New-Session {
  param(
    [Parameter(Mandatory)]
    [string]$RunDir,

    [Parameter(Mandatory)]
    [string]$RunTimestamp,

    [Parameter(Mandatory)]
    [string]$PromptId,

    [Parameter(Mandatory)]
    [object]$PromptFile,

    [Parameter(Mandatory)]
    [object[]]$ModelsToTest,

    [Parameter(Mandatory)]
    [string]$BenchmarkProfile,

    [Parameter(Mandatory)]
    [string]$ConfigPath,

    [Parameter()]
    [string[]]$RequirementPackPaths = @()
  )

  $sessionDir = Join-Path $RunDir $PromptId
  New-DirectoryIfMissing -Path $sessionDir
  $effectiveCopilotAgent = if ($CLIType -eq 'copilot') { Resolve-CopilotAgentName -Agent $CopilotAgent } else { '' }

  $sessionMetadata = @{
    RunTimestamp       = $RunTimestamp
    PromptTimestamp    = (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')
    PromptId           = $PromptId
    PromptFile         = $PromptFile.Name
    BenchmarkProfile   = $BenchmarkProfile
    CLIType            = $CLIType
    CopilotAgent       = if ($CLIType -eq 'copilot' -and -not [string]::IsNullOrWhiteSpace($effectiveCopilotAgent)) { $effectiveCopilotAgent } else { $null }
    MaxParallel        = $MaxParallel
    ShowCLIProgress    = [bool]$ShowCLIProgress
    ModelsCount        = $ModelsToTest.Count
    Categories         = ($ModelsToTest | Select-Object -ExpandProperty Category -Unique)
    ReasoningModesRequested = @($ReasoningModes)
    BenchmarkTargets   = @(
      $ModelsToTest | ForEach-Object {
        [ordered]@{
          name          = $_.Name
          modelId       = $_.ModelId
          baseModelId   = $_.BaseModelId
          reasoningMode = $_.ReasoningMode
          category      = $_.Category
        }
      }
    )
    RequirementPacks   = @($RequirementPackPaths | ForEach-Object { [System.IO.Path]::GetFileName($_) })
    ConfigurationState = @{
      llmConfigVersion = (Get-FileHash $ConfigPath).Hash.Substring(0, 8)
    }
  }

  Set-JsonContent -Path (Join-Path $sessionDir 'session-metadata.json') -Value $sessionMetadata
  Copy-FileSafe -Path $PromptFile.FullName -Destination (Join-Path $sessionDir 'prompt-used.md')

  return $sessionDir
}

function Show-SessionHeader {
  param(
    [Parameter(Mandatory)]
    [string]$SessionDir
  )

  Write-Host "`nSession Directory: $SessionDir" -ForegroundColor Green
  Write-Host "`n==================================================" -ForegroundColor Cyan
  Write-Host '   Starting Parallel Test Execution                ' -ForegroundColor Cyan
  Write-Host '==================================================' -ForegroundColor Cyan
  Write-Host ''
}

function Assert-HelperScript {
  param(
    [Parameter(Mandatory)]
    [string]$HelperScript
  )

  if (-not (Test-Path $HelperScript)) {
    Write-Error "Helper script not found: $HelperScript. Ensure Invoke-CLITest.ps1 is in the scripts directory."
    Stop-OrchestratorTranscript
    exit 1
  }

  Write-Host "✓ Helper script found: $($HelperScript | Split-Path -Leaf)" -ForegroundColor Green
}

function Start-ModelTestJob {
  param(
    [Parameter(Mandatory)]
    [object]$Model,

    [Parameter(Mandatory)]
    [string]$SessionDir,

    [Parameter(Mandatory)]
    [string]$PromptText,

    [Parameter(Mandatory)]
    [string]$PromptId,

    [Parameter(Mandatory)]
    [string]$BenchmarkProfile,

    [Parameter(Mandatory)]
    [string]$HelperScript,

    [Parameter()]
    [string]$CopilotAgent,

    [Parameter()]
    [string[]]$RequirementPackPaths = @(),

    [Parameter()]
    [bool]$WhatIfEnabled = $false,

    [Parameter()]
    [string]$TerminalWindowId
  )

  $modelDir = Join-Path $SessionDir (Get-ResultFolderName -BaseModelId $Model.BaseModelId -ReasoningMode $Model.ReasoningMode)
  New-DirectoryIfMissing -Path $modelDir

  $logsDir = Join-Path $modelDir 'logs'
  Write-Host "    instance log: $(Join-Path $logsDir 'instance-events.log')" -ForegroundColor DarkGray
  Write-Host "    stdout: $(Join-Path $logsDir 'stdout.txt')" -ForegroundColor DarkGray
  Write-Host "    stderr: $(Join-Path $logsDir 'stderr.txt')" -ForegroundColor DarkGray

  return Start-Job -Name ("llm-{0}" -f ($Model.ModelId -replace '[^a-zA-Z0-9._-]', '-')) -ScriptBlock {
    param(
      [object]$Model,
      [string]$SessionDir,
      [string]$PromptText,
      [string]$PromptId,
      [string]$BenchmarkProfile,
      [string]$HelperScript,
      [string]$CLIType,
      [string]$CopilotAgent,
      [bool]$ShowCLIProgress,
      [bool]$WhatIfEnabled,
      [string]$TerminalWindowId,
      [string[]]$RequirementPackPaths
    )

    $resultFolderName = if ([string]::IsNullOrWhiteSpace($Model.ReasoningMode)) {
      $Model.BaseModelId
    }
    else {
      '{0}-{1}' -f $Model.BaseModelId, $Model.ReasoningMode
    }

    $modelDir = Join-Path $SessionDir ($resultFolderName -replace '[^a-zA-Z0-9._-]', '-')
    if (-not (Test-Path $modelDir)) {
      New-Item -Path $modelDir -ItemType Directory -Force | Out-Null
    }

    $startTime = Get-Date
    try {
      $result = & $HelperScript `
        -ModelId $Model.ModelId `
        -ModelName $Model.Name `
        -BaseModelId $Model.BaseModelId `
        -BaseModelName $Model.BaseModelName `
        -Category $Model.Category `
        -PromptText $PromptText `
        -PromptId $PromptId `
        -BenchmarkProfile $BenchmarkProfile `
        -OutputDir $modelDir `
        -CLIType $CLIType `
        -AgentName $CopilotAgent `
        -CostPerRequest $Model.Cost `
        -ReasoningMode $Model.ReasoningMode `
        -CodexReasoningEffort $Model.CodexReasoningEffort `
        -RequirementPackFiles $RequirementPackPaths `
        -ShowCLIProgress:$ShowCLIProgress `
        -TerminalWindowId $TerminalWindowId `
        -WhatIf:$WhatIfEnabled

      $duration = ((Get-Date) - $startTime).TotalSeconds
      $isSuccess = $null -ne $result -and $result.responseCompleteness -ne 'error'

      return [PSCustomObject]@{
        Success      = $isSuccess
        Model        = $Model
        Duration     = $duration
        Result       = $result
        OutputDir    = $modelDir
        ErrorMessage = if ($isSuccess) { $null } else { $result.errorDetails }
      }
    }
    catch {
      $duration = ((Get-Date) - $startTime).TotalSeconds
      return [PSCustomObject]@{
        Success      = $false
        Model        = $Model
        Duration     = $duration
        Result       = $null
        OutputDir    = $modelDir
        ErrorMessage = $_.ToString()
      }
    }
  } -ArgumentList @($Model, $SessionDir, $PromptText, $PromptId, $BenchmarkProfile, $HelperScript, $CLIType, $CopilotAgent, [bool]$ShowCLIProgress, $WhatIfEnabled, $TerminalWindowId, @($RequirementPackPaths))
}

function Receive-ModelTestJobResult {
  param(
    [Parameter(Mandatory)]
    [System.Management.Automation.Job]$Job
  )

  $result = $null
  try {
    $jobOutput = Receive-Job -Job $Job -ErrorAction Stop
    $result = @($jobOutput) | Select-Object -Last 1
  }
  catch {
    $result = [PSCustomObject]@{
      Success      = $false
      Model        = [PSCustomObject]@{ Name = $Job.Name; ModelId = $Job.Name; Category = 'unknown' }
      Duration     = 0
      Result       = $null
      OutputDir    = ''
      ErrorMessage = $_.ToString()
    }
  }
  finally {
    Remove-Job -Job $Job -Force -ErrorAction SilentlyContinue -WhatIf:$false
  }

  if ($null -eq $result) {
    return [PSCustomObject]@{
      Success      = $false
      Model        = [PSCustomObject]@{ Name = $Job.Name; ModelId = $Job.Name; Category = 'unknown' }
      Duration     = 0
      Result       = $null
      OutputDir    = ''
      ErrorMessage = 'No output was returned from job.'
    }
  }

  return $result
}

function Show-ExecutionSummary {
  param(
    [Parameter(Mandatory)]
    [int]$TotalTests,

    [Parameter(Mandatory)]
    [int]$Completed,

    [Parameter(Mandatory)]
    [int]$Failed
  )

  Write-Host '==================================================' -ForegroundColor Cyan
  Write-Host '   Test Execution Complete                         ' -ForegroundColor Cyan
  Write-Host '==================================================' -ForegroundColor Cyan
  Write-Host ''
  Write-Host "Total Tests: $TotalTests" -ForegroundColor Cyan
  Write-Host "Completed: $($Completed - $Failed)" -ForegroundColor Green
  Write-Host "Failed: $Failed" -ForegroundColor $(if ($Failed -gt 0) { 'Red' } else { 'Green' })
  Write-Host ''
}

function Save-ConsolidatedResults {
  param(
    [object[]]$Results,

    [Parameter(Mandatory)]
    [string]$SessionDir
  )

  $allMetrics = @()
  $safeResults = @($Results)
  foreach ($testResult in $safeResults) {
    if ($testResult.Success -and $testResult.Result) {
      $allMetrics += $testResult.Result
    }
  }

  if ($allMetrics.Count -gt 0) {
    Set-JsonContent -Path (Join-Path $SessionDir 'all-results.json') -Value $allMetrics
    Write-Host "Consolidated results saved: all-results.json ($($allMetrics.Count) entries)" -ForegroundColor Green
    return $true
  }

  Write-Warning 'No successful model results to consolidate. Skipping all-results.json.'
  return $false
}

function Invoke-Analysis {
  param(
    [Parameter(Mandatory)]
    [string]$AnalysisScript,

    [Parameter(Mandatory)]
    [string]$SessionDir
  )

  if ($WhatIfPreference) {
    Write-Host 'WhatIf: skipping analysis invocation.' -ForegroundColor Yellow
    return
  }

  Write-Host 'Generating analysis reports...' -ForegroundColor Yellow
  if (Test-Path $AnalysisScript) {
    & $AnalysisScript -SessionPath $SessionDir -OutputFormat $OutputFormat
  }
  else {
    Write-Warning 'Analysis script not found. Skipping automated analysis.'
  }
}

function Show-SessionComplete {
  param(
    [Parameter(Mandatory)]
    [string]$SessionDir
  )

  Write-Host ''
  Write-Host '==================================================' -ForegroundColor Green
  Write-Host '   Session Complete!                              ' -ForegroundColor Green
  Write-Host '==================================================' -ForegroundColor Green
  Write-Host ''
  Write-Host "Results saved to: $SessionDir" -ForegroundColor Cyan
  Write-Host ''
  Write-Host 'Next steps:' -ForegroundColor Yellow
  Write-Host '  1. Review the comparison report in the reports/ directory' -ForegroundColor White
  Write-Host '  2. Check individual model outputs in their respective directories' -ForegroundColor White
  Write-Host '  3. Run additional analysis if needed' -ForegroundColor White
  Write-Host ''
}

$paths = Initialize-OrchestratorPaths
$runInfo = New-RunDirectory -ResultsDir $paths.ResultsDir
Start-OrchestratorTranscript -ResultsDir $runInfo.RunDir

try {
  Show-OrchestratorHeader
  Assert-CliAvailable

  Write-Host "Run directory: $($runInfo.RunDir)" -ForegroundColor Green
  Write-Host "Max parallel workers: $MaxParallel" -ForegroundColor Green
  if ($CLIType -eq 'copilot' -and -not [string]::IsNullOrWhiteSpace($CopilotAgent)) {
    Write-Host "Copilot agent: $CopilotAgent" -ForegroundColor Green
  }
  Write-Host "CLI progress mode: $(if ($ShowCLIProgress) { 'interactive' } else { 'passive' })" -ForegroundColor Green
  Write-Host ''

  $config = Get-OrchestratorConfig -ConfigPath $paths.ConfigPath
  Show-CliConfigStatus -CliConfigPath $paths.CliConfigPath
  $strategyProfiles = Get-StrategyProfiles -StrategyProfilesPath $paths.StrategyProfilesPath
  $selectedProfile = Get-BenchmarkProfileConfig -StrategyProfiles $strategyProfiles -ProfileId $BenchmarkProfile
  $externalAssetsCatalog = Get-ExternalAssetsCatalog -CatalogPath $paths.ExternalAssetsPath
  $profileRequirementPacks = if ($selectedProfile.requirementPacks) { @($selectedProfile.requirementPacks) } else { @() }
  $requirementPackPaths = Get-RequirementPackPaths -RequirementsDir $paths.RequirementsDir -TestRoot $paths.TestRoot -ProfileRequirementPacks $profileRequirementPacks -ExplicitPacks $RequirementPacks
  Write-Host "Benchmark profile: $BenchmarkProfile ($(if ($selectedProfile.name) { $selectedProfile.name } else { 'unnamed' }))" -ForegroundColor Green
  if ($selectedProfile.description) {
    Write-Host "Profile description: $($selectedProfile.description)" -ForegroundColor DarkGray
  }
  if ($requirementPackPaths.Count -gt 0) {
    Write-Host "Requirement packs applied: $($requirementPackPaths.Count)" -ForegroundColor Green
    foreach ($packPath in $requirementPackPaths) {
      Write-Host "  - $([System.IO.Path]::GetFileName($packPath))" -ForegroundColor DarkGray
    }
  }
  else {
    Write-Host 'Requirement packs applied: 0 (none found)' -ForegroundColor Yellow
  }

  $promptFiles = Get-PromptFiles -PromptsDir $paths.PromptsDir
  Show-PromptList -PromptFiles $promptFiles

  Assert-HelperScript -HelperScript $paths.HelperScript

  $runStartTime = Get-Date
  $promptIndex = 0
  $promptProgressId = 1
  $llmProgressId = 2
  $totalPrompts = [Math]::Max($promptFiles.Count, 1)

  foreach ($promptFile in $promptFiles) {
    $promptIndex++
    $promptId = $promptFile.BaseName
    $completedPrompts = $promptIndex - 1
    $promptPercent = [int](($completedPrompts / $totalPrompts) * 100)
    $runElapsed = (Get-Date) - $runStartTime
    $runEta = Get-EstimatedRemaining -StartTime $runStartTime -Completed $completedPrompts -Total $totalPrompts
    Write-Progress -Id $promptProgressId -Activity 'Prompt Progress' -Status "[$promptIndex/$($promptFiles.Count)] $promptId | Elapsed: $(Format-DurationText -Duration $runElapsed) | Remaining: $(Format-DurationText -Duration $runEta)" -PercentComplete $promptPercent

    Write-Host "`n##################################################" -ForegroundColor Magenta
    Write-Host "   Prompt $promptIndex/$($promptFiles.Count): $($promptFile.BaseName)" -ForegroundColor Magenta
    Write-Host '##################################################' -ForegroundColor Magenta

    $promptText = Get-PromptText -PromptPath $promptFile.FullName -PromptName $promptFile.Name
    $modelsToTest = Get-ModelsToTest -Config $config
    Show-ModelsToTest -Models $modelsToTest

    $sessionDir = New-Session -RunDir $runInfo.RunDir -RunTimestamp $runInfo.RunTimestamp -PromptId $promptId -PromptFile $promptFile -ModelsToTest $modelsToTest -BenchmarkProfile $BenchmarkProfile -ConfigPath $paths.ConfigPath -RequirementPackPaths $requirementPackPaths
    Show-SessionHeader -SessionDir $sessionDir

    Write-Host "Running tests with up to $MaxParallel concurrent workers..." -ForegroundColor Yellow
    if ($ShowCLIProgress) {
      Write-Host 'Interactive CLI progress is enabled. Each run uses an interactive PowerShell window.' -ForegroundColor Yellow
    }
    Write-Host ''

    $results = [System.Collections.Generic.List[object]]::new()
    $runningJobs = [System.Collections.Generic.List[object]]::new()
    $jobMetadata = @{}
    $pendingModels = [System.Collections.Generic.Queue[object]]::new()
    foreach ($model in $modelsToTest) {
      $pendingModels.Enqueue($model)
    }

    $totalTests = $modelsToTest.Count
    $completed = 0
    $failed = 0
    $promptStartTime = Get-Date
    try {
      while ($pendingModels.Count -gt 0 -or $runningJobs.Count -gt 0) {
        while ($pendingModels.Count -gt 0 -and $runningJobs.Count -lt $MaxParallel) {
          $nextModel = $pendingModels.Dequeue()
          Write-Host "  → Starting test for $($nextModel.Name)..." -ForegroundColor Gray
          $job = Start-ModelTestJob -Model $nextModel -SessionDir $sessionDir -PromptText $promptText -PromptId $promptId -BenchmarkProfile $BenchmarkProfile -HelperScript $paths.HelperScript -CopilotAgent $CopilotAgent -RequirementPackPaths $requirementPackPaths -WhatIfEnabled:$WhatIfPreference -TerminalWindowId $env:WT_SESSION
          $runningJobs.Add($job) | Out-Null
          $jobMetadata[$job.Id] = [PSCustomObject]@{
            ModelName = $nextModel.Name
            OutputDir = Join-Path $sessionDir (Get-ResultFolderName -BaseModelId $nextModel.BaseModelId -ReasoningMode $nextModel.ReasoningMode)
            StartedAt = Get-Date
          }
        }

        $llmElapsed = (Get-Date) - $promptStartTime
        $llmEta = Get-EstimatedRemaining -StartTime $promptStartTime -Completed $completed -Total $totalTests
        $runningCount = $runningJobs.Count
        $liveProgressDetails = if ($runningCount -gt 0) {
          Get-LiveSessionProgressDetails -RunningJobs @($runningJobs) -JobMetadata $jobMetadata
        }
        else {
          'No active sessions'
        }
        $llmPercent = [int](($completed / [Math]::Max($totalTests, 1)) * 100)
        Write-Progress -Id $llmProgressId -ParentId $promptProgressId -Activity "LLM Progress: $promptId" -Status "Completed $completed/$totalTests | Running $runningCount | Failed $failed | Elapsed: $(Format-DurationText -Duration $llmElapsed) | Remaining: $(Format-DurationText -Duration $llmEta) | $liveProgressDetails" -PercentComplete $llmPercent

        if ($runningJobs.Count -eq 0) {
          continue
        }

        $finishedJob = Wait-Job -Job @($runningJobs) -Any -Timeout 1
        if ($null -eq $finishedJob) {
          continue
        }

        foreach ($job in @($finishedJob)) {
          $jobMeta = if ($jobMetadata.ContainsKey($job.Id)) { $jobMetadata[$job.Id] } else { $null }
          $jobResult = Receive-ModelTestJobResult -Job $job
          $completed++
          [void]$runningJobs.Remove($job)
          if ($jobMetadata.ContainsKey($job.Id)) {
            [void]$jobMetadata.Remove($job.Id)
          }

          if ($jobResult.Success) {
            $completionSuffix = if ($CLIType -eq 'copilot' -and -not [string]::IsNullOrWhiteSpace($jobResult.Model.ReasoningMode)) { ' [reasoning recorded only]' } else { '' }
            Write-Host "  ✓ $($jobResult.Model.Name) completed in $([Math]::Round($jobResult.Duration, 2))s$completionSuffix" -ForegroundColor Green
            $results.Add($jobResult)
          }
          else {
            Write-Host "  ✗ $($jobResult.Model.Name) failed: $($jobResult.ErrorMessage)" -ForegroundColor Red
            $outputDirForLog = if ($jobResult.OutputDir) { $jobResult.OutputDir } elseif ($null -ne $jobMeta) { $jobMeta.OutputDir } else { '' }
            if ($outputDirForLog) {
              Write-Host "    instance log: $(Join-Path $outputDirForLog 'logs\instance-events.log')" -ForegroundColor DarkGray
            }
            $failed++
          }

          $progressElapsed = (Get-Date) - $promptStartTime
          $progressEta = Get-EstimatedRemaining -StartTime $promptStartTime -Completed $completed -Total $totalTests
          Write-Host "  Progress: $completed/$totalTests ($failed failed) | Elapsed: $(Format-DurationText -Duration $progressElapsed) | Remaining: $(Format-DurationText -Duration $progressEta)" -ForegroundColor Yellow
          Write-Host ''
        }
      }
    }
    finally {
      foreach ($job in @($runningJobs)) {
        Stop-Job -Job $job -ErrorAction SilentlyContinue -WhatIf:$false
        Remove-Job -Job $job -Force -ErrorAction SilentlyContinue -WhatIf:$false
        if ($jobMetadata.ContainsKey($job.Id)) {
          [void]$jobMetadata.Remove($job.Id)
        }
      }
    }

    Write-Progress -Id $llmProgressId -ParentId $promptProgressId -Activity 'LLM Progress' -Completed
    Show-ExecutionSummary -TotalTests $totalTests -Completed $completed -Failed $failed

    $hasConsolidatedResults = Save-ConsolidatedResults -Results @($results) -SessionDir $sessionDir
    if ($hasConsolidatedResults) {
      Invoke-Analysis -AnalysisScript $paths.AnalysisScript -SessionDir $sessionDir
    }
    else {
      Write-Warning 'Skipping analysis because there are no consolidated results for this prompt run.'
    }
    Show-SessionComplete -SessionDir $sessionDir

    $promptCompletedPercent = [int](($promptIndex / $totalPrompts) * 100)
    $runElapsedFinal = (Get-Date) - $runStartTime
    $runEtaFinal = Get-EstimatedRemaining -StartTime $runStartTime -Completed $promptIndex -Total $totalPrompts
    Write-Progress -Id $promptProgressId -Activity 'Prompt Progress' -Status "Completed prompt $promptIndex/$($promptFiles.Count): $promptId | Elapsed: $(Format-DurationText -Duration $runElapsedFinal) | Remaining: $(Format-DurationText -Duration $runEtaFinal)" -PercentComplete $promptCompletedPercent
  }

  Write-Progress -Id $promptProgressId -Activity 'Prompt Progress' -Completed

  New-RunSummaryReport -RunDir $runInfo.RunDir -RunTimestamp $runInfo.RunTimestamp -PromptFiles $promptFiles -CLIType $CLIType -CopilotAgent $CopilotAgent -BenchmarkProfile $BenchmarkProfile -StrategyProfile $selectedProfile -ExternalAssetsCatalog $externalAssetsCatalog -RequirementPackPaths $requirementPackPaths

  if ($promptFiles.Count -gt 1) {
    Write-Host '==================================================' -ForegroundColor Magenta
    Write-Host "   All $($promptFiles.Count) prompts completed!   " -ForegroundColor Magenta
    Write-Host '==================================================' -ForegroundColor Magenta
    Write-Host "Results root: $($runInfo.RunDir)" -ForegroundColor Cyan
    Write-Host ''
  }
}
finally {
  Stop-OrchestratorTranscript
  if ($script:orchestratorTranscriptPath) {
    Write-Host "Orchestrator transcript saved: $($script:orchestratorTranscriptPath)" -ForegroundColor DarkGray
  }
}





