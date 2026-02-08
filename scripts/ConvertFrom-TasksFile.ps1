#Requires -Version 7.0
<#
.SYNOPSIS
    Converts a SpecKit tasks.md file into structured task objects.

.DESCRIPTION
    Reads a tasks.md file and extracts tasks with their IDs, categories, descriptions,
    phase information, parallelization markers, completion status, and optional PATH hints.

.PARAMETER TasksFile
    Path to the tasks.md file to parse.

.OUTPUTS
    Array of PSCustomObject with properties:
    - Id: Task identifier (e.g., "T001")
    - Category: Task category (e.g., "BACKEND", "FRONTEND")
    - Description: Task description text
    - Phase: Phase number and name
    - IsParallel: Whether the task is marked with [P]
    - IsComplete: Whether the task checkbox is checked
    - UserStory: Optional user story reference (e.g., "US1")
    - PathHints: Optional list of PATH hints
    - RawLine: The original markdown line

.EXAMPLE
    $tasks = .\scripts\ConvertFrom-TasksFile.ps1 -TasksFile "specs/001-user-profile/tasks.md"
    $tasks | Where-Object { -not $_.IsComplete -and $_.Category -eq "BACKEND" }
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidateScript({ Test-Path $_ -PathType Leaf })]
  [string]$TasksFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Parse-TasksFile {
  [CmdletBinding()]
  param([string]$Path)

  $lines = Get-Content -Path $Path -Encoding utf8
  $currentPhase = ''
  $tasks = [System.Collections.Generic.List[PSCustomObject]]::new()

  # Regex patterns
  $phasePattern = '^##\s+Phase\s+(\d+)\s*[-—–]\s*(.+)$'
  $taskPattern = '^\s*-\s+\[([ xX])\]\s+(.+)$'
  $idPattern = '\[T(\d+)\]'
  $catPattern = '\[(BACKEND|FRONTEND|FULLSTACK|TEST-UNIT|TEST-INTEG|TEST-E2E|SECURITY|A11Y|DEVOPS|DOCS)\]'
  $parallelPat = '\[P\]'
  $usPattern = '\[US(\d+)\]'
  $pathPattern = '\[PATH:([^\]]+)\]'

  foreach ($line in $lines) {
    # Detect phase headers
    if ($line -match $phasePattern) {
      $currentPhase = "Phase $($Matches[1]) — $($Matches[2].Trim())"
      continue
    }

    # Detect task lines
    if ($line -match $taskPattern) {
      $isComplete = $Matches[1] -in @('x', 'X')
      $content = $Matches[2]

      # Extract task ID
      $taskId = $null
      if ($content -match $idPattern) {
        $taskId = "T$($Matches[1])"
      }

      # Extract category
      $category = $null
      if ($content -match $catPattern) {
        $category = $Matches[1]
      }

      # Check parallel marker
      $isParallel = [bool]($content -match $parallelPat)

      # Extract user story
      $userStory = $null
      if ($content -match $usPattern) {
        $userStory = "US$($Matches[1])"
      }

      # Extract path hints (optional, used for guarded parallelism)
      $pathHints = @()
      if ($content -match $pathPattern) {
        $pathRaw = $Matches[1]
        $pathHints = $pathRaw -split '[,;]'
        $pathHints = $pathHints | ForEach-Object { $_.Trim() } | Where-Object { $_ }
      }

      # Clean description — remove markers to get pure text
      $description = $content `
        -replace '\[T\d+\]\s*', '' `
        -replace '\[(BACKEND|FRONTEND|FULLSTACK|TEST-UNIT|TEST-INTEG|TEST-E2E|SECURITY|A11Y|DEVOPS|DOCS)\]\s*', '' `
        -replace '\[P\]\s*', '' `
        -replace '\[US\d+\]\s*', '' `
        -replace '\[PATH:[^\]]+\]\s*', '' |
      ForEach-Object { $_.Trim() }

      $task = [PSCustomObject]@{
        Id          = $taskId
        Category    = $category
        Description = $description
        Phase       = $currentPhase
        IsParallel  = $isParallel
        IsComplete  = $isComplete
        UserStory   = $userStory
        RawLine     = $line.Trim()
        PathHints   = $pathHints
      }

      $tasks.Add($task)
    }
  }

  return $tasks
}

# --- Main ---
$parsedTasks = Parse-TasksFile -Path $TasksFile
return $parsedTasks
