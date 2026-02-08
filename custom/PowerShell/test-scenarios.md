# PowerShell Expert System - Test Scenarios

This file contains test scenarios to validate the PowerShell expert system implementation.

## Test 1: Instructions File Activation

### Objective
Verify that PowerShell instructions are automatically applied when editing PowerShell files.

### Test Files
Create a new `.ps1` file and verify the instructions guide proper structure.

### Expected Behavior
- When editing `.ps1`, `.psm1`, `.psd1` files, instructions should activate
- Suggestions should include:
  - `[CmdletBinding()]` attribute
  - Proper parameter blocks with validation
  - Begin/Process/End blocks for pipeline support
  - Cross-platform path handling
  - Error handling with try-catch

### Validation
```powershell
# Create test file
New-Item -Path "test-script.ps1" -ItemType File

# Edit with AI assistance - should suggest:
# 1. Script template with comment-based help
# 2. [CmdletBinding()] for advanced functions
# 3. Proper parameter validation
# 4. Pipeline support patterns
```

## Test 2: Approved Verb Validation

### Objective
Ensure the system recommends approved PowerShell verbs only.

### Test Case
Ask AI to create a function for "deleting files".

### Expected Behavior
- Should suggest `Remove-*` (approved verb)
- Should NOT suggest `Delete-*` (non-approved verb)
- Should reference `Get-Verb` for verification

### Validation
```powershell
# Expected function name pattern
function Remove-MyFile { }  # ✅ Correct
# NOT: function Delete-MyFile { }  # ❌ Wrong
```

## Test 3: PowerShell Expert Agent Invocation

### Objective
Verify PowerShell Expert agent can be invoked for complex tasks.

### Test Command
Ask the agent to design a PowerShell module structure.

### Example Prompt
```
Design a PowerShell module for managing cloud resources with cmdlets:
- Get-CloudResource
- New-CloudResource
- Set-CloudResource
- Remove-CloudResource

Include proper module manifest, folder structure, and Pester tests.
```

### Expected Output
- Complete module structure (folder layout)
- Module manifest (.psd1)
- Root module (.psm1)
- Public/Private function organization
- Pester test structure
- Build and import instructions

## Test 4: Binary Cmdlet Development

### Objective
Verify agent can guide creation of C# binary cmdlets.

### Test Case
Request a binary cmdlet that processes pipeline input.

### Example Prompt
```
Create a binary cmdlet Get-ProcessedData that:
- Accepts string array from pipeline
- Validates input is not null/empty
- Supports -Detailed switch parameter
- Returns custom objects
- Handles errors gracefully
```

### Expected Output
- Complete C# cmdlet class
- Proper attributes ([Cmdlet], [Parameter])
- ProcessRecord implementation
- Error handling with ErrorRecord
- .csproj configuration
- Build instructions

## Test 5: Cross-Platform Compatibility

### Objective
Ensure generated scripts work on Windows, Linux, and macOS.

### Test Case
Request a script that handles file paths.

### Expected Behavior
- Use `Join-Path` or `[System.IO.Path]::Combine()`
- Avoid hardcoded `\` separators
- Include OS detection: `$IsWindows`, `$IsLinux`, `$IsMacOS`
- No Windows-specific paths like `C:\`

### Validation
```powershell
# ✅ Should generate:
$path = Join-Path $PSScriptRoot 'data' 'config.json'

# ❌ Should NOT generate:
$path = "$PSScriptRoot\data\config.json"
```

## Test 6: Error Handling Patterns

### Objective
Validate proper error handling implementation.

### Test Case
Request a function that reads files and handles errors.

### Expected Output
```powershell
function Get-FileContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateScript({ Test-Path $_ })]
        [string[]]$Path
    )
    
    process {
        foreach ($file in $Path) {
            try {
                $content = Get-Content $file -ErrorAction Stop
                # Process content
                [PSCustomObject]@{
                    Path = $file
                    Content = $content
                }
            }
            catch [System.IO.FileNotFoundException] {
                Write-Error "File not found: $file"
            }
            catch {
                Write-Error "Failed to read $file: $_"
            }
        }
    }
}
```

## Test 7: ShouldProcess Implementation

### Objective
Verify `-WhatIf` and `-Confirm` support for destructive operations.

### Test Case
Request a function that deletes files.

### Expected Output
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
```

## Test 8: Pipeline Support

### Objective
Ensure functions accept and process pipeline input correctly.

### Test Case
Request a function that processes multiple items from pipeline.

### Expected Output
```powershell
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [string[]]$Name
)

process {
    foreach ($item in $Name) {
        # Process each pipeline input
    }
}

# Usage:
# "Item1", "Item2", "Item3" | Function-Name
```

## Test 9: Module Structure Generation

### Objective
Validate complete module structure creation.

