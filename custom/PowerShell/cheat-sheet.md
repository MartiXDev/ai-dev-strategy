# PowerShell Quick Reference Cheat Sheet

## Approved Verbs (Most Common)

### Data Access
```powershell
Get-*     # Retrieve (paired with Set)
Set-*     # Modify/Create (paired with Get)
Read-*    # Extract info from source
Write-*   # Add info to target
```

### Modifications
```powershell
Add-*     # Add to container (paired with Remove)
Remove-*  # Delete from container
Clear-*   # Remove all but keep container
Copy-*    # Duplicate
Move-*    # Relocate
```

### Creation/Deletion
```powershell
New-*     # Create new resource
Remove-*  # Delete resource
```

### Testing & Validation
```powershell
Test-*    # Verify operation/consistency
Confirm-* # Validate state
Measure-* # Get statistics
```

### State Changes
```powershell
Start-*   # Begin async operation (paired with Stop)
Stop-*    # End operation
Enable-*  # Activate (paired with Disable)
Disable-* # Deactivate
```

### Import/Export
```powershell
Import-*  # Load from file/store (paired with Export)
Export-*  # Save to file/store
```

**Get full list**: `Get-Verb`

## Parameter Attributes

### [Parameter(...)]
```powershell
[Parameter(
    Position = 0,                          # Positional index
    Mandatory = $true,                     # Required
    ValueFromPipeline = $true,             # From pipeline object
    ValueFromPipelineByPropertyName = $true, # By property name
    ParameterSetName = "SetName",          # Parameter set
    HelpMessage = "Help text"              # Help message
)]
```

### Validation Attributes
```powershell
[ValidateNotNull()]                    # Not null
[ValidateNotNullOrEmpty()]            # Not null or empty
[ValidateCount(1, 10)]                # Array/collection size
[ValidateLength(1, 50)]               # String length
[ValidateRange(1, 100)]               # Numeric range
[ValidatePattern('^\d{3}-\d{4}$')]   # Regex pattern
[ValidateSet('A', 'B', 'C')]         # Specific values only
[ValidateScript({ Test-Path $_ })]   # Custom validation
[AllowNull()]                          # Override not-null
[AllowEmptyString()]                   # Override not-empty
[AllowEmptyCollection()]               # Override not-empty
```

### Other Parameter Attributes
```powershell
[Alias('Name1', 'Name2')]              # Alternative names
[SupportsWildcards()]                  # Accepts wildcards
```

## Function Template

```powershell
function Verb-Noun {
    <#
    .SYNOPSIS
        Brief description.
    .DESCRIPTION
        Detailed description.
    .PARAMETER Name
        Parameter description.
    .EXAMPLE
        Verb-Noun -Name "Example"
        Description of example.
    .OUTPUTS
        OutputType
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name
    )
    
    begin {
        # One-time initialization
    }
    
    process {
        # Per-record processing
        foreach ($item in $Name) {
            if ($PSCmdlet.ShouldProcess($item, "Action")) {
                # Process $item
            }
        }
    }
    
    end {
        # One-time cleanup
    }
}
```

## [CmdletBinding] Options

```powershell
[CmdletBinding(
    DefaultParameterSetName = 'Default',  # Default parameter set
    SupportsShouldProcess = $true,        # Enable -WhatIf/-Confirm
    ConfirmImpact = 'Medium',             # High/Medium/Low/None
    PositionalBinding = $true,            # Allow positional params
    HelpUri = 'https://...'               # Online help URL
)]
```

## Error Handling

### Try-Catch-Finally
```powershell
$ErrorActionPreference = 'Stop'  # Make errors terminating

try {
    # Code that might fail
}
catch [SpecificException] {
    Write-Error "Specific error: $_"
}
catch {
    Write-Error "General error: $_"
}
finally {
    # Always executes (cleanup)
}
```

### ErrorAction Values
```powershell
-ErrorAction Stop              # Terminating error
-ErrorAction Continue          # Display and continue (default)
-ErrorAction SilentlyContinue  # Suppress and continue
-ErrorAction Inquire           # Prompt user
-ErrorAction Ignore            # Completely ignore
```

### Writing Errors
```powershell
# Non-terminating (continues execution)
Write-Error "Error message"

# Terminating (stops execution)
throw "Error message"
$PSCmdlet.ThrowTerminatingError($errorRecord)
```

## Output Methods

```powershell
Write-Output "Output"         # Pipeline output
Write-Verbose "Verbose"       # -Verbose flag
Write-Debug "Debug"           # -Debug flag
Write-Warning "Warning"       # Always shown
Write-Error "Error"           # Error stream
Write-Information "Info"      # Information stream
Write-Progress -Activity "..." # Progress bar
```

