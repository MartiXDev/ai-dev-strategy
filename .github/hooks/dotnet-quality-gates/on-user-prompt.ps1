#Requires -Version 7.0
<#
.SYNOPSIS
    Logs prompt-level audit metadata for Copilot CLI hooks.

.DESCRIPTION
    Reads the userPromptSubmitted payload from stdin and appends a compact
    JSON entry into logs/copilot-hooks/session-events.jsonl.
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

function Get-TextHash
{
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Text
    )

    if ([string]::IsNullOrEmpty($Text))
    {
        return 'empty'
    }

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $hashBytes = [System.Security.Cryptography.SHA256]::HashData($bytes)
    return [Convert]::ToHexString($hashBytes).ToLowerInvariant()
}

function Get-PromptPreview
{
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$PromptText
    )

    if ([string]::IsNullOrWhiteSpace($PromptText))
    {
        return ''
    }

    $normalized = ($PromptText -replace '\s+', ' ').Trim()
    if ($normalized.Length -le 180)
    {
        return $normalized
    }

    return "$($normalized.Substring(0, 180))..."
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
    $workingDirectory = [string](Get-PayloadProperty -Payload $payload -Name 'cwd' -DefaultValue $repositoryRoot)
    $promptText = [string](Get-PayloadProperty -Payload $payload -Name 'prompt' -DefaultValue '')

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

    $qualityKeywords = @('build', 'test', 'lint', 'security', 'coverage', 'format', 'quality', 'vulnerability')
    $matchedKeywords = New-Object System.Collections.Generic.List[string]
    $normalizedPrompt = $promptText.ToLowerInvariant()
    foreach ($keyword in $qualityKeywords)
    {
        if ($normalizedPrompt.Contains($keyword))
        {
            $matchedKeywords.Add($keyword)
        }
    }

    $entry = [ordered]@{
        event             = 'userPromptSubmitted'
        timestamp         = $timestamp
        utc               = $(Get-IsoUtcTimestamp -UnixMilliseconds $timestamp)
        cwd               = $workingDirectory
        promptLength      = $promptText.Length
        promptHash        = $(Get-TextHash -Text $promptText)
        promptPreview     = $(Get-PromptPreview -PromptText $promptText)
        hasQualityIntent  = $matchedKeywords.Count -gt 0
        qualityKeywords   = @($matchedKeywords | Sort-Object -Unique)
        gitDirtyFileCount = $dirtyFileCount
    }

    $logPath = Join-Path -Path $logsDirectory -ChildPath 'session-events.jsonl'
    Write-JsonLine -Path $logPath -Data $entry
}
catch
{
    Write-Warning "on-user-prompt hook failed: $($_.Exception.Message)"
}

exit 0
