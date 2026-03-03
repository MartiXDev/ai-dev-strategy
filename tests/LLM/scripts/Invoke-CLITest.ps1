<#
.SYNOPSIS
    Executes a single LLM test via CLI (Copilot CLI or Codex CLI).

.DESCRIPTION
    This script runs a single code generation test against a specified LLM model
    using either GitHub Copilot CLI or Codex CLI. It captures timing, raw output,
    extracts code blocks, and writes structured metrics.

    Designed to be invoked from Invoke-LLMOrchestrator.ps1 as a parallel job,
    or standalone for individual model testing.

.PARAMETER ModelId
    The model identifier (e.g., "gpt-4.1", "claude-haiku-4.5").

.PARAMETER ModelName
    Human-readable display name of the model.

.PARAMETER Category
    LLM category: "free", "cheap", or "standard".

.PARAMETER PromptText
    The full prompt text to send to the CLI.

.PARAMETER PromptFile
    Path to a UTF-8 text file containing the prompt text. If provided, it overrides PromptText.

.PARAMETER PromptId
    Prompt identifier used for result aggregation (e.g., "01-crud-api-with-validation").

.PARAMETER BenchmarkProfile
    Benchmark profile label used for strategy-driven comparisons.

.PARAMETER OutputDir
    Directory where results (code, metrics, raw output) are saved.

.PARAMETER CLIType
    CLI to use: "copilot" or "codex" (default: "copilot").

.PARAMETER AgentName
  Optional Copilot chat agent name used with `--agent` when CLIType is "copilot".
  Leave empty to omit `--agent`.

.PARAMETER CostPerRequest
    Cost per request in USD (default: 0 for free models).

.PARAMETER TimeoutSeconds
    Maximum seconds to wait for CLI response (default: 1800).

.PARAMETER ShowCLIProgress
    Shows live CLI output in visible windows. When omitted, runs in passive mode
    with hidden CLI windows and log capture only.

.PARAMETER RequirementPackFiles
    Optional requirement-pack markdown files appended to the prompt contract.

.EXAMPLE
    .\Invoke-CLITest.ps1 -ModelId "gpt-4.1" -ModelName "GPT-4.1" -Category "free" `
        -PromptText "Generate a C# Web API..." -OutputDir ".\results\session\gpt-4-1"

.NOTES
    Author: LLM Comparison Framework
    Version: 1.0.0
    Requires: PowerShell 7+
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string]$ModelId,

  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string]$ModelName,

  [Parameter(Mandatory)]
  [ValidateSet('free', 'cheap', 'standard')]
  [string]$Category,

  [Parameter()]
  [string]$PromptText,

  [Parameter()]
  [string]$PromptFile,

  [Parameter()]
  [string]$PromptId = '',

  [Parameter()]
  [string]$BenchmarkProfile = 'baseline',

  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string]$OutputDir,

  [Parameter()]
  [ValidateSet('copilot', 'codex')]
  [string]$CLIType = 'copilot',

  [Parameter()]
  [AllowEmptyString()]
  [string]$AgentName = '',

  [Parameter()]
  [decimal]$CostPerRequest = 0,

  [Parameter()]
  [ValidateRange(30, 3600)]
  [int]$TimeoutSeconds = 1800,

  [Parameter()]
  [switch]$ShowCLIProgress,

  [Parameter()]
  [string[]]$RequirementPackFiles = @(),

  [Parameter()]
  [string]$TerminalWindowId
)

#Requires -Version 7.0

$ErrorActionPreference = 'Stop'
$script:CmdletContext = $PSCmdlet

function New-DirectoryIfMissing {
  param(
    [Parameter(Mandatory)]
    [string]$Path
  )

  if (-not (Test-Path $Path)) {
    New-Item -Path $Path -ItemType Directory -Force -WhatIf:$WhatIfPreference | Out-Null
  }
}

function Set-Utf8Content {
  param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory)]
    [AllowEmptyString()]
    [string]$Value
  )

  Set-Content -Path $Path -Value $Value -Encoding utf8 -WhatIf:$WhatIfPreference
}

function Add-Utf8Content {
  param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory)]
    [AllowEmptyString()]
    [string]$Value
  )

  Add-Content -Path $Path -Value $Value -Encoding utf8 -WhatIf:$WhatIfPreference
}

function Copy-FileSafe {
  param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory)]
    [string]$Destination
  )

  Copy-Item -Path $Path -Destination $Destination -Force -WhatIf:$WhatIfPreference
}

function Remove-ItemSafe {
  param(
    [Parameter(Mandatory)]
    [string]$Path
  )

  if (Test-Path $Path) {
    Remove-Item $Path -Force -ErrorAction SilentlyContinue -WhatIf:$WhatIfPreference
  }
}

function Get-ConstrainedPrompt {
  param(
    [Parameter(Mandatory)]
    [string]$PromptContent,

    [Parameter(Mandatory)]
    [string]$ModelOutputDir,

    [Parameter(Mandatory)]
    [string]$CodeOutputDir,

    [Parameter()]
    [AllowEmptyString()]
    [string]$RequirementPackText = ''
  )

  $basePrompt = @"
$PromptContent

## Output Contract (MANDATORY)
- Produce a complete **multi-file** C# implementation.
- Do NOT create files outside this model directory: $ModelOutputDir
- Put C# source files under: $CodeOutputDir
- Put non-code artifacts (design notes, plans, docs) under the same model directory, e.g. `docs/` or `plans/`.
- Do NOT use or reference repository-root folders like `src/` or `tests/` directly.
- Return **all artifacts** in this exact format:

File: <relative/path/inside/model-folder>
```<language>
...file content...
```

- Include all required C# files needed by the prompt (models, DTOs, endpoints/handlers, validators, and setup/registration files).
- Do not return prose-only answers; return file artifacts using `File:` + fenced content blocks.
- If uncertain, still provide compilable scaffold files rather than prose-only output.
"@

  if ([string]::IsNullOrWhiteSpace($RequirementPackText)) {
    return $basePrompt
  }

  return @"
$basePrompt

## Additional Requirement Packs (MANDATORY)
$RequirementPackText
"@
}

function Get-RequirementPackText {
  param(
    [Parameter(Mandatory)]
    [string[]]$PackFiles
  )

  if (-not $PackFiles -or $PackFiles.Count -eq 0) {
    return ''
  }

  $sections = [System.Collections.Generic.List[string]]::new()
  foreach ($packFile in $PackFiles) {
    if (-not (Test-Path $packFile)) {
      throw "Requirement pack file not found: $packFile"
    }

    $packName = [System.IO.Path]::GetFileName($packFile)
    $packContent = (Get-Content -Path $packFile -Raw).Trim()
    if ([string]::IsNullOrWhiteSpace($packContent)) {
      continue
    }

    $sections.Add("### Pack: $packName`n$packContent")
  }

  if ($sections.Count -eq 0) {
    return ''
  }

  return ($sections -join "`n`n")
}

