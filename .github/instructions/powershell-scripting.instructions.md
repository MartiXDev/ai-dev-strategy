---
description: 'PowerShell 7+ scripting conventions and best practices for automation, modules, and cmdlet development'
applyTo: '**/*.ps1, **/*.psm1, **/*.psd1, **/*.cs (in PowerShell module context)'
---

# PowerShell 7+ Scripting Excellence

You write production-quality PowerShell 7+ scripts for cross-platform automation (Windows, Linux, macOS). Follow these conventions for consistency, maintainability, and PowerShell best practices.

## Script Structure

### Script Template
```powershell
<#
.SYNOPSIS
    Brief description of what the script does.

.DESCRIPTION
    Detailed description of the script's functionality.

.PARAMETER Name
    Description of the parameter.

.EXAMPLE
    .\Script-Name.ps1 -Name "Example"
    Description of what this example does.

.NOTES
    Author: Your Name
    Version: 1.0.0
    Requires: PowerShell 7+
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,
    
    [Parameter()]
    [string]$Path = (Get-Location),
    
    [Parameter()]
    [switch]$Force
)

begin {
    # One-time initialization
    $ErrorActionPreference = 'Stop'
    Write-Verbose "Starting $($MyInvocation.MyCommand.Name)"
}

process {
    # Per-record processing (runs for each pipeline input)
    try {
        if ($PSCmdlet.ShouldProcess($Name, "Perform operation")) {
            # Main logic here
        }
    }
    catch {
        Write-Error "Failed to process $Name: $_"
    }
}

end {
    # One-time cleanup and summary
    Write-Verbose "Completed $($MyInvocation.MyCommand.Name)"
}
```

## Naming Conventions

### Use Approved Verbs Only
- Run `Get-Verb` to see approved verbs
- Common: `Get`, `Set`, `New`, `Remove`, `Add`, `Clear`, `Copy`, `Move`, `Find`, `Test`
- ✅ `Get-UserData`, `Set-Configuration`, `New-Report`
- ❌ `Retrieve-UserData`, `Change-Configuration`, `Create-Report`

### Verb-Noun Format
- Functions and cmdlets: `Verb-SingularNoun` (e.g., `Get-Process`, not `Get-Processes`)
- Use Pascal casing: `Get-AzureResource`, not `get-azureresource`
- Prefix custom nouns to avoid conflicts: `Get-CompanyUser`, not `Get-User`

### Variables and Parameters
- Use descriptive names with Pascal casing for parameters: `$ComputerName`, `$FilePath`
- Use camel casing for internal variables: `$userCount`, `$tempFile`
- Avoid single-letter variables except in very short scopes (`foreach ($item in $items)`)

## Parameter Blocks

### Always Use [CmdletBinding()]
```powershell
[CmdletBinding(
    SupportsShouldProcess,           # Enables -WhatIf and -Confirm
    ConfirmImpact = 'Medium',        # High, Medium, Low, None
    DefaultParameterSetName = 'Default'
)]
param(...)
```

### Parameter Best Practices
```powershell
# Required parameter with validation
[Parameter(Mandatory, ValueFromPipeline, Position = 0)]
[ValidateNotNullOrEmpty()]
[string]$Name

# Optional with default value
[Parameter()]
[ValidateSet('Windows', 'Linux', 'macOS')]
[string]$Platform = 'Windows'

# Switch parameter (boolean flag)
[Parameter()]
[switch]$Force

# Parameter with validation
[Parameter()]
[ValidateRange(1, 100)]
[int]$Count = 10

# Parameter with pattern validation
[Parameter()]
[ValidatePattern('^\d{3}-\d{2}-\d{4}$')]
[string]$SSN

# Parameter with script validation
[Parameter()]
[ValidateScript({ Test-Path $_ })]
[string]$FilePath

# Pipeline by property name
[Parameter(ValueFromPipelineByPropertyName)]
[Alias('CN', 'MachineName')]
[string]$ComputerName
```

