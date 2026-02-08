---
name: module-builder
description: Convert standalone PowerShell scripts into proper module structure with manifest, organized folders, and export management. Use when packaging scripts for distribution or creating organized module structure.
---

# PowerShell Module Builder

Transform standalone `.ps1` scripts into production-ready PowerShell modules with proper structure, manifest, and organization.

## When to Use

- Converting one or more standalone scripts into a distributable module
- Organizing scattered functions into a cohesive module structure
- Preparing scripts for PowerShell Gallery publication
- Creating proper module structure for team distribution
- Refactoring a collection of related scripts

**NOT for**: Designing new modules from scratch (use PowerShell Expert agent instead).

## Prerequisites

- PowerShell 7+ installed
- Existing `.ps1` script(s) with functions to modularize
- Basic understanding of module concepts (optional)

## Core Workflow

### 1. Analyze Existing Scripts

First, examine the scripts to identify:
- Function names and their purposes
- Public functions (for export) vs private helpers
- Dependencies and required modules
- PowerShell version requirements

```powershell
# Review functions in existing scripts
Get-Content .\MyScript.ps1 | Select-String "^function "
```

### 2. Create Module Directory Structure

Standard module layout:

```
MyModule/
├── MyModule.psd1          # Module manifest
├── MyModule.psm1          # Root module file
├── Public/                # Exported functions
│   ├── Get-MyData.ps1
│   └── Set-MyConfig.ps1
├── Private/               # Internal helpers
│   └── Get-Helper.ps1
├── Tests/                 # Pester tests (if using)
├── README.md
└── LICENSE
```

Create the structure:

```powershell
$moduleName = "MyModule"
$modulePath = ".\$moduleName"

# Create directories
New-Item -Path $modulePath -ItemType Directory -Force
New-Item -Path "$modulePath\Public" -ItemType Directory -Force
New-Item -Path "$modulePath\Private" -ItemType Directory -Force
New-Item -Path "$modulePath\Tests" -ItemType Directory -Force
```

### 3. Organize Functions into Public/Private

**Public** folder: Functions to be exported (user-facing API)
**Private** folder: Internal helpers (not exported)

Move each function into its own file:

```powershell
# Extract function from script
$functionContent = @'
function Get-MyData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )
    
    # Function logic here
    Write-Output "Data for $Name"
}
'@

# Save to Public folder
$functionContent | Out-File "$modulePath\Public\Get-MyData.ps1" -Encoding utf8
```

**Naming convention**: One function per file, filename matches function name.

### 4. Create Root Module File (.psm1)

The `.psm1` file imports all functions and exports public ones:

```powershell
$rootModuleContent = @'
# Import all public functions
$PublicFunctions = Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue

foreach ($import in $PublicFunctions) {
    try {
        . $import.FullName
    }
    catch {
        Write-Error "Failed to import function $($import.FullName): $_"
    }
}

# Import all private functions
$PrivateFunctions = Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue

foreach ($import in $PrivateFunctions) {
    try {
        . $import.FullName
    }
    catch {
        Write-Error "Failed to import function $($import.FullName): $_"
    }
}

# Export public functions
Export-ModuleMember -Function $PublicFunctions.BaseName
'@

$rootModuleContent | Out-File "$modulePath\$moduleName.psm1" -Encoding utf8
```

### 5. Generate Module Manifest (.psd1)

Use `New-ModuleManifest` to create the manifest:

```powershell
$manifestParams = @{
    Path              = "$modulePath\$moduleName.psd1"
    RootModule        = "$moduleName.psm1"
    ModuleVersion     = '1.0.0'
    Author            = 'Your Name'
    CompanyName       = 'Your Company'
    Description       = 'Brief description of what this module does'
    PowerShellVersion = '7.0'
    FunctionsToExport = @('Get-MyData', 'Set-MyConfig')  # List all public functions
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    Tags              = @('Automation', 'Utility')  # For PowerShell Gallery
    ProjectUri        = 'https://github.com/user/MyModule'
    LicenseUri        = 'https://github.com/user/MyModule/blob/main/LICENSE'
}

New-ModuleManifest @manifestParams
```

**Important**: `FunctionsToExport` must match public function names exactly.

### 6. Validate Module

Test the module before distribution:

```powershell
# Test manifest is valid
Test-ModuleManifest -Path "$modulePath\$moduleName.psd1"

# Import the module
Import-Module "$modulePath\$moduleName.psd1" -Force

# Verify exported functions
Get-Command -Module $moduleName

# Test a function
Get-MyData -Name "Test"

# Clean up
Remove-Module $moduleName
```

## Decision Tree

```
Standalone scripts → Multiple functions in one file?
    ├─ Yes → Split each function into separate file
    │        Categorize as Public (exported) or Private (internal)
    │
    └─ Already separated → Organize into Public/Private folders
        Create .psm1 to import all
        Generate .psd1 manifest
        Validate with Test-ModuleManifest
        Import and test
```

## Example: Converting a Script

**Before**: Single file `AzureTools.ps1`

```powershell
# AzureTools.ps1
function Get-AzureReport {
    [CmdletBinding()]
    param([string]$SubscriptionId)
    
    $data = Get-InternalData -Id $SubscriptionId
    Format-AzureReport $data
}

function Get-InternalData {
    param([string]$Id)
    # Helper function
}

function Format-AzureReport {
    param($Data)
    # Helper function
}
```