function Initialize-TestContext {
  New-DirectoryIfMissing -Path $OutputDir
  $codeDir = Join-Path $OutputDir 'code'
  $logsDir = Join-Path $OutputDir 'logs'
  New-DirectoryIfMissing -Path $codeDir
  New-DirectoryIfMissing -Path $logsDir

  if ([string]::IsNullOrWhiteSpace($PromptText) -and [string]::IsNullOrWhiteSpace($PromptFile)) {
    throw 'Either -PromptText or -PromptFile must be provided.'
  }

  if (-not [string]::IsNullOrWhiteSpace($PromptFile)) {
    if (-not (Test-Path $PromptFile)) {
      throw "Prompt file not found: $PromptFile"
    }

    $script:PromptText = Get-Content -Path $PromptFile -Raw
  }
  else {
    $script:PromptText = $PromptText
  }

  $effectiveAgentName = ''
  if ($CLIType -eq 'copilot' -and -not [string]::IsNullOrWhiteSpace($AgentName)) {
    $effectiveAgentName = Resolve-CopilotAgentName -Agent $AgentName
  }

  $script:testContext = [ordered]@{
    ModelDir               = $OutputDir
    CodeDir                = $codeDir
    LogsDir                = $logsDir
    TerminalWindowId       = if (-not [string]::IsNullOrWhiteSpace($TerminalWindowId)) { $TerminalWindowId } else { $env:WT_SESSION }
    StatusPath             = Join-Path $logsDir 'instance-status.json'
    TranscriptPath         = Join-Path $logsDir 'console-transcript.log'
    InstanceLogPath        = Join-Path $logsDir 'instance-events.log'
    TempPromptPath         = Join-Path $logsDir 'prompt-input.txt'
    LatestStdoutPath       = Join-Path $logsDir 'stdout.txt'
    LatestStderrPath       = Join-Path $logsDir 'stderr.txt'
    RawOutputPath          = Join-Path $logsDir 'raw-output.txt'
    GeneratedCodePath      = Join-Path $codeDir 'generated-code.cs'
    ExtractedArtifactsPath = Join-Path $logsDir 'extracted-artifacts.json'
    MaxRetries             = 2
    RetryDelay             = 5
    AgentName              = $effectiveAgentName
  }

  $scriptDir = $PSScriptRoot
  $testRoot = Split-Path $scriptDir -Parent
  $cliConfigPath = Join-Path $testRoot 'cli-config.json'
  $requirementsRoot = Join-Path $testRoot 'requirements'

  if (Test-Path $cliConfigPath) {
    $cliConfig = Get-Content $cliConfigPath -Raw | ConvertFrom-Json

    if ($cliConfig.orchestration.maxRetries) {
      $script:testContext.MaxRetries = $cliConfig.orchestration.maxRetries
    }

    if ($cliConfig.orchestration.retryDelaySeconds) {
      $script:testContext.RetryDelay = $cliConfig.orchestration.retryDelaySeconds
    }
  }

  $resolvedRequirementPacks = @()
  if ($RequirementPackFiles -and $RequirementPackFiles.Count -gt 0) {
    foreach ($pack in $RequirementPackFiles) {
      $candidate = $pack
      if (-not [System.IO.Path]::IsPathRooted($candidate)) {
        $candidate = Join-Path $testRoot $pack
        if (-not (Test-Path $candidate)) {
          $candidate = Join-Path $requirementsRoot $pack
        }
      }

      if (-not (Test-Path $candidate)) {
        throw "Requirement pack path not found: $pack"
      }

      $resolvedRequirementPacks += (Get-Item -Path $candidate).FullName
    }
  }
  elseif (Test-Path $requirementsRoot) {
    $resolvedRequirementPacks = @(
      Get-ChildItem -Path $requirementsRoot -File -Filter '*.md' |
      Sort-Object Name |
      Select-Object -ExpandProperty FullName
    )
  }

  $requirementPackText = Get-RequirementPackText -PackFiles $resolvedRequirementPacks
  $script:PromptText = Get-ConstrainedPrompt -PromptContent $script:PromptText -ModelOutputDir $OutputDir -CodeOutputDir $codeDir -RequirementPackText $requirementPackText
  Set-Utf8Content -Path $script:testContext.TempPromptPath -Value $script:PromptText
}