### Validation Attributes
- `[ValidateNotNull()]` - Parameter cannot be null
- `[ValidateNotNullOrEmpty()]` - Parameter cannot be null or empty
- `[ValidateCount(min, max)]` - Validate array/collection count
- `[ValidateLength(min, max)]` - Validate string length
- `[ValidateRange(min, max)]` - Validate numeric range
- `[ValidatePattern('regex')]` - Validate against regex
- `[ValidateSet('A', 'B', 'C')]` - Validate against set of values
- `[ValidateScript({ script })]` - Custom validation logic

## Pipeline Support

### Accept Pipeline Input
```powershell
[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline)]
    [string[]]$Name
)

process {
    # This block runs once per pipeline input
    foreach ($n in $Name) {
        # Process each name
        Write-Output "Processing: $n"
    }
}
```

### Pipeline by Property Name
```powershell
[Parameter(ValueFromPipelineByPropertyName)]
[string]$ComputerName

# Enables: Get-ADComputer | Your-Function
# Matches property names automatically
```

## Error Handling

### Use Try-Catch-Finally
```powershell
$ErrorActionPreference = 'Stop'  # Convert non-terminating errors to terminating

try {
    $result = Get-Content $Path -ErrorAction Stop
    # Process result
}
catch [System.IO.FileNotFoundException] {
    Write-Error "File not found: $Path"
}
catch {
    Write-Error "Unexpected error: $_"
    Write-Verbose $_.ScriptStackTrace
}
finally {
    # Always executes (cleanup code)
    if ($resource) { $resource.Dispose() }
}
```

### Error Action Preference
```powershell
# Script level (affects all commands in script)
$ErrorActionPreference = 'Stop'      # Terminating errors
$ErrorActionPreference = 'Continue'  # Default - display error and continue
$ErrorActionPreference = 'SilentlyContinue'  # Suppress errors

# Per-command
Get-Content $Path -ErrorAction Stop
Get-Item $Path -ErrorAction SilentlyContinue
```

### Write Output Methods
```powershell
Write-Output "Normal output"        # To pipeline (use for actual output)
Write-Host "Console only"           # To console (avoid in functions)
Write-Verbose "Detailed info"       # With -Verbose
Write-Debug "Debug info"            # With -Debug
Write-Warning "Warning message"     # Always shown
Write-Error "Error message"         # Error stream
Write-Information "Info message"    # Information stream
```

### Terminating vs Non-Terminating Errors
```powershell
# Non-terminating (continues execution)
Write-Error "This is a non-terminating error"

# Terminating (stops execution)
throw "This is a terminating error"
$PSCmdlet.ThrowTerminatingError($errorRecord)
```

## ShouldProcess for Destructive Operations

```powershell
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [string]$Path
)

process {
    if ($PSCmdlet.ShouldProcess($Path, "Delete file")) {
        Remove-Item $Path -Force
    }
}

# Enables:
# Remove-MyFile -Path "file.txt" -WhatIf  # Shows what would happen
# Remove-MyFile -Path "file.txt" -Confirm # Prompts for confirmation
```

## Cross-Platform Compatibility

### Path Handling
```powershell
# ✅ Correct - cross-platform
$path = Join-Path $PSScriptRoot 'data' 'config.json'
$path = [System.IO.Path]::Combine($root, 'subdir', 'file.txt')

# ❌ Wrong - Windows-only
$path = "$PSScriptRoot\data\config.json"
$path = "C:\Users\user\file.txt"
```

### OS Detection
```powershell
if ($IsWindows) {
    # Windows-specific code
}
elseif ($IsLinux) {
    # Linux-specific code
}
elseif ($IsMacOS) {
    # macOS-specific code
}

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -ge 7) {
    # PowerShell 7+ features
}
```

