<#
.SYNOPSIS
    Executes LLM comparison tests and collects results.

.DESCRIPTION
    This script orchestrates the testing of multiple LLMs by generating code based on defined prompts.
    It measures performance, costs, and provides a framework for quality comparison.

.PARAMETER TestPromptId
    The ID of the test prompt to use (e.g., "01-crud-api-with-validation")

.PARAMETER LLMCategory
    The category of LLMs to test: "free", "cheap", "standard", or "all"

.PARAMETER SpecificModel
    Test only a specific model by name

.PARAMETER ReasoningModes
    Optional reasoning modes to benchmark for supported models. Accepted values are
    "low", "medium", "high", and "extra-high". When omitted, supported models expand to the
    configured benchmarkReasoningModes from llm-config.json. Each reasoning target gets its own
    result folder using the pattern [model]-[reasoningmode].

.PARAMETER OutputPath
    Path to save results (defaults to ../results)

.EXAMPLE
    .\Invoke-LLMTest.ps1 -TestPromptId "01-crud-api-with-validation" -LLMCategory "all"
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [Parameter(Mandatory = $false)]
  [string]$TestPromptId,

  [Parameter(Mandatory = $false)]
  [ValidateSet("free", "cheap", "standard", "all")]
  [string]$LLMCategory = "all",

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]$SpecificModel,

  [Parameter(Mandatory = $false)]
  [ValidateSet("low", "medium", "high", "extra-high")]
  [string[]]$ReasoningModes = @(),

  [Parameter(Mandatory = $false)]
  [ValidateNotNullOrEmpty()]
  [string]$OutputPath
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

function Get-Paths {
  $scriptRoot = Split-Path -Parent $PSScriptRoot
  return [PSCustomObject]@{
    ConfigPath  = Join-Path $scriptRoot 'llm-config.json'
    PromptsPath = Join-Path $scriptRoot 'prompts'
    ResultsPath = if ($OutputPath) { $OutputPath } else { Join-Path $scriptRoot 'results' }
  }
}

function Initialize-ResultsDirectory {
  param(
    [Parameter(Mandatory)]
    [string]$Path
  )

  New-DirectoryIfMissing -Path $Path
}

function Get-Config {
  param(
    [Parameter(Mandatory)]
    [string]$Path
  )

  Write-Host 'Loading LLM configuration...' -ForegroundColor Cyan
  return Get-Content $Path -Raw | ConvertFrom-Json
}

function Get-AvailablePrompts {
  param(
    [Parameter(Mandatory)]
    [string]$PromptsPath
  )

  return Get-ChildItem -Path $PromptsPath -Filter '*.md' | ForEach-Object {
    [PSCustomObject]@{
      Id   = $_.BaseName
      Path = $_.FullName
      Name = $_.Name
    }
  }
}

function Select-Prompt {
  param(
    [Parameter(Mandatory)]
    [object[]]$AvailablePrompts
  )

  if (-not $TestPromptId) {
    Write-Host "`nAvailable Test Prompts:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $AvailablePrompts.Count; $i++) {
      Write-Host "  [$($i + 1)] $($AvailablePrompts[$i].Id)" -ForegroundColor White
    }

    $selection = Read-Host "`nSelect prompt number (1-$($AvailablePrompts.Count))"
    return $AvailablePrompts[$selection - 1]
  }

  $selectedPrompt = $AvailablePrompts | Where-Object { $_.Id -eq $TestPromptId }
  if (-not $selectedPrompt) {
    Write-Error "Prompt ID '$TestPromptId' not found"
    exit 1
  }

  return $selectedPrompt
}