function Set-InstanceStatus {
  param(
    [Parameter(Mandatory)]
    [string]$State,

    [Parameter(Mandatory)]
    [string]$Message,

    [int]$Attempt = 0,
    [int]$CliProcessId = 0
  )

  $status = [ordered]@{
    model        = $ModelName
    modelId      = $ModelId
    cliType      = $CLIType
    agentName    = $script:testContext.AgentName
    state        = $State
    message      = $Message
    attempt      = $Attempt
    cliProcessId = $CliProcessId
    updatedAt    = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')
  }

  Set-Utf8Content -Path $script:testContext.StatusPath -Value ($status | ConvertTo-Json -Depth 5)

  $safeMessage = ($Message -replace '\r?\n', ' ').Trim()
  $statusLine = '{0} | state={1} | attempt={2} | pid={3} | {4}' -f $status.updatedAt, $State, $Attempt, $CliProcessId, $safeMessage
  Add-Utf8Content -Path $script:testContext.InstanceLogPath -Value $statusLine
}

function Start-TestTranscript {
  try {
    Start-Transcript -Path $script:testContext.TranscriptPath -Force | Out-Null
    $script:transcriptStarted = $true
    Write-Verbose "Transcript started: $($script:testContext.TranscriptPath)"
  }
  catch {
    $script:transcriptStarted = $false
    Write-Warning "Failed to start transcript for $ModelName`: $($_.Exception.Message)"
  }
}

function Stop-TestTranscript {
  if ($script:transcriptStarted) {
    try {
      Stop-Transcript | Out-Null
    }
    catch {
      Write-Warning "Failed to stop transcript for $ModelName`: $($_.Exception.Message)"
    }
  }
}

function New-ResultObject {
  return [ordered]@{
    llmName              = $ModelName
    llmModel             = $ModelId
    category             = $Category
    cliType              = $CLIType
    agentName            = $script:testContext.AgentName
    benchmarkProfile     = $BenchmarkProfile
    testPromptId         = $PromptId
    startTime            = ''
    endTime              = ''
    durationSeconds      = 0
    requestCount         = 0
    totalCost            = 0
    responseCompleteness = 'pending'
    rawOutputLength      = 0
    extractedCodeLength  = 0
    generatedFiles       = @()
    codeQuality          = [ordered]@{
      compilable             = $null
      followsBestPractices   = $null
      hasProperErrorHandling = $null
      hasDocumentation       = $null
      usesModernFeatures     = $null
      overallScore           = $null
    }
    performanceMetrics   = [ordered]@{
      timeToFirstToken    = $null
      tokensPerSecond     = $null
      totalTokensEstimate = $null
    }
    strategyAlignment    = [ordered]@{
      hasSpecArtifacts                 = $null
      followsExpectedStructure         = $null
      reusesMartixPatterns             = $null
      planningImplementationContinuity = $null
      referencesSkillsOrAgents         = $null
      overallScore                     = $null
    }
    errorDetails         = $null
    observations         = ''
  }
}

function ConvertTo-EncodedCommand {
  param(
    [Parameter(Mandatory)]
    [string]$CommandText
  )

  $bytes = [System.Text.Encoding]::Unicode.GetBytes($CommandText)
  return [Convert]::ToBase64String($bytes)
}