## ShouldProcess Pattern

```powershell
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param([string]$Target)

process {
    if ($PSCmdlet.ShouldProcess($Target, "Delete")) {
        # Perform destructive operation
    }
}

# Usage:
# Verb-Noun -Target "File" -WhatIf   # Shows what would happen
# Verb-Noun -Target "File" -Confirm  # Prompts for confirmation
```

## Cross-Platform Paths

```powershell
# ✅ Cross-platform
$path = Join-Path $PSScriptRoot 'data' 'config.json'
$path = [System.IO.Path]::Combine($root, 'subdir', 'file.txt')

# ❌ Windows-only
$path = "$PSScriptRoot\data\config.json"
```

## OS Detection

```powershell
if ($IsWindows) { # Windows }
elseif ($IsLinux) { # Linux }
elseif ($IsMacOS) { # macOS }
```

## Module Manifest (.psd1)

```powershell
@{
    RootModule = 'Module.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
    Author = 'Name'
    Description = 'Description'
    PowerShellVersion = '7.0'
    FunctionsToExport = @('Verb-Noun')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}
```

## Binary Cmdlet (C#)

```csharp
using System.Management.Automation;

[Cmdlet(VerbsCommon.Get, "Resource")]
[OutputType(typeof(Resource))]
public class GetResourceCommand : Cmdlet
{
    [Parameter(Mandatory = true, ValueFromPipeline = true)]
    [ValidateNotNullOrEmpty()]
    public string[] Name { get; set; }
    
    protected override void ProcessRecord()
    {
        foreach (var name in Name)
        {
            try
            {
                var resource = FetchResource(name);
                WriteObject(resource);
            }
            catch (Exception ex)
            {
                var error = new ErrorRecord(
                    ex,
                    "FetchFailed",
                    ErrorCategory.InvalidOperation,
                    name
                );
                WriteError(error);
            }
        }
    }
}
```

## Pester 5.x Testing

```powershell
BeforeAll {
    . $PSScriptRoot/../MyFunction.ps1
}

Describe 'MyFunction' {
    Context 'When valid input' {
        It 'Should return expected result' {
            $result = MyFunction -Name 'Test'
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'Test'
        }
    }
    
    Context 'When invalid input' {
        It 'Should throw error' {
            { MyFunction -Name '' } | Should -Throw
        }
    }
}

# Run tests
Invoke-Pester -Path ./Tests -Output Detailed
```

## PowerShell 7+ Features

```powershell
# Ternary operator
$value = $condition ? 'true' : 'false'

# Null coalescing
$result = $var ?? 'default'
$result ??= 'default'  # Assign if null

# Pipeline chain operators
Command1 && Command2  # Run if first succeeds
Command1 || Command2  # Run if first fails

# Parallel ForEach
1..10 | ForEach-Object -Parallel {
    Process $_
} -ThrottleLimit 5
```

## Common Patterns

### Pipeline Support
```powershell
param(
    [Parameter(ValueFromPipeline)]
    [string[]]$Items
)
process {
    foreach ($item in $Items) {
        # Process each
    }
}
```

### Return Custom Objects
```powershell
[PSCustomObject]@{
    Name = $name
    Value = $value
    Timestamp = Get-Date
}
```

### Splatting Parameters
```powershell
$params = @{
    Path = $path
    Filter = '*.txt'
    Recurse = $true
}
Get-ChildItem @params
```

## Quick Checks

**Is this an approved verb?**
```powershell
Get-Verb | Where-Object Verb -EQ 'YourVerb'
```

**Analyze script quality:**
```powershell
Install-Module -Name PSScriptAnalyzer
Invoke-ScriptAnalyzer -Path .\MyScript.ps1
```

**Test module manifest:**
```powershell
Test-ModuleManifest -Path .\MyModule.psd1
```

**Get command help:**
```powershell
Get-Help Verb-Noun -Full
Get-Help Verb-Noun -Examples
Get-Help Verb-Noun -Online
```

## Anti-Patterns

❌ Don't use aliases in scripts  
❌ Don't use positional parameters (except very common)  
❌ Don't suppress errors without handling  
❌ Don't use backticks for line continuation (use natural breaks)  
❌ Don't use `Invoke-Expression`  
❌ Don't hardcode paths  
❌ Don't use `Write-Host` in functions  

## Resources

- **Approved Verbs**: `Get-Verb` or `docs/approved-verbs.md`
- **Cmdlet Docs**: `custom/PowerShell/docs/00-index.md`
- **Examples**: `custom/PowerShell/examples/`
- **Instructions**: `.github/instructions/powershell-scripting.instructions.md`
- **Agent**: `.github/agents/powershell-expert.agent.md`