**After**: Module structure

```
AzureTools/
├── AzureTools.psd1          # Manifest (FunctionsToExport = @('Get-AzureReport'))
├── AzureTools.psm1          # Imports Public/* and Private/*, exports Public
├── Public/
│   └── Get-AzureReport.ps1  # Only this is exported
└── Private/
    ├── Get-InternalData.ps1
    └── Format-AzureReport.ps1
```

**Conversion steps**:

```powershell
# 1. Create structure
$moduleName = "AzureTools"
New-Item -Path ".\$moduleName\Public" -ItemType Directory -Force
New-Item -Path ".\$moduleName\Private" -ItemType Directory -Force

# 2. Extract and save functions
# Public/Get-AzureReport.ps1
@'
function Get-AzureReport {
    [CmdletBinding()]
    param([string]$SubscriptionId)
    
    $data = Get-InternalData -Id $SubscriptionId
    Format-AzureReport $data
}
'@ | Out-File ".\$moduleName\Public\Get-AzureReport.ps1" -Encoding utf8

# Private/Get-InternalData.ps1
@'
function Get-InternalData {
    param([string]$Id)
    # Helper function
}
'@ | Out-File ".\$moduleName\Private\Get-InternalData.ps1" -Encoding utf8

# Private/Format-AzureReport.ps1
@'
function Format-AzureReport {
    param($Data)
    # Helper function
}
'@ | Out-File ".\$moduleName\Private\Format-AzureReport.ps1" -Encoding utf8

# 3. Create root module (see template above)
# 4. Create manifest
New-ModuleManifest -Path ".\$moduleName\$moduleName.psd1" `
    -RootModule "$moduleName.psm1" `
    -FunctionsToExport @('Get-AzureReport') `
    -ModuleVersion '1.0.0'

# 5. Test
Test-ModuleManifest -Path ".\$moduleName\$moduleName.psd1"
Import-Module ".\$moduleName\$moduleName.psd1" -Force
Get-Command -Module $moduleName
```

## Common Patterns

### Auto-Detecting Public Functions

Instead of manually listing functions in `FunctionsToExport`, derive from Public folder:

```powershell
$publicFunctions = (Get-ChildItem -Path "$modulePath\Public\*.ps1").BaseName

New-ModuleManifest -Path "$modulePath\$moduleName.psd1" `
    -FunctionsToExport $publicFunctions `
    # ... other params
```

### Adding README and LICENSE

```powershell
@'
# MyModule

## Installation
```powershell
Install-Module -Name MyModule
```

## Usage
```powershell
Import-Module MyModule
Get-MyData -Name "Example"
```
'@ | Out-File "$modulePath\README.md" -Encoding utf8

# Add LICENSE file (MIT, Apache, etc.)
```

### Versioning Strategy

Follow semantic versioning in `.psd1`:
- **1.0.0** - Initial release
- **1.1.0** - New features (backwards compatible)
- **2.0.0** - Breaking changes

Update `ModuleVersion` in manifest when releasing.

## Best Practices

### Module Organization

✅ **DO**:
- One function per file, filename matches function name
- Use `Public/` for exported functions only
- Keep helpers in `Private/`
- Include comment-based help in each function
- Use `[CmdletBinding()]` on all public functions

❌ **DON'T**:
- Mix multiple functions in one file
- Export private helper functions
- Hardcode file paths in `.psm1` (use `$PSScriptRoot`)
- Forget to update `FunctionsToExport` when adding public functions

### Manifest Quality

Required fields for PowerShell Gallery:
- `Author`
- `Description`
- `ModuleVersion`
- `PowerShellVersion`
- `ProjectUri`
- `LicenseUri` (if distributing)
- `Tags` (for discoverability)

### Testing Before Distribution

Always validate:
```powershell
# 1. Manifest is valid
Test-ModuleManifest -Path ".\MyModule\MyModule.psd1"

# 2. Module imports cleanly
Import-Module ".\MyModule" -Force -Verbose

# 3. Expected functions are exported
$exported = Get-Command -Module MyModule
$expected = @('Get-MyData', 'Set-MyConfig')
$exported.Name | Should -Be $expected

# 4. Run Pester tests if available
Invoke-Pester -Path ".\MyModule\Tests"

# 5. Run PSScriptAnalyzer
Invoke-ScriptAnalyzer -Path ".\MyModule" -Recurse
```

## Anti-Patterns to Avoid

- ❌ Exporting everything (`Export-ModuleMember -Function *`)
- ❌ Not using `$PSScriptRoot` in `.psm1` (breaks when module moves)
- ❌ Including test files or build artifacts in module distribution
- ❌ Forgetting to remove `-Force` from `Import-Module` in `.psm1`
- ❌ Not testing module import before distribution

## Next Steps After Module Creation

1. **Add Pester Tests** - Use `pester-test-generator` skill
2. **Run PSScriptAnalyzer** - Ensure code quality
3. **Create Help** - Add comment-based help to all public functions
4. **Publish to Gallery** - Use `gallery-publisher` skill
5. **Set up CI/CD** - Automate testing and publishing

## Reference

- Module manifest reference: `Get-Help New-ModuleManifest -Full`
- Module structure: `Get-Help about_Modules`
- Best practices: `.github/instructions/powershell-scripting.instructions.md`
- Expert guidance: `.github/agents/powershell-expert.agent.md`