function Get-PowerShellExecutablePath {
  if ($IsWindows) {
    return (Join-Path $PSHOME 'pwsh.exe')
  }

  return 'pwsh'
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

function Invoke-CliAttempt {
  param(
    [Parameter(Mandatory)]
    [int]$AttemptNumber
  )

  $stdoutPath = Join-Path $script:testContext.LogsDir ("stdout-attempt-{0}.txt" -f $AttemptNumber)
  $stderrPath = Join-Path $script:testContext.LogsDir ("stderr-attempt-{0}.txt" -f $AttemptNumber)
  $quotedPrompt = '"' + ($script:PromptText -replace '"', '\"') + '"'

  switch ($CLIType) {
    'copilot' {
      $argumentList = @('--prompt', $quotedPrompt, '--model', $ModelId, '--allow-all')
      if (-not [string]::IsNullOrWhiteSpace($script:testContext.AgentName)) {
        if (-not [string]::IsNullOrWhiteSpace($AgentName) -and $script:testContext.AgentName -ne $AgentName) {
          Write-Verbose "Resolved Copilot agent '$AgentName' to '$($script:testContext.AgentName)' for CLI compatibility."
        }

        $argumentList += @('--agent', $script:testContext.AgentName)
      }
      if (-not $ShowCLIProgress) {
        $argumentList += '--silent'
      }

      $processArgs = @{
        FilePath     = 'copilot'
        ArgumentList = $argumentList
      }
    }
    'codex' {
      $processArgs = @{
        FilePath     = 'codex'
        ArgumentList = @('exec', '--model', $ModelId, $quotedPrompt)
      }
    }
  }

  try {
    $resolvedCommand = Get-Command $processArgs.FilePath -ErrorAction Stop
    $resolvedPath = $resolvedCommand.Path

    if ($resolvedCommand.CommandType -eq 'ExternalScript' -or $resolvedPath -like '*.ps1') {
      $cliArguments = @($processArgs.ArgumentList)
      $processArgs.FilePath = Get-PowerShellExecutablePath
      $processArgs.ArgumentList = @('-NoLogo', '-NoProfile', '-File', $resolvedPath) + $cliArguments
    }
    elseif (-not [string]::IsNullOrWhiteSpace($resolvedPath)) {
      $processArgs.FilePath = $resolvedPath
    }
  }
  catch {
    throw "Unable to resolve executable path for '$($processArgs.FilePath)': $($_.Exception.Message)"
  }

  if ($WhatIfPreference) {
    $finalArgText = @($processArgs.ArgumentList | ForEach-Object { [string]$_ }) -join ' '
    Write-Verbose "WhatIf final CLI command: $($processArgs.FilePath) $finalArgText"
    $modeName = if ($ShowCLIProgress) { 'interactive' } else { 'passive' }
    Set-InstanceStatus -State 'running-cli' -Message "WhatIf: skipping $CLIType CLI process launch in $modeName mode. stdout=$stdoutPath stderr=$stderrPath" -Attempt $AttemptNumber -CliProcessId 0
    return [ordered]@{
      ExitCode      = 0
      CliProcessId  = 0
      StdoutPath    = $stdoutPath
      StderrPath    = $stderrPath
      RawOutput     = '[WhatIf] CLI execution skipped.'
      StderrContent = ''
    }
  }

  $workingDirectory = $script:testContext.ModelDir

  if ($ShowCLIProgress) {
    $interactiveExitPath = Join-Path $script:testContext.LogsDir ("interactive-exit-attempt-{0}.json" -f $AttemptNumber)
    Remove-ItemSafe -Path $interactiveExitPath

    $payload = @{
      command          = $processArgs.FilePath
      args             = @($processArgs.ArgumentList)
      stdoutPath       = $stdoutPath
      stderrPath       = $stderrPath
      donePath         = $interactiveExitPath
      workingDirectory = $workingDirectory
    }
    $payloadJson = $payload | ConvertTo-Json -Depth 5 -Compress
    $payloadBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($payloadJson))

    $runnerCommand = @"
`$payloadJson = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('$payloadBase64'))
`$payload = `$payloadJson | ConvertFrom-Json
if (Test-Path `$payload.workingDirectory) {
  Set-Location -Path `$payload.workingDirectory
}
`$exitCode = 1
try {
  `$captured = & `$payload.command @(`$payload.args) 2>&1 | Tee-Object -FilePath `$payload.stdoutPath
  `$errorLines = @(`$captured | Where-Object { `$_ -is [System.Management.Automation.ErrorRecord] } | ForEach-Object { `$_.ToString() })
  if (`$errorLines.Count -gt 0) {
    Set-Content -Path `$payload.stderrPath -Value (`$errorLines -join [Environment]::NewLine) -Encoding utf8
  }
  elseif (-not (Test-Path `$payload.stderrPath)) {
    Set-Content -Path `$payload.stderrPath -Value '' -Encoding utf8
  }
  `$exitCode = `$LASTEXITCODE
  if (`$null -eq `$exitCode) {
    `$exitCode = 0
  }
}
catch {
  Set-Content -Path `$payload.stderrPath -Value `$_.ToString() -Encoding utf8
  `$exitCode = 1
}
finally {
  if (-not (Test-Path `$payload.stdoutPath)) {
    Set-Content -Path `$payload.stdoutPath -Value '' -Encoding utf8
  }
  if (-not (Test-Path `$payload.stderrPath)) {
    Set-Content -Path `$payload.stderrPath -Value '' -Encoding utf8
  }

  `$donePayload = @{
    exitCode    = `$exitCode
    completedAt = (Get-Date).ToString('o')
  }
  Set-Content -Path `$payload.donePath -Value (`$donePayload | ConvertTo-Json -Depth 5) -Encoding utf8
}
exit `$exitCode
"@
    $encodedRunner = ConvertTo-EncodedCommand -CommandText $runnerCommand

    $launchArgs = @{
      FilePath         = Get-PowerShellExecutablePath
      ArgumentList     = @('-NoLogo', '-NoProfile', '-EncodedCommand', $encodedRunner)
      WorkingDirectory = $workingDirectory
      PassThru         = $true
    }
    $proc = Start-Process @launchArgs
    Set-InstanceStatus -State 'running-cli' -Message "$CLIType CLI started in interactive-window mode. stdout=$stdoutPath stderr=$stderrPath" -Attempt $AttemptNumber -CliProcessId $proc.Id

    if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) {
      Stop-Process -Id $proc.Id -ErrorAction SilentlyContinue
      throw "CLI timed out after $TimeoutSeconds seconds."
    }

    $exitCode = $proc.ExitCode
  }
  else {
    $launchArgs = @{
      FilePath               = $processArgs.FilePath
      ArgumentList           = @($processArgs.ArgumentList)
      RedirectStandardOutput = $stdoutPath
      RedirectStandardError  = $stderrPath
      WorkingDirectory       = $workingDirectory
      WindowStyle            = 'Hidden'
      PassThru               = $true
    }
  }

  if (-not $ShowCLIProgress) {
    $proc = Start-Process @launchArgs
    Set-InstanceStatus -State 'running-cli' -Message "$CLIType CLI process started in passive mode. stdout=$stdoutPath stderr=$stderrPath" -Attempt $AttemptNumber -CliProcessId $proc.Id

    if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) {
      Stop-Process -Id $proc.Id -ErrorAction SilentlyContinue
      throw "CLI timed out after $TimeoutSeconds seconds."
    }

    $exitCode = $proc.ExitCode
  }

  if (Test-Path $stdoutPath) {
    Copy-FileSafe -Path $stdoutPath -Destination $script:testContext.LatestStdoutPath
  }

  if (Test-Path $stderrPath) {
    Copy-FileSafe -Path $stderrPath -Destination $script:testContext.LatestStderrPath
  }

  $rawOutput = if (Test-Path $stdoutPath) {
    Get-Content -Path $stdoutPath -Raw -ErrorAction SilentlyContinue
  }
  else {
    ''
  }

  $stderrContent = if (Test-Path $stderrPath) {
    Get-Content -Path $stderrPath -Raw -ErrorAction SilentlyContinue
  }
  else {
    ''
  }

  return [ordered]@{
    ExitCode      = $exitCode
    CliProcessId  = if ($null -ne $proc) { $proc.Id } else { 0 }
    StdoutPath    = $stdoutPath
    StderrPath    = $stderrPath
    RawOutput     = $rawOutput
    StderrContent = $stderrContent
  }
}

