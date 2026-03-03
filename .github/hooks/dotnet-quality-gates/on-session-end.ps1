#Requires -Version 7.0
<#
.SYNOPSIS
    Logs session end audit metadata and deterministic .NET quality gate results.

.DESCRIPTION
    Reads the sessionEnd hook payload from stdin, records session metadata, and
    runs safe non-destructive quality checks (`dotnet build` and discovered test
    projects) before appending JSON lines into logs/copilot-hooks.
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-RepositoryRoot
{
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $hooksRoot = Split-Path -Path $PSScriptRoot -Parent
    $githubRoot = Split-Path -Path $hooksRoot -Parent
    $repositoryRoot = Split-Path -Path $githubRoot -Parent
    return [System.IO.Path]::GetFullPath($repositoryRoot)
}

function Get-LogsDirectory
{
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryRoot
    )

    $logsRoot = Join-Path -Path $RepositoryRoot -ChildPath 'logs'
    return Join-Path -Path $logsRoot -ChildPath 'copilot-hooks'
}

function Get-HookPayload
{
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $rawInput = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($rawInput))
    {
        return [pscustomobject]@{}
    }

    return $rawInput | ConvertFrom-Json
}

function Get-PayloadProperty
{
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Payload,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter()]
        [object]$DefaultValue = $null
    )

    $property = $Payload.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value)
    {
        return $DefaultValue
    }

    return $property.Value
}

function Get-IsoUtcTimestamp
{
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [long]$UnixMilliseconds
    )

    return [DateTimeOffset]::FromUnixTimeMilliseconds($UnixMilliseconds).UtcDateTime.ToString('o')
}

function Get-OutputTail
{
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter()]
        [object[]]$Lines,

        [Parameter()]
        [ValidateRange(1, 200)]
        [int]$MaxLines = 25
    )

    if ($null -eq $Lines -or $Lines.Count -eq 0)
    {
        return ''
    }

    $normalizedLines = foreach ($line in $Lines)
    {
        [string]$line
    }

    return ($normalizedLines | Select-Object -Last $MaxLines) -join [Environment]::NewLine
}

function Get-RelativePath
{
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryRoot,

        [Parameter(Mandatory)]
        [string]$FullPath
    )

    return [System.IO.Path]::GetRelativePath($RepositoryRoot, $FullPath)
}

function Invoke-DotnetCommand
{
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    $commandOutput = @(& dotnet @Arguments 2>&1)
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output   = $commandOutput
    }
}

function Write-JsonLine
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [object]$Data
    )

    $jsonLine = $Data | ConvertTo-Json -Compress -Depth 20
    Add-Content -Path $Path -Value $jsonLine -Encoding utf8
}