### Environment Variables
```powershell
# Cross-platform
$env:USERNAME  # Windows
$env:USER      # Linux/macOS

# Use platform-agnostic approach
$currentUser = if ($IsWindows) { $env:USERNAME } else { $env:USER }
```

## Module Development

### Module Structure
```
MyModule/
├── MyModule.psd1          # Module manifest
├── MyModule.psm1          # Root module
├── Public/                # Exported functions
│   ├── Get-Something.ps1
│   └── Set-Something.ps1
├── Private/               # Internal functions
│   └── Helper.ps1
├── Classes/               # PowerShell classes
│   └── MyClass.ps1
└── en-US/                 # Help files
    └── about_MyModule.help.txt
```

### Module Manifest (.psd1)
```powershell
@{
    RootModule = 'MyModule.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
    Author = 'Your Name'
    Description = 'Module description'
    PowerShellVersion = '7.0'
    FunctionsToExport = @('Get-Something', 'Set-Something')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Automation', 'Tool')
            ProjectUri = 'https://github.com/user/repo'
        }
    }
}
```

### Root Module (.psm1)
```powershell
# Import all public functions
$Public = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)

foreach ($import in @($Public + $Private)) {
    try {
        . $import.FullName
    }
    catch {
        Write-Error "Failed to import $($import.FullName): $_"
    }
}

# Export public functions
Export-ModuleMember -Function $Public.BaseName
```

## Testing with Pester 5.x

### Test File Structure
```powershell
# MyFunction.Tests.ps1
BeforeAll {
    # Import module/function to test
    . $PSScriptRoot/../Public/Get-Something.ps1
}

Describe 'Get-Something' {
    Context 'When called with valid parameters' {
        It 'Should return expected result' {
            $result = Get-Something -Name 'Test'
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'Test'
        }
    }
    
    Context 'When called with invalid parameters' {
        It 'Should throw an error' {
            { Get-Something -Name '' } | Should -Throw
        }
    }
}
```

### Run Tests
```powershell
Invoke-Pester -Path ./Tests -Output Detailed
Invoke-Pester -Path ./Tests -CodeCoverage ./Public/*.ps1
```

## Performance Best Practices

### Use .NET Methods for Performance
```powershell
# Faster for simple operations
[System.IO.File]::ReadAllText($path)
[System.IO.Directory]::GetFiles($path, '*.txt')

# Instead of
Get-Content $path
Get-ChildItem $path -Filter '*.txt'
```

### Avoid Write-Host in Functions
```powershell
# ✅ Correct - allows redirection and pipeline
Write-Output "Message"
Write-Verbose "Verbose message"

# ❌ Wrong - writes directly to console, can't be captured
Write-Host "Message"
```

### Use String Builder for Large Strings
```powershell
$sb = [System.Text.StringBuilder]::new()
foreach ($line in $lines) {
    [void]$sb.AppendLine($line)
}
$result = $sb.ToString()
```

## Anti-Patterns to Avoid

❌ **Don't use aliases in scripts**
```powershell
# Bad
gci | % { $_.Name }

# Good
Get-ChildItem | ForEach-Object { $_.Name }
```

❌ **Don't use positional parameters (except very common ones)**
```powershell
# Bad
Get-ChildItem "C:\Temp" "*.txt"

# Good
Get-ChildItem -Path "C:\Temp" -Filter "*.txt"
```

❌ **Don't suppress errors without handling**
```powershell
# Bad
Get-Content $path -ErrorAction SilentlyContinue

# Good
$content = Get-Content $path -ErrorAction SilentlyContinue
if (-not $content) {
    Write-Warning "Could not read $path"
}
```

❌ **Don't use backticks for line continuation**
```powershell
# Bad
Get-ChildItem -Path $path `
    -Filter "*.txt" `
    -Recurse

# Good (PowerShell allows natural line breaks)
Get-ChildItem -Path $path `
    -Filter "*.txt" `
    -Recurse

# Better (use splatting for many parameters)
$params = @{
    Path = $path
    Filter = '*.txt'
    Recurse = $true
}
Get-ChildItem @params
```

