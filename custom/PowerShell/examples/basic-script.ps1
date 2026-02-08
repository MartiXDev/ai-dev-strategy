<#
.SYNOPSIS
    Basic PowerShell script demonstrating best practices.

.DESCRIPTION
    This script demonstrates PowerShell 7+ best practices including:
    - Proper parameter blocks with validation
    - Pipeline support
    - Error handling
    - Cross-platform compatibility
    - Comment-based help

.PARAMETER Name
    One or more names to process. Accepts pipeline input.

.PARAMETER Path
    Output path for the report. Defaults to current directory.

.PARAMETER Format
    Output format: JSON, CSV, or Text.

.EXAMPLE
    .\basic-script.ps1 -Name "Alice" -Format JSON
    
    Processes a single name and outputs JSON format.

.EXAMPLE
    "Alice", "Bob", "Charlie" | .\basic-script.ps1 -Path C:\Reports -Format CSV
    
    Processes multiple names from pipeline and saves as CSV.

.NOTES
    Author: PowerShell Expert System
    Version: 1.0.0
    Requires: PowerShell 7+
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Name,
    
    [Parameter()]
    [ValidateScript({ Test-Path $_ -IsValid })]
    [string]$Path = (Get-Location),
    
    [Parameter()]
    [ValidateSet('JSON', 'CSV', 'Text')]
    [string]$Format = 'Text',
    
    [Parameter()]
    [switch]$Force
)

begin {
    # One-time initialization
    $ErrorActionPreference = 'Stop'
    Write-Verbose "Starting $($MyInvocation.MyCommand.Name)"
    Write-Verbose "Output format: $Format"
    Write-Verbose "Output path: $Path"
    
    # Cross-platform path handling
    $outputPath = Join-Path $Path "report-$(Get-Date -Format 'yyyyMMdd-HHmmss').$($Format.ToLower())"
    
    # Initialize results collection
    $results = [System.Collections.Generic.List[object]]::new()
}

process {
    # Per-record processing (runs for each pipeline input)
    foreach ($n in $Name) {
        Write-Verbose "Processing: $n"
        
        try {
            if ($PSCmdlet.ShouldProcess($n, "Process name")) {
                # Simulate processing
                $result = [PSCustomObject]@{
                    Name = $n
                    ProcessedAt = Get-Date
                    Status = 'Success'
                    Length = $n.Length
                    Platform = if ($IsWindows) { 'Windows' } 
                              elseif ($IsLinux) { 'Linux' } 
                              elseif ($IsMacOS) { 'macOS' } 
                              else { 'Unknown' }
                }
                
                $results.Add($result)
                
                # Output to pipeline for immediate consumption
                Write-Output $result
            }
        }
        catch {
            Write-Error "Failed to process '$n': $_"
            
            # Add error result but continue processing
            $errorResult = [PSCustomObject]@{
                Name = $n
                ProcessedAt = Get-Date
                Status = 'Failed'
                Error = $_.Exception.Message
            }
            $results.Add($errorResult)
        }
    }
}

end {
    # One-time cleanup and summary
    Write-Verbose "Processed $($results.Count) items"
    
    if ($results.Count -eq 0) {
        Write-Warning "No results to save"
        return
    }
    
    try {
        # Save results in specified format
        switch ($Format) {
            'JSON' {
                $results | ConvertTo-Json -Depth 5 | Set-Content -Path $outputPath -Force:$Force
            }
            'CSV' {
                $results | Export-Csv -Path $outputPath -NoTypeInformation -Force:$Force
            }
            'Text' {
                $results | Format-Table -AutoSize | Out-String | Set-Content -Path $outputPath -Force:$Force
            }
        }
        
        Write-Verbose "Report saved to: $outputPath"
        
        # Return file info
        Get-Item $outputPath
    }
    catch {
        Write-Error "Failed to save report: $_"
        throw
    }
    finally {
        Write-Verbose "Completed $($MyInvocation.MyCommand.Name)"
    }
}