### Expected Directory Structure
```
MyModule/
├── MyModule.psd1          # Manifest
├── MyModule.psm1          # Root module
├── Public/                # Exported functions
│   ├── Get-Something.ps1
│   └── Set-Something.ps1
├── Private/               # Internal functions
│   └── Helper.ps1
└── Tests/                 # Pester tests
    └── MyModule.Tests.ps1
```

## Test 10: Overnight Execution Integration

### Objective
Verify PowerShell tasks can be executed in overnight workflow.

### Test Configuration
Check `overnight-config.json` has POWERSHELL category:

```json
"POWERSHELL": {
  "agent": ".github/agents/powershell-expert.agent.md",
  "overnightModel": "gpt-4.1-mini",
  "daytimeModel": "claude-sonnet-4-5"
}
```

### Test Task
Create a tasks.md with:
```markdown
- [ ] T001 [POWERSHELL] Create deployment automation script
```

### Expected Behavior
- Overnight runner recognizes POWERSHELL category
- Invokes PowerShell Expert agent
- Uses correct model configuration
- Generates production-quality PowerShell script

## Test 11: Pester Test Generation

### Objective
Verify agent can create Pester 5.x tests.

### Test Case
Request tests for an existing function.

### Expected Output
```powershell
BeforeAll {
    . $PSScriptRoot/../Public/Get-MyData.ps1
}

Describe 'Get-MyData' {
    Context 'When valid input' {
        It 'Should return data object' {
            $result = Get-MyData -Id 123
            $result | Should -Not -BeNullOrEmpty
            $result.Id | Should -Be 123
        }
    }
    
    Context 'When invalid input' {
        It 'Should throw error' {
            { Get-MyData -Id 0 } | Should -Throw
        }
    }
}
```

## Test 12: Documentation Accessibility

### Objective
Verify cached documentation is accessible and useful.

### Test Files
Check existence of:
- `custom/PowerShell/docs/00-index.md`
- `custom/PowerShell/docs/cmdlet-overview.md`
- `custom/PowerShell/docs/approved-verbs.md`
- `custom/PowerShell/docs/cmdlet-parameters.md`
- `custom/PowerShell/docs/error-reporting.md`

### Expected Behavior
- All documentation files exist
- Content is properly formatted markdown
- Links between documents work
- Examples are present and correct

## Validation Checklist

After implementation, verify:

- [ ] Instructions file activates for `.ps1`, `.psm1`, `.psd1` files
- [ ] Only approved verbs are suggested
- [ ] PowerShell Expert agent can be invoked
- [ ] Binary cmdlet code is correct and compiles
- [ ] Cross-platform paths are used
- [ ] Error handling follows best practices
- [ ] ShouldProcess is implemented for destructive ops
- [ ] Pipeline support works correctly
- [ ] Module structure follows conventions
- [ ] Overnight config includes POWERSHELL category
- [ ] Pester tests follow 5.x syntax
- [ ] Documentation is complete and accessible
- [ ] Examples compile and run successfully
- [ ] Cheat sheet is accurate and helpful

## Manual Testing Steps

1. **Create a new PowerShell script**
   ```powershell
   New-Item -Path "test-function.ps1" -ItemType File
   ```

2. **Edit with AI assistance** and verify suggestions include:
   - `[CmdletBinding()]`
   - Parameter validation
   - Comment-based help

3. **Invoke PowerShell Expert agent**
   ```
   @agent powershell-expert Create a module for user management with Get-User and New-User cmdlets
   ```

4. **Build binary cmdlet example**
   ```powershell
   cd custom/PowerShell/examples/binary-cmdlet
   dotnet build
   ```

5. **Import and test module example**
   ```powershell
   Import-Module ./custom/PowerShell/examples/module-structure/MyModule.psd1
   Get-MyData -Id 123
   ```

6. **Run Pester tests** (if created)
   ```powershell
   Invoke-Pester -Path ./Tests -Output Detailed
   ```

## Success Criteria

✅ All checklist items pass  
✅ Instructions automatically guide PowerShell development  
✅ Agent produces compilable, runnable code  
✅ Cross-platform compatibility ensured  
✅ Documentation is complete and helpful  
✅ Examples work as expected  
✅ Integration with overnight workflow functions  

## Troubleshooting

**Instructions not activating?**
- Verify file extension matches `applyTo` pattern
- Check `.github/instructions/powershell-scripting.instructions.md` exists

**Agent not responding?**
- Verify `.github/agents/powershell-expert.agent.md` exists
- Check agent metadata is valid

**Binary cmdlet won't build?**
- Ensure .NET 6.0 SDK is installed
- Run `dotnet restore` before `dotnet build`
- Check NuGet package `PowerShellStandard.Library` is referenced

**Module won't import?**
- Run `Test-ModuleManifest -Path ./MyModule.psd1`
- Verify all exported functions exist in Public/
- Check for syntax errors in .psm1