function Invoke-CliWithRetry {
  $attempt = 0
  $success = $false
  $rawOutput = ''
  $startTime = $null
  $endTime = $null
  $lastError = $null

  while ($attempt -lt $script:testContext.MaxRetries -and -not $success) {
    $attempt++
    Set-InstanceStatus -State 'attempt-started' -Message 'Starting CLI attempt.' -Attempt $attempt
    Write-Verbose "Attempt $attempt of $($script:testContext.MaxRetries) for $ModelName"

    $startTime = Get-Date

    try {
      $attemptResult = Invoke-CliAttempt -AttemptNumber $attempt
      $endTime = Get-Date

      if ($attemptResult.ExitCode -ne 0) {
        throw "CLI exited with code $($attemptResult.ExitCode). Stderr: $($attemptResult.StderrContent)"
      }

      if ([string]::IsNullOrWhiteSpace($attemptResult.RawOutput)) {
        throw 'CLI returned empty output'
      }

      $rawOutput = $attemptResult.RawOutput
      $success = $true
      Set-InstanceStatus -State 'attempt-succeeded' -Message "CLI attempt succeeded. stdout=$($attemptResult.StdoutPath) stderr=$($attemptResult.StderrPath)" -Attempt $attempt -CliProcessId $attemptResult.CliProcessId
    }
    catch {
      $lastError = $_.ToString()
      Write-Warning "Attempt $attempt failed for $ModelName`: $lastError"
      Set-InstanceStatus -State 'attempt-failed' -Message "Attempt failed: $lastError" -Attempt $attempt

      if ($attempt -lt $script:testContext.MaxRetries) {
        Set-InstanceStatus -State 'retrying' -Message "Attempt failed. Retrying in $($script:testContext.RetryDelay) seconds." -Attempt $attempt
        Start-Sleep -Seconds $script:testContext.RetryDelay
      }
      else {
        Set-InstanceStatus -State 'failed' -Message "All attempts failed: $lastError" -Attempt $attempt
      }
    }
  }

  if ($null -eq $endTime) {
    $endTime = Get-Date
  }

  return [ordered]@{
    Success   = $success
    Attempt   = $attempt
    RawOutput = $rawOutput
    Error     = $lastError
    StartTime = $startTime
    EndTime   = $endTime
  }
}

function Get-ExtensionFromLanguage {
  param(
    [Parameter()]
    [string]$Language
  )

  $lang = ($Language ?? '').Trim().ToLowerInvariant()
  switch ($lang) {
    { $_ -in @('csharp', 'cs', 'c#') } { return '.cs' }
    { $_ -in @('markdown', 'md') } { return '.md' }
    { $_ -eq 'json' } { return '.json' }
    { $_ -in @('yaml', 'yml') } { return '.yml' }
    { $_ -eq 'xml' } { return '.xml' }
    { $_ -in @('txt', 'text', '') } { return '.txt' }
    default { return '.txt' }
  }
}

function Get-SafeRelativeArtifactPath {
  param(
    [Parameter(Mandatory)]
    [string]$PathCandidate,

    [Parameter(Mandatory)]
    [int]$Index,

    [Parameter()]
    [string]$LanguageHint
  )

  $normalized = ($PathCandidate -replace '\\', '/').Trim()
  $normalized = $normalized -replace '^\./', ''
  $normalized = $normalized -replace '^/+', ''
  $normalized = $normalized -replace ':', ''
  $normalized = $normalized -replace '\.\.', ''

  if ([string]::IsNullOrWhiteSpace($normalized)) {
    $normalized = "GeneratedArtifact-$Index"
  }

  if ([string]::IsNullOrWhiteSpace([System.IO.Path]::GetExtension($normalized))) {
    $normalized = $normalized + (Get-ExtensionFromLanguage -Language $LanguageHint)
  }

  $segments = $normalized.Split('/', [System.StringSplitOptions]::RemoveEmptyEntries)
  $cleanedSegments = foreach ($segment in $segments) {
    $clean = $segment -replace '[<>:"|?*]', '-'
    if ([string]::IsNullOrWhiteSpace($clean)) { 'unnamed' } else { $clean }
  }

  if ($cleanedSegments.Count -eq 0) {
    return "docs/GeneratedArtifact-$Index.txt"
  }

  $relativePath = ($cleanedSegments -join '/')
  $ext = [System.IO.Path]::GetExtension($relativePath).ToLowerInvariant()
  $hasFolder = $relativePath.Contains('/')

  if ($relativePath.ToLowerInvariant().StartsWith('logs/')) {
    $relativePath = "artifacts/$relativePath"
    $hasFolder = $true
  }

  if (-not $hasFolder) {
    if ($ext -eq '.cs') {
      $relativePath = "code/$relativePath"
    }
    else {
      $relativePath = "docs/$relativePath"
    }
  }

  return $relativePath
}