❌ **Don't use `Invoke-Expression`** (security risk)
```powershell
# Bad
Invoke-Expression $userInput

# Good - use & operator or direct call
& $command $arguments
```

## Security Best Practices

### Never Trust User Input
```powershell
# Validate all input
[ValidateScript({ Test-Path $_ })]
[string]$Path

# Sanitize file paths
$safePath = [System.IO.Path]::GetFullPath($userPath)
if (-not $safePath.StartsWith($allowedRoot)) {
    throw "Invalid path"
}
```

### Use SecureString for Credentials
```powershell
[Parameter()]
[PSCredential]$Credential

# Get credential
$cred = Get-Credential -Message "Enter credentials"
```

### Avoid Hardcoded Secrets
```powershell
# ❌ Bad
$password = "P@ssw0rd123"

# ✅ Good
$password = Get-Secret -Name 'MyAppPassword' -Vault MyVault
$password = $env:MY_APP_PASSWORD  # From secure environment variable
```

## Comment-Based Help

Every exported function should have complete help:

```powershell
function Get-Something {
    <#
    .SYNOPSIS
        Brief description (one line).
    
    .DESCRIPTION
        Detailed description of what the function does, how it works,
        and any important information users should know.
    
    .PARAMETER Name
        Description of the Name parameter. Include valid values,
        defaults, and any constraints.
    
    .PARAMETER Path
        Description of the Path parameter.
    
    .EXAMPLE
        Get-Something -Name "Example"
        
        Description of what this example does and what the output looks like.
    
    .EXAMPLE
        "Item1", "Item2" | Get-Something -Verbose
        
        Shows pipeline usage with verbose output.
    
    .INPUTS
        System.String
        You can pipe strings to this function.
    
    .OUTPUTS
        System.Management.Automation.PSCustomObject
        Returns custom objects with properties X, Y, Z.
    
    .NOTES
        Additional notes, version info, or requirements.
        
    .LINK
        https://docs.example.com/Get-Something
    #>
    [CmdletBinding()]
    param(...)
    
    # Implementation
}
```

## Return Values

### Use Write-Output or Return
```powershell
# Preferred - explicit output to pipeline
Write-Output $result

# Also correct
return $result

# Implicit (last expression in function)
$result  # This gets output automatically
```

### Return Custom Objects
```powershell
# Use PSCustomObject for structured output
[PSCustomObject]@{
    Name = $name
    Status = $status
    Timestamp = Get-Date
}

# Supports: Format-Table, Select-Object, Where-Object, etc.
```

## Script Signing (Production)

For production scripts, sign with code-signing certificate:

```powershell
# Sign script
$cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert
Set-AuthenticodeSignature -FilePath .\Script.ps1 -Certificate $cert

# Verify signature
Get-AuthenticodeSignature -FilePath .\Script.ps1
```

## File Organization

- One function per file in modules
- Name files to match function names: `Get-Something.ps1`
- Keep scripts under 500 lines - refactor into modules if larger
- Use regions sparingly (only for very long scripts)

## PowerShell 7+ Features

### Ternary Operator
```powershell
$value = $condition ? 'true-value' : 'false-value'
```

### Null Coalescing
```powershell
$result = $possiblyNull ?? 'default-value'
$result ??= 'default-value'  # Assign if null
```

### Pipeline Chain Operators
```powershell
# Run second command only if first succeeds
Command1 && Command2

# Run second command only if first fails
Command1 || Command2
```

### ForEach-Object -Parallel
```powershell
1..10 | ForEach-Object -Parallel {
    Start-Sleep -Seconds 1
    "Processed $_"
} -ThrottleLimit 5
```

This ensures your PowerShell scripts are production-ready, cross-platform compatible, and follow PowerShell community best practices.
