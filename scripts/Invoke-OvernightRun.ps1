#Requires -Version 7.0
<#
.SYNOPSIS
    Invokes overnight feature execution based on overnight-config.json.

.DESCRIPTION
    For each feature, creates a git worktree, parses tasks.md, invokes Copilot CLI per task,
    runs build/test gates, commits after each completed phase, and produces a summary report.

.PARAMETER ConfigPath
    Path to overnight-config.json relative to repo root.

.PARAMETER DryRun
    If set, prints what would happen without invoking Copilot or build/test commands.
#>

[CmdletBinding()]
param(
  [string]$ConfigPath = "overnight-config.json",
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$configFullPath = Join-Path $repoRoot $ConfigPath
$parseTasksScript = Join-Path $PSScriptRoot "ConvertFrom-TasksFile.ps1"

if (-not (Test-Path $configFullPath -PathType Leaf)) {
  throw "Config not found: $configFullPath"
}
if (-not (Test-Path $parseTasksScript -PathType Leaf)) {
  throw "Missing ConvertFrom-TasksFile.ps1: $parseTasksScript"
}

$config = Get-Content $configFullPath -Raw | ConvertFrom-Json
if (-not $config.features -or $config.features.Count -eq 0) {
  Write-Host "No features registered. Use Register-Feature.ps1 first." -ForegroundColor Yellow
  return
}

$logsRoot = Join-Path $repoRoot $config.logsDir
New-Item -ItemType Directory -Path $logsRoot -Force | Out-Null

function Invoke-ProcessWithTimeout {
  param(
    [Parameter(Mandatory)] [string]$FilePath,
    [Parameter(Mandatory)] [string[]]$ArgumentList,
    [Parameter(Mandatory)] [string]$WorkingDirectory,
    [Parameter(Mandatory)] [int]$TimeoutMinutes,
    [Parameter(Mandatory)] [string]$LogFile
  )

  $process = Start-Process -FilePath $FilePath `
    -ArgumentList $ArgumentList `
    -WorkingDirectory $WorkingDirectory `
    -NoNewWindow -PassThru `
    -RedirectStandardOutput $LogFile `
    -RedirectStandardError $LogFile

  $timeoutMs = [Math]::Max(1, $TimeoutMinutes) * 60 * 1000
  $exited = $process.WaitForExit($timeoutMs)

  if (-not $exited) {
    try { $process.Kill($true) } catch { }
    return [PSCustomObject]@{ ExitCode = 124; TimedOut = $true }
  }

  return [PSCustomObject]@{ ExitCode = $process.ExitCode; TimedOut = $false }
}

function Update-TaskCompletion {
  param(
    [Parameter(Mandatory)] [string]$TasksFile,
    [Parameter(Mandatory)] [string]$TaskId
  )

  $lines = Get-Content -Path $TasksFile -Encoding utf8
  $pattern = "^\s*-\s+\[ \]\s+.*\[$TaskId\]"

  $updated = $lines | ForEach-Object {
    if ($_ -match $pattern) {
      return $_ -replace "\[ \]", "[x]"
    }
    return $_
  }

  $updated | Set-Content -Path $TasksFile -Encoding utf8
}

function SafePathSegment {
  param([string]$Value)
  return ($Value -replace '[^a-zA-Z0-9-_]', '_')
}

$parallelEnabled = [bool]$config.parallelTasksEnabled
$maxParallelTasks = if ($config.maxParallelTasks) { [int]$config.maxParallelTasks } else { 1 }
$parallelGuard = if ($config.parallelTaskGuard) { [string]$config.parallelTaskGuard } else { "category" }
$parallelTaskMatrix = $config.parallelTaskMatrix
$taskBranchesEnabled = [bool]$config.taskBranchesEnabled
$taskBranchPrefix = if ($config.taskBranchPrefix) { [string]$config.taskBranchPrefix } else { "task/" }
$taskBranchMergeStrategy = if ($config.taskBranchMergeStrategy) { [string]$config.taskBranchMergeStrategy } else { "squash" }
$taskBranchCleanup = if ($null -ne $config.taskBranchCleanup) { [bool]$config.taskBranchCleanup } else { $true }

$overallWatch = [System.Diagnostics.Stopwatch]::StartNew()
$summary = [ordered]@{
  date       = (Get-Date -Format "yyyy-MM-dd")
  features   = @()
  modelUsage = [ordered]@{}
  totals     = [ordered]@{
    completed          = 0
    failed             = 0
    skipped            = 0
    runtime            = "0m"
    estimatedCost      = 0
    budgetDollars      = $config.totalBudgetDollars
    premiumRequests    = 0
    maxPremiumRequests = $config.maxPremiumRequests
  }
}

function Get-ModelMultiplier {
  param([string]$Model)
  if ($config.modelMultipliers -and $config.modelMultipliers.PSObject.Properties[$Model]) {
    return [double]$config.modelMultipliers.PSObject.Properties[$Model].Value
  }
  return 1
}

function Is-PremiumModel {
  param([string]$Model)
  if ($config.premiumModels) {
    return ($config.premiumModels -contains $Model)
  }
  return ($Model -notmatch 'mini')
}

function Register-ModelUse {
  param([string]$Model)

  if (-not $summary.modelUsage.Contains($Model)) {
    $summary.modelUsage[$Model] = 0
  }
  $summary.modelUsage[$Model]++
  $summary.totals.estimatedCost += (Get-ModelMultiplier -Model $Model)

  if (Is-PremiumModel -Model $Model) {
    $summary.totals.premiumRequests++
  }
}

function Can-AddParallelTask {
  param(
    [Parameter(Mandatory)] $Task,
    [Parameter(Mandatory)] $Batch,
    [Parameter(Mandatory)] [string]$GuardMode,
    [ref]$WarnedPathGuard
  )

  function Normalize-PathHint {
    param([string]$Value)
    $normalized = $Value -replace '\\', '/'
    $normalized = $normalized.Trim().Trim('/')
    return $normalized.ToLowerInvariant()
  }

  function PathsOverlap {
    param([string]$Left, [string]$Right)
    return ($Left.StartsWith($Right) -or $Right.StartsWith($Left))
  }

  if ($GuardMode -eq "category") {
    return (-not ($Batch | Where-Object { $_.Category -eq $Task.Category }))
  }

  if ($GuardMode -eq "path-locks") {
    if (-not $WarnedPathGuard.Value) {
      Write-Host "parallelTaskGuard 'path-locks' is not implemented. Falling back to sequential." -ForegroundColor Yellow
      $WarnedPathGuard.Value = $true
    }
    return $false
  }

  if ($GuardMode -eq "category-path-matrix") {
    if (-not $parallelTaskMatrix) {
      return $false
    }

    $taskPaths = @()
    if ($Task.PathHints) {
      $taskPaths = $Task.PathHints | ForEach-Object { Normalize-PathHint -Value $_ }
    }

    if ($taskPaths.Count -eq 0) {
      return $false
    }

    $taskRule = $parallelTaskMatrix.$($Task.Category)
    if (-not $taskRule) {
      return $false
    }

    $allowedCategories = @()
    if ($taskRule.allowedCategories) { $allowedCategories = @($taskRule.allowedCategories) }
    $allowedRoots = @()
    if ($taskRule.pathRoots) { $allowedRoots = @($taskRule.pathRoots) }
    $allowedRoots = $allowedRoots | ForEach-Object { Normalize-PathHint -Value $_ }

    if ($allowedRoots.Count -eq 0) {
      return $false
    }

    foreach ($path in $taskPaths) {
      if (-not ($allowedRoots | Where-Object { $path.StartsWith($_) })) {
        return $false
      }
    }

    foreach ($entry in $Batch) {
      $entryTask = $entry.Task
      $entryRule = $parallelTaskMatrix.$($entryTask.Category)
      if (-not $entryRule) {
        return $false
      }

      $entryAllowed = @()
      if ($entryRule.allowedCategories) { $entryAllowed = @($entryRule.allowedCategories) }
      $entryRoots = @()
      if ($entryRule.pathRoots) { $entryRoots = @($entryRule.pathRoots) }
      $entryRoots = $entryRoots | ForEach-Object { Normalize-PathHint -Value $_ }
      if ($allowedCategories -notcontains $entryTask.Category) { return $false }
      if ($entryAllowed -notcontains $Task.Category) { return $false }

      $entryPaths = @()
      if ($entryTask.PathHints) {
        $entryPaths = $entryTask.PathHints | ForEach-Object { Normalize-PathHint -Value $_ }
      }

      if ($entryPaths.Count -eq 0) {
        return $false
      }

      if ($entryRoots.Count -eq 0) {
        return $false
      }

      foreach ($path in $entryPaths) {
        if (-not ($entryRoots | Where-Object { $path.StartsWith($_) })) {
          return $false
        }
      }

      foreach ($left in $taskPaths) {
        foreach ($right in $entryPaths) {
          if (PathsOverlap -Left $left -Right $right) {
            return $false
          }
        }
      }
    }

    return $true
  }

  return $false
}

$stopAll = $false

foreach ($feature in $config.features) {
  if ($stopAll) { break }
  if (-not $feature.specDir -or -not $feature.branch) {
    Write-Host "Feature is missing specDir or branch. Skipping." -ForegroundColor Yellow
    continue
  }

  $featureWatch = [System.Diagnostics.Stopwatch]::StartNew()
  $featureSegment = SafePathSegment -Value $feature.branch
  $featureLogDir = Join-Path $logsRoot $featureSegment
  New-Item -ItemType Directory -Path $featureLogDir -Force | Out-Null

  $worktreeBase = Join-Path $repoRoot $config.worktreeDir
  New-Item -ItemType Directory -Path $worktreeBase -Force | Out-Null

  $worktreePath = Join-Path $worktreeBase ("overnight-" + ($feature.branch -replace '^feature/', ''))

  if (-not (Test-Path $worktreePath)) {
    if ($DryRun) {
      Write-Host "[DryRun] git worktree add $worktreePath $($feature.branch)"
    }
    else {
      & git worktree add $worktreePath $feature.branch
    }
  }

  $specDirPath = Join-Path $worktreePath $feature.specDir
  $specFile = Join-Path $specDirPath "spec.md"
  $planFile = Join-Path $specDirPath "plan.md"
  $tasksFile = Join-Path $specDirPath "tasks.md"

  if (-not (Test-Path $tasksFile -PathType Leaf)) {
    Write-Host "Missing tasks.md for feature: $($feature.specDir)" -ForegroundColor Yellow
    continue
  }

  Push-Location $worktreePath

  $tasks = & $parseTasksScript -TasksFile $tasksFile
  $committedPhases = [System.Collections.Generic.HashSet[string]]::new()
  $featureSummary = [ordered]@{
    specDir      = $feature.specDir
    branch       = $feature.branch
    worktreePath = $worktreePath
    tasks        = @()
    completed    = 0
    failed       = 0
    skipped      = 0
    draftPrUrl   = $null
  }

  $featureBranch = $feature.branch
  $warnedPathGuard = $false
  $tasksToRun = $tasks | Where-Object { -not $_.IsComplete }
  $parallelBatch = @()
  $currentPhase = $null

  function Add-SkippedTask {
    param(
      [Parameter(Mandatory)] $Task,
      [string]$LogFile = $null
    )

    $featureSummary.tasks += [ordered]@{
      id          = $Task.Id
      category    = $Task.Category
      description = $Task.Description
      status      = "Skipped"
      log         = $LogFile
    }
    $featureSummary.skipped++
    $summary.totals.skipped++
  }

  function Invoke-Task {
    param(
      [Parameter(Mandatory)] $Task,
      [Parameter(Mandatory)] $Mapping
    )

    if ($summary.totals.budgetDollars -and $summary.totals.estimatedCost -ge $summary.totals.budgetDollars) {
      Write-Host "Budget cap reached. Stopping overnight run." -ForegroundColor Yellow
      $script:stopAll = $true
      return
    }

    if ($summary.totals.maxPremiumRequests -and $summary.totals.premiumRequests -ge $summary.totals.maxPremiumRequests) {
      Write-Host "Premium request limit reached. Stopping overnight run." -ForegroundColor Yellow
      $script:stopAll = $true
      return
    }

    $taskLog = Join-Path $featureLogDir ("$($Task.Id).log")
    $taskRetryLog = Join-Path $featureLogDir ("$($Task.Id)-retry.log")
    $taskBetterLog = Join-Path $featureLogDir ("$($Task.Id)-better.log")

    if ($DryRun) {
      Write-Host "[DryRun] Task $($Task.Id) [$($Task.Category)] $($Task.Description)"
      Add-SkippedTask -Task $Task -LogFile $taskLog
      return
    }

    $agentPath = Join-Path $worktreePath $Mapping.agent
    $prompt = @"
You are the Overnight Orchestrator.
Task $($Task.Id) [$($Task.Category)] $($Task.Description).
Read spec: $specFile
Read plan: $planFile
Read tasks: $tasksFile
Implement only this task. Run build and tests after.
"@.Trim()

    $taskBranch = $null
    $taskBranchCreated = $false
    if ($taskBranchesEnabled) {
      $featureId = $featureBranch -replace '^feature/', ''
      $slug = SafePathSegment -Value $Task.Description
      $taskBranch = "$taskBranchPrefix$featureId-$($Task.Id)-$slug"
      if ($taskBranch.Length -gt 120) {
        $taskBranch = $taskBranch.Substring(0, 120)
      }

      & git switch $featureBranch | Out-Null
      & git show-ref --verify --quiet "refs/heads/$taskBranch" 2>$null
      if ($LASTEXITCODE -eq 0) {
        & git branch -D $taskBranch | Out-Null
      }
      & git switch -c $taskBranch | Out-Null
      $taskBranchCreated = $true
    }

    function Invoke-CopilotTask {
      param(
        [Parameter(Mandatory)] [string]$Model,
        [Parameter(Mandatory)] [string]$LogFile
      )

      $args = @(
        "-p", $prompt,
        "--model", $Model,
        "--custom-instructions", $agentPath,
        "--allow-all-tools"
      )

      foreach ($deny in $config.denyTools) {
        $args += @("--deny-tool", $deny)
      }

      return Invoke-ProcessWithTimeout `
        -FilePath "copilot" `
        -ArgumentList $args `
        -WorkingDirectory $worktreePath `
        -TimeoutMinutes $config.taskTimeoutMinutes `
        -LogFile $LogFile
    }

    $currentModel = $Mapping.overnightModel
    $taskResult = Invoke-CopilotTask -Model $currentModel -LogFile $taskLog
    Register-ModelUse -Model $currentModel

    if ($taskResult.ExitCode -ne 0 -and $config.retryOnFailure) {
      $retryResult = Invoke-CopilotTask -Model $currentModel -LogFile $taskRetryLog
      Register-ModelUse -Model $currentModel
      $taskResult = $retryResult
    }

    if ($taskResult.ExitCode -ne 0 -and $config.retryWithBetterModel) {
      if ($Mapping.daytimeModel -and $Mapping.daytimeModel -ne $currentModel) {
        if ($summary.totals.premiumRequests -lt $summary.totals.maxPremiumRequests) {
          $currentModel = $Mapping.daytimeModel
          $betterResult = Invoke-CopilotTask -Model $currentModel -LogFile $taskBetterLog
          Register-ModelUse -Model $currentModel
          $taskResult = $betterResult
        }
      }
    }

    $buildOk = $true
    if ($taskResult.ExitCode -ne 0) {
      $buildOk = $false
    }

    if ($buildOk) {
      $buildLog = Join-Path $featureLogDir ("$($Task.Id)-build.log")
      $testLog = Join-Path $featureLogDir ("$($Task.Id)-test.log")

      $buildResult = Invoke-ProcessWithTimeout `
        -FilePath "dotnet" `
        -ArgumentList @("build", "--no-incremental") `
        -WorkingDirectory $worktreePath `
        -TimeoutMinutes $config.taskTimeoutMinutes `
        -LogFile $buildLog

      $testResult = Invoke-ProcessWithTimeout `
        -FilePath "dotnet" `
        -ArgumentList @("test", "--no-build") `
        -WorkingDirectory $worktreePath `
        -TimeoutMinutes $config.taskTimeoutMinutes `
        -LogFile $testLog

      if ($buildResult.ExitCode -ne 0 -or $testResult.ExitCode -ne 0) {
        $buildOk = $false
      }

      $packageJson = Join-Path $worktreePath "package.json"
      if ($buildOk -and (Test-Path $packageJson)) {
        $feBuildLog = Join-Path $featureLogDir ("$($Task.Id)-frontend-build.log")
        $feLintLog = Join-Path $featureLogDir ("$($Task.Id)-frontend-lint.log")

        $feBuildResult = Invoke-ProcessWithTimeout `
          -FilePath "npm" `
          -ArgumentList @("run", "build") `
          -WorkingDirectory $worktreePath `
          -TimeoutMinutes $config.taskTimeoutMinutes `
          -LogFile $feBuildLog

        $feLintResult = Invoke-ProcessWithTimeout `
          -FilePath "npm" `
          -ArgumentList @("run", "lint") `
          -WorkingDirectory $worktreePath `
          -TimeoutMinutes $config.taskTimeoutMinutes `
          -LogFile $feLintLog

        if ($feBuildResult.ExitCode -ne 0 -or $feLintResult.ExitCode -ne 0) {
          $buildOk = $false
        }
      }
    }

    if ($taskBranchesEnabled -and $taskBranchCreated) {
      & git switch $featureBranch | Out-Null

      if ($buildOk) {
        if ($taskBranchMergeStrategy -eq "merge") {
          & git merge --no-ff -m "merge task $($Task.Id)" $taskBranch | Out-Null
          if ($LASTEXITCODE -ne 0) {
            $buildOk = $false
            & git merge --abort | Out-Null
          }
        }
        else {
          & git merge --squash $taskBranch | Out-Null
          if ($LASTEXITCODE -ne 0) {
            $buildOk = $false
            & git merge --abort | Out-Null
          }
          else {
            & git reset | Out-Null
          }
        }
      }

      if ($taskBranchCleanup) {
        & git branch -D $taskBranch | Out-Null
      }
    }

    if ($buildOk) {
      Update-TaskCompletion -TasksFile $tasksFile -TaskId $Task.Id
      $featureSummary.tasks += [ordered]@{
        id          = $Task.Id
        category    = $Task.Category
        description = $Task.Description
        status      = "Completed"
        log         = $taskLog
      }
      $featureSummary.completed++
      $summary.totals.completed++
    }
    else {
      $featureSummary.tasks += [ordered]@{
        id          = $Task.Id
        category    = $Task.Category
        description = $Task.Description
        status      = "Failed"
        log         = $taskLog
      }
      $featureSummary.failed++
      $summary.totals.failed++

      if ($config.revertOnFailure) {
        try {
          & git restore .
        }
        catch {
          Write-Host "Failed to revert changes for task $($Task.Id)." -ForegroundColor Yellow
        }
      }
    }

    # Commit after phase if all tasks in the phase are complete
    if ($config.commitAfterPhase -and $Task.Phase) {
      $tasksAfter = & $parseTasksScript -TasksFile $tasksFile
      $phaseOpen = $tasksAfter | Where-Object { $_.Phase -eq $Task.Phase -and -not $_.IsComplete }
      if ($phaseOpen.Count -eq 0 -and -not $committedPhases.Contains($Task.Phase)) {
        & git add -A
        & git commit -m "chore(overnight): complete $($Task.Phase) [$($Task.Id)]"
        $committedPhases.Add($Task.Phase) | Out-Null
      }
    }
  }

  function Flush-ParallelBatch {
    param([Parameter(Mandatory)] $Batch)

    foreach ($entry in $Batch) {
      if ($script:stopAll) { return }
      Invoke-Task -Task $entry.Task -Mapping $entry.Mapping
    }
  }

  foreach ($task in $tasksToRun) {
    if ($script:stopAll) { break }

    if ($null -ne $task.Phase -and $currentPhase -ne $task.Phase) {
      if ($parallelBatch.Count -gt 0) {
        Flush-ParallelBatch -Batch $parallelBatch
        $parallelBatch = @()
      }
      $currentPhase = $task.Phase
    }

    if (-not $task.Id -or -not $task.Category) {
      Add-SkippedTask -Task $task
      continue
    }

    $mapping = $config.categoryMapping.$($task.Category)
    if (-not $mapping) {
      Add-SkippedTask -Task $task
      continue
    }

    if ($parallelEnabled -and $task.IsParallel) {
      $canAdd = Can-AddParallelTask -Task $task -Batch $parallelBatch -GuardMode $parallelGuard -WarnedPathGuard ([ref]$warnedPathGuard)
      if ($canAdd -and $parallelBatch.Count -lt $maxParallelTasks) {
        $parallelBatch += [PSCustomObject]@{ Task = $task; Mapping = $mapping }
        continue
      }

      if ($parallelBatch.Count -gt 0) {
        Flush-ParallelBatch -Batch $parallelBatch
        $parallelBatch = @()
      }
    }
    else {
      if ($parallelBatch.Count -gt 0) {
        Flush-ParallelBatch -Batch $parallelBatch
        $parallelBatch = @()
      }
    }

    Invoke-Task -Task $task -Mapping $mapping
  }

  if ($parallelBatch.Count -gt 0 -and -not $script:stopAll) {
    Flush-ParallelBatch -Batch $parallelBatch
  }

  if ($config.createDraftPR) {
    try {
      $title = "feat: " + ($feature.branch -replace '^feature/', '') + " (overnight)"
      $bodyFile = Join-Path $featureLogDir "pr-body.md"
      @(
        "# Overnight Summary",
        "",
        "- Feature: $($feature.branch)",
        "- Spec: $($feature.specDir)",
        "- Completed: $($featureSummary.completed)",
        "- Failed: $($featureSummary.failed)",
        "- Skipped: $($featureSummary.skipped)",
        "- Logs: $featureLogDir"
      ) | Set-Content -Path $bodyFile -Encoding utf8

      $prUrl = & gh pr create --draft --title $title --body-file $bodyFile 2>$null
      if ($prUrl) {
        $featureSummary.draftPrUrl = $prUrl
      }
    }
    catch {
      Write-Host "Draft PR creation failed for $($feature.branch)." -ForegroundColor Yellow
    }
  }

  Pop-Location

  $featureWatch.Stop()
  $featureSummary.runtime = [string]::Format("{0}m {1}s", [int]$featureWatch.Elapsed.TotalMinutes, $featureWatch.Elapsed.Seconds)
  $summary.features += $featureSummary
}

$overallWatch.Stop()
$summary.totals.runtime = [string]::Format("{0}m {1}s", [int]$overallWatch.Elapsed.TotalMinutes, $overallWatch.Elapsed.Seconds)

$summaryPath = Join-Path $logsRoot "overnight-summary.json"
$summary | ConvertTo-Json -Depth 10 | Set-Content -Path $summaryPath -Encoding utf8

& $PSScriptRoot\New-MorningReport.ps1 -SummaryPath (Join-Path $config.logsDir "overnight-summary.json")
Write-Host "Overnight run complete. Summary: $summaryPath" -ForegroundColor Green