function Get-ExtractedCodeFiles {
  param(
    [Parameter(Mandatory)]
    [string]$RawOutput
  )

  $files = [System.Collections.Generic.List[object]]::new()
  $explicitPattern = '(?s)(?:^|\r?\n)(?:#+\s*)?(?:File|Path)\s*:\s*(?<path>[^\r\n`]+?)\s*\r?\n(?<fence>`{1,3})(?<lang>[^\r\n`]*)\r?\n(?<code>.*?)(?:\r?\n)\k<fence>(?=\r?\n|$)'
  $explicitMatches = [regex]::Matches($RawOutput, $explicitPattern)

  $index = 0
  foreach ($match in $explicitMatches) {
    $content = $match.Groups['code'].Value.Trim()
    if ([string]::IsNullOrWhiteSpace($content)) {
      continue
    }

    $index++
    $language = $match.Groups['lang'].Value
    $relativePath = Get-SafeRelativeArtifactPath -PathCandidate $match.Groups['path'].Value -Index $index -LanguageHint $language
    $files.Add([PSCustomObject]@{
        RelativePath = $relativePath
        Content      = $content
        Language     = $language
      })
  }

  if ($files.Count -gt 0) {
    return $files
  }

  $fencePattern = '(?s)(?<fence>`{1,3})(?<lang>[^\r\n`]*)\r?\n(?<code>.*?)(?:\r?\n)\k<fence>(?=\r?\n|$)'
  $fenceMatches = [regex]::Matches($RawOutput, $fencePattern)
  foreach ($match in $fenceMatches) {
    $content = $match.Groups['code'].Value.Trim()
    if ([string]::IsNullOrWhiteSpace($content)) {
      continue
    }

    $index++
    $language = $match.Groups['lang'].Value
    $contextStart = [Math]::Max(0, $match.Index - 250)
    $contextLength = [Math]::Min(250, $match.Index)
    $context = $RawOutput.Substring($contextStart, $contextLength)

    $pathFromContext = [regex]::Match($context, '(?im)(?:File|Path)\s*:\s*(?<path>[A-Za-z0-9_./\\-]+\.[A-Za-z0-9]+)\s*$').Groups['path'].Value
    if ([string]::IsNullOrWhiteSpace($pathFromContext)) {
      $pathFromContext = "GeneratedArtifact-$index"
    }

    $relativePath = Get-SafeRelativeArtifactPath -PathCandidate $pathFromContext -Index $index -LanguageHint $language
    $files.Add([PSCustomObject]@{
        RelativePath = $relativePath
        Content      = $content
        Language     = $language
      })
  }

  return $files
}

function Save-ExtractedCodeFiles {
  param(
    [Parameter(Mandatory)]
    [object[]]$Files
  )

  $savedFiles = [System.Collections.Generic.List[string]]::new()
  $pathCounts = @{}
  $combinedCode = [System.Collections.Generic.List[string]]::new()

  foreach ($file in $Files) {
    $candidatePath = $file.RelativePath
    $lowerKey = $candidatePath.ToLowerInvariant()
    if ($pathCounts.ContainsKey($lowerKey)) {
      $pathCounts[$lowerKey]++
      $baseName = [System.IO.Path]::GetFileNameWithoutExtension($candidatePath)
      $ext = [System.IO.Path]::GetExtension($candidatePath)
      $dir = [System.IO.Path]::GetDirectoryName($candidatePath)
      $candidatePath = if ([string]::IsNullOrWhiteSpace($dir)) {
        "{0}-{1}{2}" -f $baseName, $pathCounts[$lowerKey], $ext
      }
      else {
        [System.IO.Path]::Combine($dir, ("{0}-{1}{2}" -f $baseName, $pathCounts[$lowerKey], $ext))
      }
    }
    else {
      $pathCounts[$lowerKey] = 1
    }

    $relativeWindowsPath = $candidatePath -replace '/', '\'
    $destination = Join-Path $script:testContext.ModelDir $relativeWindowsPath
    $destinationDir = Split-Path -Path $destination -Parent
    if (-not [string]::IsNullOrWhiteSpace($destinationDir)) {
      New-DirectoryIfMissing -Path $destinationDir
    }

    Set-Utf8Content -Path $destination -Value $file.Content
    $normalizedSavedPath = ($candidatePath -replace '\\', '/')
    $savedFiles.Add($normalizedSavedPath)

    if ($normalizedSavedPath.ToLowerInvariant().EndsWith('.cs')) {
      $combinedCode.Add($file.Content)
    }
  }

  if ($combinedCode.Count -gt 0) {
    Set-Utf8Content -Path $script:testContext.GeneratedCodePath -Value ($combinedCode -join "`n`n// --- Next Code Block ---`n`n")
  }

  Set-Utf8Content -Path $script:testContext.ExtractedArtifactsPath -Value ((@($savedFiles)) | ConvertTo-Json -Depth 5)

  return [PSCustomObject]@{
    SavedFiles      = @($savedFiles)
    CombinedCode    = ($combinedCode -join "`n`n// --- Next Code Block ---`n`n")
    CombinedChars   = (($combinedCode -join '')).Length
    CSharpFileCount = (@($savedFiles | Where-Object { $_.ToLowerInvariant().EndsWith('.cs') })).Count
  }
}

