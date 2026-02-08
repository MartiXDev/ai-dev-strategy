#Requires -Version 7.0

# Get public and private function definition files
$Public = @(Get-ChildItem -Path $PSScriptRoot/Public/*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot/Private/*.ps1 -ErrorAction SilentlyContinue)

# Dot source the files
foreach ($import in @($Public + $Private)) {
    try {
        . $import.FullName
    }
    catch {
        Write-Error "Failed to import function $($import.FullName): $_"
    }
}

# Export only public functions
Export-ModuleMember -Function $Public.BaseName

# Module variables (if needed)
$script:ModuleConfig = @{
    Version = '1.0.0'
    CachePath = Join-Path $env:TEMP 'MyModuleCache'
}

# Module initialization
Write-Verbose "MyModule v$($script:ModuleConfig.Version) loaded"