function Get-PromptText {
  param(
    [Parameter(Mandatory)]
    [string]$PromptPath
  )

  $promptContent = Get-Content $PromptPath -Raw
  if ($promptContent -match '(?s)## Prompt Text\s*\n\n(.+)') {
    return $matches[1].Trim()
  }

  return $promptContent
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
function New-ExpandedModelObjects {
  param(
    [Parameter(Mandatory)]
    [object]$Model,

    [Parameter(Mandatory)]
    [string]$CategoryName,

    [Parameter(Mandatory)]
    [object]$Category,

    [Parameter()]
    [string[]]$RequestedReasoningModes = @()
  )

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

  foreach ($mode in $selectedReasoningModes) {
    if ($supportedReasoningModes.Count -gt 0 -and $supportedReasoningModes -notcontains $mode) {
      throw "Reasoning mode '$mode' is not supported for model '$($Model.model)'. Supported values: $($supportedReasoningModes -join ', ')"
    }
  }

  if ($selectedReasoningModes.Count -eq 0) {
    return @(
      [PSCustomObject]@{
        Name               = $Model.name
        Model              = $Model.model
        BaseModelId        = $Model.model
        BaseModelName      = $Model.name
        Category           = $CategoryName
        CategoryMultiplier = $Category.multiplier
        CostPerRequest     = if ($Model.PSObject.Properties.Name -contains 'costPerRequest') { $Model.costPerRequest } else { 0 }
        Notes              = $Model.notes
        ReasoningMode      = $null
        CodexReasoningEffort = $null
      }
    )
  }

  $expandedModels = [System.Collections.Generic.List[object]]::new()
  foreach ($mode in $selectedReasoningModes) {
    $expandedModels.Add([PSCustomObject]@{
        Name                 = "$($Model.name) [$mode]"
        Model                = "$($Model.model)--$mode"
        BaseModelId          = $Model.model
        BaseModelName        = $Model.name
        Category             = $CategoryName
        CategoryMultiplier   = $Category.multiplier
        CostPerRequest       = if ($Model.PSObject.Properties.Name -contains 'costPerRequest') { $Model.costPerRequest } else { 0 }
        Notes                = $Model.notes
        ReasoningMode        = $mode
        CodexReasoningEffort = ConvertTo-CodexReasoningEffort -ReasoningMode $mode
      })
  }

  return @($expandedModels)
}

function New-ModelObject {
  param(
    [Parameter(Mandatory)]
    [object]$Model,

    [Parameter(Mandatory)]
    [string]$CategoryName,

    [Parameter(Mandatory)]
    [object]$Category
  )

  return [PSCustomObject]@{
    Name                 = $Model.Name
    Model                = $Model.Model
    BaseModelId          = $Model.BaseModelId
    BaseModelName        = $Model.BaseModelName
    Category             = $CategoryName
    CategoryMultiplier   = $Category.multiplier
    CostPerRequest       = $Model.CostPerRequest
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

  $llmsToTest = @()

  if ($SpecificModel) {
    $lookupModelId = $SpecificModel
    $requestedModesForModel = @($ReasoningModes)

    if ($SpecificModel -match '^(?<base>.+)--(?<mode>low|medium|high|extra-high)$') {
      $lookupModelId = $Matches.base
      $requestedModesForModel = @($Matches.mode)
    }

    foreach ($category in $Config.llmCategories.PSObject.Properties) {
      $model = $category.Value.models | Where-Object { $_.model -eq $lookupModelId -or $_.name -eq $lookupModelId }
      if ($model -and $model.enabled) {
        foreach ($expanded in (New-ExpandedModelObjects -Model $model -CategoryName $category.Name -Category $category.Value -RequestedReasoningModes $requestedModesForModel)) {
          $llmsToTest += New-ModelObject -Model $expanded -CategoryName $category.Name -Category $category.Value
        }
        break
      }
    }

    if ($llmsToTest.Count -eq 0) {
      Write-Error "Model '$SpecificModel' not found or not enabled"
      exit 1
    }

    return $llmsToTest
  }

  $categoriesToTest = if ($LLMCategory -eq 'all') {
    $Config.llmCategories.PSObject.Properties.Name
  }
  else {
    @($LLMCategory)
  }

  foreach ($categoryName in $categoriesToTest) {
    $category = $Config.llmCategories.$categoryName
    foreach ($model in $category.models) {
      if ($model.enabled) {
        foreach ($expanded in (New-ExpandedModelObjects -Model $model -CategoryName $categoryName -Category $category -RequestedReasoningModes $ReasoningModes)) {
          $llmsToTest += New-ModelObject -Model $expanded -CategoryName $categoryName -Category $category
        }
      }
    }
  }

  $seenModelIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
  $dedupedLlmsToTest = [System.Collections.Generic.List[object]]::new()
  foreach ($model in $llmsToTest) {
    if ($seenModelIds.Add([string]$model.Model)) {
      $dedupedLlmsToTest.Add($model)
    }
  }

  return @($dedupedLlmsToTest)
}

function Show-ModelsToTest {
  param(
    [Parameter(Mandatory)]
    [object[]]$Models
  )

  Write-Host "`nLLMs to test ($($Models.Count)):" -ForegroundColor Cyan
  $Models | ForEach-Object {
    $costInfo = if ($_.CostPerRequest -gt 0) { " (Cost: `$$($_.CostPerRequest))" } else { ' (Free)' }
    $reasoningInfo = if ($_.ReasoningMode) { " | reasoning: $($_.ReasoningMode)" } else { '' }
    Write-Host "  - $($_.Name)$costInfo$reasoningInfo" -ForegroundColor White
  }
}

function New-TestSession {
  param(
    [Parameter(Mandatory)]
    [string]$ResultsPath,

    [Parameter(Mandatory)]
    [object]$SelectedPrompt,

    [Parameter(Mandatory)]
    [object]$Config,

    [Parameter(Mandatory)]
    [object[]]$Models
  )

  $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $runPath = Join-Path $ResultsPath $timestamp
  New-DirectoryIfMissing -Path $runPath
  $sessionPath = Join-Path $runPath $SelectedPrompt.Id
  New-DirectoryIfMissing -Path $sessionPath

  $sessionMetadata = [PSCustomObject]@{
    RunTimestamp      = $timestamp
    PromptTimestamp   = (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')
    PromptId          = $SelectedPrompt.Id
    PromptPath        = $SelectedPrompt.Path
    LLMCategory       = $LLMCategory
    ReasoningModesRequested = @($ReasoningModes)
    TestConfiguration = $Config.testConfiguration
    LLMsTested        = $Models.Count
    BenchmarkTargets  = @(
      $Models | ForEach-Object {
        [ordered]@{
          name          = $_.Name
          modelId       = $_.Model
          baseModelId   = $_.BaseModelId
          reasoningMode = $_.ReasoningMode
          category      = $_.Category
        }
      }
    )
  }

  Set-JsonContent -Path (Join-Path $sessionPath 'session-metadata.json') -Value $sessionMetadata
  Copy-FileSafe -Path $SelectedPrompt.Path -Destination (Join-Path $sessionPath 'prompt-used.md')

  return [PSCustomObject]@{
    Timestamp   = $timestamp
    SessionPath = $sessionPath
  }
}

function New-TestInstructions {
  param(
    [Parameter(Mandatory)]
    [object]$Llm,

    [Parameter(Mandatory)]
    [object]$SelectedPrompt
  )

  return @"
# Test Instructions for $($Llm.Name)

## Model Information
- **Name**: $($Llm.Name)
- **Model Variant ID**: $($Llm.Model)
- **Base Model ID**: $($Llm.BaseModelId)
- **Category**: $($Llm.Category)
- **Cost per Request**: `$$($Llm.CostPerRequest)
- **Reasoning Mode**: $(if ($Llm.ReasoningMode) { $Llm.ReasoningMode } else { 'N/A' })
- **Codex Reasoning Effort**: $(if ($Llm.CodexReasoningEffort) { $Llm.CodexReasoningEffort } else { 'N/A' })
- **Notes**: $($Llm.Notes)

## Testing Instructions

### Step 1: Open GitHub Copilot Chat
1. Open VS Code
2. Open GitHub Copilot Chat (Ctrl+Shift+I or Cmd+Shift+I)
3. Switch to model: **$($Llm.BaseModelId)**
4. $(if ($Llm.ReasoningMode) { "If your client exposes reasoning controls, set the reasoning mode to **$($Llm.ReasoningMode)** (Codex/API value: **$($Llm.CodexReasoningEffort)**). If you cannot confirm that override in the client, keep **reasoningModeApplied** = **false** in metrics.json and note the limitation in observations.md." } else { 'Use the model default reasoning settings.' })

### Step 2: Run the Test
1. Copy the prompt from: ``prompt-used.md``
2. Paste it into the chat
3. **Start timer** before sending
4. Send the prompt
5. **Stop timer** when complete response is received

### Step 3: Save Results
1. Save all generated C# files to: ``code\`` (multiple `*.cs` files are expected)
2. If the model only returns one block, save it as ``code\generated-code.cs``
3. Save non-code outputs (plans/docs/design notes) under ``docs\`` or ``plans\`` inside the same model folder
4. Record metrics in: ``metrics.json`` (see template below)
5. Add any observations to: ``observations.md``
6. Keep ``reasoningModeApplied`` honest: set it to ``true`` only if you actually changed/verified the client reasoning setting for this run.
7. Save any transcript/screenshots/CLI captures under: ``logs\``

### Metrics Template (metrics.json)
``````json
{
  "llmName": "$($Llm.Name)",
  "llmModel": "$($Llm.Model)",
  "baseModelName": "$($Llm.BaseModelName)",
  "baseModelId": "$($Llm.BaseModelId)",
  "modelVariantId": "$($Llm.Model)",
  "reasoningMode": $(if ($Llm.ReasoningMode) { '"' + $Llm.ReasoningMode + '"' } else { 'null' }),
  "codexReasoningEffort": $(if ($Llm.CodexReasoningEffort) { '"' + $Llm.CodexReasoningEffort + '"' } else { 'null' }),
  "reasoningModeApplied": false,
  "category": "$($Llm.Category)",
  "testPromptId": "$($SelectedPrompt.Id)",
  "startTime": "YYYY-MM-DD HH:mm:ss",
  "endTime": "YYYY-MM-DD HH:mm:ss",
  "durationSeconds": 0,
  "requestCount": 1,
  "totalCost": $($Llm.CostPerRequest),
  "responseCompleteness": "complete|partial|failed",
  "codeQuality": {
    "compilable": true,
    "followsBestPractices": true,
    "hasProperErrorHandling": true,
    "hasDocumentation": true,
    "usesModernFeatures": true
  },
  "observations": ""
}
``````

### Step 4: Code Quality Review
Review the generated code for:
- [ ] Compiles without errors
- [ ] Follows C# 14 / .NET 10 best practices
- [ ] Implements all required features
- [ ] Has proper error handling
- [ ] Has XML documentation
- [ ] Uses async/await correctly
- [ ] Has proper validation
- [ ] Follows naming conventions
- [ ] Is well-structured and maintainable
- [ ] Has no security issues

## Notes
- Take your time to thoroughly review the code
- Document any issues or exceptional features
- Compare against the requirements in the prompt
- When a reasoning mode is present, this benchmark target already has its own folder named ``$((Get-ResultFolderName -BaseModelId $Llm.BaseModelId -ReasoningMode $Llm.ReasoningMode))``
"@
}

function Invoke-ManualTest {
  param(
    [Parameter(Mandatory)]
    [object]$Llm,

    [Parameter(Mandatory)]
    [string]$SessionPath,

    [Parameter(Mandatory)]
    [object]$SelectedPrompt
  )

  $llmResultPath = Join-Path $SessionPath (Get-ResultFolderName -BaseModelId $Llm.BaseModelId -ReasoningMode $Llm.ReasoningMode)
  New-DirectoryIfMissing -Path $llmResultPath
  New-DirectoryIfMissing -Path (Join-Path $llmResultPath 'code')
  New-DirectoryIfMissing -Path (Join-Path $llmResultPath 'docs')
  New-DirectoryIfMissing -Path (Join-Path $llmResultPath 'plans')
  New-DirectoryIfMissing -Path (Join-Path $llmResultPath 'logs')

  $instructionsPath = Join-Path $llmResultPath 'TEST-INSTRUCTIONS.md'
  $instructions = New-TestInstructions -Llm $Llm -SelectedPrompt $SelectedPrompt
  Set-TextContent -Path $instructionsPath -Value $instructions

  Write-Host "  Instructions saved to: $llmResultPath" -ForegroundColor Green
  Write-Host '  Please complete the test manually and press Enter when done...' -ForegroundColor Cyan
  Read-Host '  Press Enter to continue' | Out-Null

  $metricsPath = Join-Path $llmResultPath 'metrics.json'
  if (Test-Path $metricsPath) {
    Write-Host '  ✓ Results collected' -ForegroundColor Green
    return Get-Content $metricsPath -Raw | ConvertFrom-Json
  }

  Write-Warning '  Metrics file not found. Skipping...'
  return $null
}

function Show-SessionStart {
  param(
    [Parameter(Mandatory)]
    [string]$Timestamp,

    [Parameter(Mandatory)]
    [string]$SessionPath
  )

  Write-Host "`n========================================" -ForegroundColor Magenta
  Write-Host '  LLM Testing Session Started' -ForegroundColor Magenta
  Write-Host '========================================' -ForegroundColor Magenta
  Write-Host "Session: $Timestamp" -ForegroundColor Yellow
  Write-Host "Results: $SessionPath" -ForegroundColor Yellow
  Write-Host ''
}

function Show-Completion {
  param(
    [Parameter(Mandatory)]
    [string]$SessionPath
  )

  Write-Host "`n========================================" -ForegroundColor Magenta
  Write-Host '  All Tests Complete!' -ForegroundColor Magenta
  Write-Host '========================================' -ForegroundColor Magenta
  Write-Host "`nResults saved to: $SessionPath" -ForegroundColor Yellow
  Write-Host "`nNext steps:" -ForegroundColor Cyan
  Write-Host '  1. Review all generated code' -ForegroundColor White
  Write-Host "  2. Run: .\Invoke-LLMAnalysis.ps1 -SessionPath '$SessionPath'" -ForegroundColor White
  Write-Host '  3. Review the generated comparison report' -ForegroundColor White
  Write-Host ''
}

$paths = Get-Paths
Initialize-ResultsDirectory -Path $paths.ResultsPath

$config = Get-Config -Path $paths.ConfigPath
$availablePrompts = Get-AvailablePrompts -PromptsPath $paths.PromptsPath
$selectedPrompt = Select-Prompt -AvailablePrompts $availablePrompts

Write-Host "`nSelected prompt: $($selectedPrompt.Id)" -ForegroundColor Green
$null = Get-PromptText -PromptPath $selectedPrompt.Path

$llmsToTest = Get-ModelsToTest -Config $config
Show-ModelsToTest -Models $llmsToTest

$session = New-TestSession -ResultsPath $paths.ResultsPath -SelectedPrompt $selectedPrompt -Config $config -Models $llmsToTest
Show-SessionStart -Timestamp $session.Timestamp -SessionPath $session.SessionPath

$results = @()
$testNumber = 0

foreach ($llm in $llmsToTest) {
  $testNumber++
  Write-Host "`n[$testNumber/$($llmsToTest.Count)] Testing: $($llm.Name)" -ForegroundColor Yellow
  Write-Host ('=' * 60) -ForegroundColor Gray

  $metrics = Invoke-ManualTest -Llm $llm -SessionPath $session.SessionPath -SelectedPrompt $selectedPrompt
  if ($metrics) {
    $results += $metrics
  }
}

Show-Completion -SessionPath $session.SessionPath

if ($results.Count -gt 0) {
  Set-JsonContent -Path (Join-Path $session.SessionPath 'all-results.json') -Value $results
  Write-Host 'Consolidated results saved to: all-results.json' -ForegroundColor Green
}