try
{
    $payload = Get-HookPayload
    $repositoryRoot = Get-RepositoryRoot
    $logsDirectory = Get-LogsDirectory -RepositoryRoot $repositoryRoot
    New-Item -Path $logsDirectory -ItemType Directory -Force | Out-Null

    $timestampValue = Get-PayloadProperty -Payload $payload -Name 'timestamp' -DefaultValue ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())
    $timestamp = [long]$timestampValue
    $reason = [string](Get-PayloadProperty -Payload $payload -Name 'reason' -DefaultValue 'unknown')
    $workingDirectory = [string](Get-PayloadProperty -Payload $payload -Name 'cwd' -DefaultValue $repositoryRoot)

    $dotnetAvailable = $null -ne (Get-Command -Name 'dotnet' -ErrorAction SilentlyContinue)
    $buildStatus = 'skipped'
    $buildExitCode = -1
    $buildOutputTail = ''
    $buildTarget = ''

    $testStatus = 'skipped'
    $testSummary = 'Not executed.'
    $testResults = @()

    if ($dotnetAvailable)
    {
        $solutionFile = Get-ChildItem -Path $repositoryRoot -Filter '*.sln' -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '[\\/](bin|obj)[\\/]' } |
            Sort-Object -Property FullName |
            Select-Object -First 1

        if ($null -ne $solutionFile)
        {
            $buildTarget = $solutionFile.FullName
        }
        else
        {
            $projectCandidates = @(Get-ChildItem -Path $repositoryRoot -Filter '*.csproj' -File -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -notmatch '[\\/](bin|obj)[\\/]' })

            $projectFile = $projectCandidates |
                Where-Object { $_.FullName -match '[\\/]src[\\/]' } |
                Sort-Object -Property FullName |
                Select-Object -First 1

            if ($null -eq $projectFile)
            {
                $projectFile = $projectCandidates |
                    Sort-Object -Property FullName |
                    Select-Object -First 1
            }

            if ($null -ne $projectFile)
            {
                $buildTarget = $projectFile.FullName
            }
        }

        if (-not [string]::IsNullOrWhiteSpace($buildTarget))
        {
            $buildResult = Invoke-DotnetCommand -Arguments @('build', $buildTarget, '--nologo', '--verbosity', 'minimal', '--no-restore')
            $buildExitCode = [int]$buildResult.ExitCode
            $buildOutputTail = Get-OutputTail -Lines $buildResult.Output
            $buildStatus = if ($buildExitCode -eq 0) { 'passed' } else { 'failed' }
        }
        else
        {
            $buildStatus = 'skipped'
            $buildOutputTail = 'No solution or project file found.'
        }

        $testProjects = @(Get-ChildItem -Path $repositoryRoot -Filter '*.csproj' -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object {
                $_.FullName -notmatch '[\\/](bin|obj)[\\/]' -and
                ($_.FullName -match '(?i)[\\/]tests?[\\/]' -or $_.BaseName -match '(?i)test')
            } |
            Sort-Object -Property FullName)

        if ($testProjects.Count -eq 0)
        {
            $testStatus = 'skipped'
            $testSummary = 'No test projects discovered.'
        }
        elseif ($buildStatus -eq 'failed')
        {
            $testStatus = 'skipped'
            $testSummary = 'Build failed; tests skipped.'
        }
        else
        {
            $testStatus = 'passed'
            foreach ($testProject in $testProjects)
            {
                $testResult = Invoke-DotnetCommand -Arguments @('test', $testProject.FullName, '--nologo', '--verbosity', 'minimal', '--no-build', '--no-restore')
                $testExitCode = [int]$testResult.ExitCode
                if ($testExitCode -ne 0)
                {
                    $testStatus = 'failed'
                }

                $testResults += [ordered]@{
                    project    = $(Get-RelativePath -RepositoryRoot $repositoryRoot -FullPath $testProject.FullName)
                    status     = if ($testExitCode -eq 0) { 'passed' } else { 'failed' }
                    exitCode   = $testExitCode
                    outputTail = $(Get-OutputTail -Lines $testResult.Output)
                }
            }

            $testSummary = "Executed $($testResults.Count) test project(s)."
        }
    }
    else
    {
        $buildStatus = 'skipped'
        $buildOutputTail = 'dotnet CLI was not found on PATH.'
        $testStatus = 'skipped'
        $testSummary = 'dotnet CLI was not found on PATH.'
    }

    $buildTargetRelative = ''
    if (-not [string]::IsNullOrWhiteSpace([string]$buildTarget))
    {
        $buildTargetRelative = Get-RelativePath -RepositoryRoot $repositoryRoot -FullPath ([string]$buildTarget)
    }
    $qualityUtc = Get-IsoUtcTimestamp -UnixMilliseconds $timestamp

    $qualityEntry = [ordered]@{
        event        = 'sessionEndQuality'
        timestamp    = $timestamp
        utc          = $qualityUtc
        cwd          = $workingDirectory
        reason       = $reason
        dotnetFound  = $dotnetAvailable
        buildTarget  = $buildTargetRelative
        buildStatus  = $buildStatus
        buildExitCode = $buildExitCode
        buildOutputTail = $buildOutputTail
        testStatus   = $testStatus
        testSummary  = $testSummary
        testResults  = $testResults
    }

    $sessionEntry = [ordered]@{
        event          = 'sessionEnd'
        timestamp      = $timestamp
        utc            = $qualityUtc
        reason         = $reason
        cwd            = $workingDirectory
        qualityBuild   = $buildStatus
        qualityTests   = $testStatus
    }

    $qualityLogPath = Join-Path -Path $logsDirectory -ChildPath 'quality-gates.jsonl'
    $sessionLogPath = Join-Path -Path $logsDirectory -ChildPath 'session-events.jsonl'

    Write-JsonLine -Path $qualityLogPath -Data $qualityEntry
    Write-JsonLine -Path $sessionLogPath -Data $sessionEntry
}
catch
{
    Write-Warning ("on-session-end hook failed ({0}): {1}" -f $_.Exception.GetType().FullName, $_.Exception.Message)
    Write-Verbose $_.ScriptStackTrace
}

exit 0
