#Requires -Version 7.0
<#
.SYNOPSIS
    Logs session start audit metadata for Copilot CLI hooks.

.DESCRIPTION
    Reads the sessionStart hook payload from stdin and appends structured JSON
    metadata into logs/copilot-hooks/session-events.jsonl.
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
    $source = [string](Get-PayloadProperty -Payload $payload -Name 'source' -DefaultValue 'unknown')
    $workingDirectory = [string](Get-PayloadProperty -Payload $payload -Name 'cwd' -DefaultValue $repositoryRoot)
    $initialPrompt = [string](Get-PayloadProperty -Payload $payload -Name 'initialPrompt' -DefaultValue '')

    $dotnetVersion = 'not-found'
    if ($null -ne (Get-Command -Name 'dotnet' -ErrorAction SilentlyContinue))
    {
        try
        {
            $resolvedVersion = ((& dotnet --version 2>$null) | Select-Object -First 1)
            if (-not [string]::IsNullOrWhiteSpace($resolvedVersion))
            {
                $dotnetVersion = $resolvedVersion.Trim()
            }
        }
        catch
        {
            $dotnetVersion = 'error'
        }
    }

    $branchName = 'unknown'
    try
    {
        $resolvedBranch = ((& git -C $repositoryRoot rev-parse --abbrev-ref HEAD 2>$null) | Select-Object -First 1)
        if (-not [string]::IsNullOrWhiteSpace($resolvedBranch))
        {
            $branchName = $resolvedBranch.Trim()
        }
    }
    catch
    {
        $branchName = 'error'
    }

    $dirtyFileCount = 0
    try
    {
        $statusLines = @(& git -C $repositoryRoot status --porcelain 2>$null)
        $dirtyFileCount = $statusLines.Count
    }
    catch
    {
        $dirtyFileCount = -1
    }

    $entry = [ordered]@{
        event               = 'sessionStart'
        timestamp           = $timestamp
        utc                 = $(Get-IsoUtcTimestamp -UnixMilliseconds $timestamp)
        source              = $source
        cwd                 = $workingDirectory
        initialPromptLength = $initialPrompt.Length
        dotnetVersion       = $dotnetVersion
        gitBranch           = $branchName
        gitDirtyFileCount   = $dirtyFileCount
    }

    $logPath = Join-Path -Path $logsDirectory -ChildPath 'session-events.jsonl'
    Write-JsonLine -Path $logPath -Data $entry
}
catch
{
    Write-Warning "on-session-start hook failed: $($_.Exception.Message)"
}

exit 0