function Set-CodeQualityMetrics {
  param(
    [Parameter(Mandatory)]
    [hashtable]$Result,

    [Parameter(Mandatory)]
    [string]$Code,

    [Parameter(Mandatory)]
    [double]$DurationSeconds,

    [Parameter(Mandatory)]
    [int]$RawOutputLength
  )

  $Result.codeQuality.hasDocumentation = ($Code -match '///\s*<summary>' -or $Code -match '///\s')
  $Result.codeQuality.usesModernFeatures = (
    $Code -match 'record\b' -or
    $Code -match 'required\b' -or
    $Code -match 'file\s+scoped' -or
    $Code -match 'primary\s+constructor' -or
    $Code -match 'init\b' -or
    $Code -match 'readonly\s+record'
  )
  $Result.codeQuality.hasProperErrorHandling = (
    $Code -match 'try\s*\{' -or
    $Code -match 'catch\s*\(' -or
    $Code -match 'IActionResult' -or
    $Code -match 'ProblemDetails' -or
    $Code -match 'Results?\.(BadRequest|NotFound|Problem)'
  )
  $Result.codeQuality.followsBestPractices = (
    $Code -match 'async\s+Task' -and
    $Code -match '\bawait\b' -and
    ($Code -match 'ILogger' -or $Code -match 'LogInformation|LogWarning|LogError')
  )

  $Result.performanceMetrics.totalTokensEstimate = [math]::Round($RawOutputLength / 4)
  $Result.performanceMetrics.tokensPerSecond = if ($DurationSeconds -gt 0) {
    [math]::Round($Result.performanceMetrics.totalTokensEstimate / $DurationSeconds, 1)
  }
  else {
    0
  }
}

function Set-StrategyAlignmentMetrics {
  param(
    [Parameter(Mandatory)]
    [hashtable]$Result,

    [Parameter(Mandatory)]
    [string]$Code,

    [Parameter(Mandatory)]
    [string]$RawOutput,

    [Parameter(Mandatory)]
    [string[]]$GeneratedFiles
  )

  $files = @($GeneratedFiles | ForEach-Object { ($_ ?? '').Replace('\', '/').Trim() })
  $hasPlans = @($files | Where-Object { $_.StartsWith('plans/', [System.StringComparison]::OrdinalIgnoreCase) }).Count -gt 0
  $hasDocs = @($files | Where-Object { $_.StartsWith('docs/', [System.StringComparison]::OrdinalIgnoreCase) }).Count -gt 0
  $hasFeatureCode = @($files | Where-Object { $_ -match '(?i)^code/features/' }).Count -gt 0
  $hasSpecNamedArtifacts = @($files | Where-Object { $_ -match '(?i)(spec|constitution|technical-plan|tasks)' }).Count -gt 0

  $Result.strategyAlignment.hasSpecArtifacts = ($hasPlans -or $hasSpecNamedArtifacts -or $RawOutput -match '(?i)\b(spec|constitution|technical plan|task breakdown)\b')
  $Result.strategyAlignment.followsExpectedStructure = ($hasFeatureCode -and ($hasDocs -or $hasPlans))
  $Result.strategyAlignment.reusesMartixPatterns = (
    $Code -match '(?i)\bGuard\.Against\b' -or
    $Code -match '(?i)\bResult<|Result\.' -or
    $Code -match '(?i)\bSpecification\b' -or
    $Code -match '(?i)\bSmartEnum\b' -or
    $Code -match '(?i)\bSharedKernel\b'
  )
  $Result.strategyAlignment.planningImplementationContinuity = (($hasPlans -or $hasDocs) -and @($files | Where-Object { $_ -match '(?i)^code/.*\.cs$' }).Count -gt 0)
  $Result.strategyAlignment.referencesSkillsOrAgents = (
    $RawOutput -match '(?i)\b(awesome copilot|openai skills|anthropic skills|speckit|custom agent|agent skill)\b' -or
    @($files | Where-Object { $_ -match '(?i)(skills?|agents?)' }).Count -gt 0
  )

  $strategyChecks = @(
    $Result.strategyAlignment.hasSpecArtifacts
    $Result.strategyAlignment.followsExpectedStructure
    $Result.strategyAlignment.reusesMartixPatterns
    $Result.strategyAlignment.planningImplementationContinuity
    $Result.strategyAlignment.referencesSkillsOrAgents
  )
  $Result.strategyAlignment.overallScore = ($strategyChecks | Where-Object { $_ -eq $true }).Count
}

function Write-ObservationTemplate {
  param(
    [Parameter(Mandatory)]
    [hashtable]$Result,

    [Parameter(Mandatory)]
    [double]$Duration,

    [Parameter(Mandatory)]
    [int]$Attempt
  )

  $observationsPath = Join-Path $OutputDir 'observations.md'

  if (Test-Path $observationsPath) {
    return
  }

  $generatedFiles = @($Result.generatedFiles)
  $generatedFilesSummary = if ($generatedFiles.Count -gt 0) { $generatedFiles.Count } else { 0 }
  $generatedFilesList = if ($generatedFiles.Count -gt 0) {
    ($generatedFiles | ForEach-Object { '- `' + $_ + '`' }) -join "`n"
  }
  else {
    '- _No extracted file artifacts_'
  }

  $observationsContent = @"
# Observations: $ModelName

## Auto-generated Summary

- **Model**: $ModelName ($ModelId)
- **Category**: $Category
- **CLI**: $CLIType
- **Benchmark Profile**: $BenchmarkProfile
- **Duration**: $([math]::Round($Duration, 2))s
- **Attempts**: $Attempt
- **Cost**: `$$([math]::Round($CostPerRequest * $Attempt, 6))
- **Status**: $($Result.responseCompleteness)
- **Code Length**: $($Result.extractedCodeLength) chars
- **Generated Artifacts**: $generatedFilesSummary

## Automated Quality Checks

- Documentation: $(if ($Result.codeQuality.hasDocumentation) { '✅' } else { '❌/Unknown' })
- Modern Features: $(if ($Result.codeQuality.usesModernFeatures) { '✅' } else { '❌/Unknown' })
- Error Handling: $(if ($Result.codeQuality.hasProperErrorHandling) { '✅' } else { '❌/Unknown' })
- Best Practices: $(if ($Result.codeQuality.followsBestPractices) { '✅' } else { '❌/Unknown' })

## Strategy Alignment Checks

- Spec Artifacts: $(if ($Result.strategyAlignment.hasSpecArtifacts) { '✅' } else { '❌/Unknown' })
- Expected Structure: $(if ($Result.strategyAlignment.followsExpectedStructure) { '✅' } else { '❌/Unknown' })
- MartiX Pattern Reuse: $(if ($Result.strategyAlignment.reusesMartixPatterns) { '✅' } else { '❌/Unknown' })
- Plan→Implementation Continuity: $(if ($Result.strategyAlignment.planningImplementationContinuity) { '✅' } else { '❌/Unknown' })
- Skills/Agent References: $(if ($Result.strategyAlignment.referencesSkillsOrAgents) { '✅' } else { '❌/Unknown' })

## Generated Artifact List (under model folder)

$generatedFilesList

## Manual Review Notes

> Fill in after reviewing the generated code.

### Compilation

- [ ] Code compiles without errors

### Strengths

1. _TBD_

### Weaknesses

1. _TBD_

### Overall Impression

_TBD_
"@

  Set-Utf8Content -Path $observationsPath -Value $observationsContent
}

function Save-Metrics {
  param(
    [Parameter(Mandatory)]
    [hashtable]$Result
  )

  $metricsPath = Join-Path $OutputDir 'metrics.json'
  Set-Utf8Content -Path $metricsPath -Value ($Result | ConvertTo-Json -Depth 10)
}

function Invoke-Test {
  $result = New-ResultObject

  $run = Invoke-CliWithRetry

  $result.startTime = $run.StartTime.ToString('yyyy-MM-dd HH:mm:ss.fff')
  $result.endTime = $run.EndTime.ToString('yyyy-MM-dd HH:mm:ss.fff')
  $duration = ($run.EndTime - $run.StartTime).TotalSeconds
  $result.durationSeconds = [math]::Round($duration, 3)
  $result.requestCount = $run.Attempt
  $result.totalCost = [math]::Round($CostPerRequest * $run.Attempt, 6)

  if ($run.Success) {
    $result.rawOutputLength = $run.RawOutput.Length
    Set-Utf8Content -Path $script:testContext.RawOutputPath -Value $run.RawOutput

    $extractedFiles = Get-ExtractedCodeFiles -RawOutput $run.RawOutput

    if ($extractedFiles.Count -gt 0) {
      $saveInfo = Save-ExtractedCodeFiles -Files $extractedFiles
      $result.generatedFiles = @($saveInfo.SavedFiles)
      $result.extractedCodeLength = $saveInfo.CombinedChars
      if ($saveInfo.CSharpFileCount -gt 0) {
        $result.responseCompleteness = 'complete'
        Set-CodeQualityMetrics -Result $result -Code $saveInfo.CombinedCode -DurationSeconds $duration -RawOutputLength $run.RawOutput.Length
        Set-StrategyAlignmentMetrics -Result $result -Code $saveInfo.CombinedCode -RawOutput $run.RawOutput -GeneratedFiles @($result.generatedFiles)
      }
      else {
        $result.responseCompleteness = 'partial'
        $result.observations = 'Artifacts were extracted, but no C# files were found. Review extracted files and raw output.'
        Set-StrategyAlignmentMetrics -Result $result -Code '' -RawOutput $run.RawOutput -GeneratedFiles @($result.generatedFiles)
      }
    }
    else {
      Set-Utf8Content -Path $script:testContext.GeneratedCodePath -Value $run.RawOutput
      $result.generatedFiles = @('generated-code.cs')
      $result.extractedCodeLength = $run.RawOutput.Length
      $result.responseCompleteness = 'partial'
      $result.observations = 'No parseable C# file blocks were extracted. The raw response was saved to code\generated-code.cs for manual review.'
      Set-StrategyAlignmentMetrics -Result $result -Code $run.RawOutput -RawOutput $run.RawOutput -GeneratedFiles @($result.generatedFiles)
    }
  }
  else {
    $result.responseCompleteness = 'error'
    $result.errorDetails = $run.Error
    $result.observations = "Failed after $($script:testContext.MaxRetries) attempts. Error: $($run.Error)"
  }

  Set-InstanceStatus -State $result.responseCompleteness -Message "Test finished with status '$($result.responseCompleteness)'." -Attempt $run.Attempt
  Save-Metrics -Result $result
  Write-ObservationTemplate -Result $result -Duration $duration -Attempt $run.Attempt

  Remove-ItemSafe -Path $script:testContext.TempPromptPath

  Write-Verbose "Test complete for $ModelName`: $($result.responseCompleteness) in $([math]::Round($duration, 2))s"

  return $result
}

try {
  Write-Verbose "Starting CLI test: $ModelName ($ModelId) via $CLIType"
  Initialize-TestContext
  Start-TestTranscript
  Set-InstanceStatus -State 'initialized' -Message 'Test helper initialized.'
  $finalResult = Invoke-Test
  return $finalResult
}
finally {
  Stop-TestTranscript
  Write-Verbose "Finished CLI test: $ModelName"
}
