---
name: powershell-modernizer
description: Upgrade PowerShell 5.1 legacy code to PowerShell 7+ modern syntax. Converts if/else to ternary, null checks to null coalescing, adds pipeline chains, ForEach-Object -Parallel, and cross-platform patterns.
---

# PowerShell Modernizer

Transform legacy PowerShell 5.1 code to modern PowerShell 7+ syntax with ternary operators, null coalescing, pipeline chains, parallel execution, and cross-platform compatibility.

## When to Use

- Migrating scripts from Windows PowerShell 5.1 to PowerShell 7+
- Modernizing legacy scripts for better readability
- Taking advantage of PowerShell 7+ performance features
- Preparing scripts for cross-platform execution (Linux, macOS)
- Code review identified outdated patterns

**NOT for**: New scripts (write with modern syntax from the start using PowerShell instructions).

## Prerequisites

- PowerShell 7+ installed (target environment)
- PowerShell 5.1 or later (source code)
- Understanding of new syntax features (or willing to learn)
- Backup of original code (or version control)

## Core Workflow

### 1. Analyze Legacy Code

Identify PowerShell 5.1 patterns to modernize:

```powershell
# Scan for legacy patterns
Get-Content .\LegacyScript.ps1 | Select-String -Pattern 'if \(.+\) \{ .+ \} else \{ .+ \}'
```

Common legacy patterns:
- Verbose `if/else` for simple assignments
- Null checks with `if ($null -eq $var)`
- Sequential `&&` logic with separate statements
- `ForEach-Object` without `-Parallel`
- Platform-specific paths (hardcoded `\` or `/`)
- Missing `[CmdletBinding()]`

### 2. Apply PowerShell 7+ Transformations

#### A. Ternary Operator (`? :`)

**Before** (PS 5.1):
```powershell
if ($user.IsActive) {
    $status = 'Active'
} else {
    $status = 'Inactive'
}
```

**After** (PS 7+):
```powershell
$status = $user.IsActive ? 'Active' : 'Inactive'
```

**Pattern**: `condition ? true-value : false-value`

**When to use**:
- Simple assignments based on condition
- One-line boolean checks
- Return values from functions

**When NOT to use**:
- Complex multi-line logic
- Side effects in branches (use `if/else`)
- Nested ternary (hurts readability)

#### B. Null Coalescing (`??`, `??=`)

**Before** (PS 5.1):
```powershell
if ($null -eq $config) {
    $config = Get-DefaultConfig
}
```

**After** (PS 7+):
```powershell
$config ??= Get-DefaultConfig
```

**Or for expressions**:
```powershell
# Before
$value = if ($null -ne $input) { $input } else { 'default' }

# After
$value = $input ?? 'default'
```

**Operators**:
- `??` - Null coalescing (return right if left is null)
- `??=` - Null coalescing assignment (assign right if left is null)

#### C. Pipeline Chain Operators (`&&`, `||`)

**Before** (PS 5.1):
```powershell
$result = Test-Path $file
if ($result) {
    Remove-Item $file
}
```

**After** (PS 7+):
```powershell
Test-Path $file && Remove-Item $file
```

**Before** (PS 5.1):
```powershell
try {
    Connect-Service
} catch {
    Connect-FallbackService
}
```

**After** (PS 7+):
```powershell
Connect-Service || Connect-FallbackService
```

**Operators**:
- `&&` - Execute right only if left succeeds
- `||` - Execute right only if left fails

**Best for**: Command chains, validation flows, fallback logic

#### D. ForEach-Object -Parallel

**Before** (PS 5.1):
```powershell
$servers | ForEach-Object {
    Test-Connection $_ -Count 1
}
```

**After** (PS 7+):
```powershell
$servers | ForEach-Object -Parallel {
    Test-Connection $_ -Count 1
} -ThrottleLimit 10
```

**Benefits**:
- Up to 10x faster for I/O-bound operations
- Automatic thread management
- Default throttle limit: 5 (configurable)

**When to use**:
- Network operations (API calls, server checks)
- File I/O across multiple files
- Independent processing of large datasets

**When NOT to use**:
- Items must be processed in order
- Shared state/variables (use `$using:` scope)
- Very fast operations (overhead not worth it)

#### E. Cross-Platform Path Handling

**Before** (PS 5.1):
```powershell
$logPath = 'C:\Logs\app.log'
$configPath = $env:USERPROFILE + '\config.json'
```

**After** (PS 7+):
```powershell
$logPath = Join-Path ([Environment]::GetFolderPath('CommonApplicationData')) 'Logs' 'app.log'
$configPath = Join-Path $HOME 'config.json'

# Or for conditional paths
$baseDir = $IsWindows ? 'C:\Data' : '/var/data'
```

**Cross-platform variables**:
- `$IsWindows` - True on Windows
- `$IsLinux` - True on Linux
- `$IsMacOS` - True on macOS
- `$HOME` - User home directory (all platforms)
- `$PSScriptRoot` - Script directory (all platforms)

#### F. Add [CmdletBinding()] Where Missing

**Before** (PS 5.1):
```powershell
function Get-MyData {
    param($Name)
    # ...
}
```

**After** (PS 7+):
```powershell
function Get-MyData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )
    # ...
}
```

**Benefits**: Enables `-Verbose`, `-Debug`, `-ErrorAction`, better error handling

### 3. Validate Modernized Code

Test thoroughly:

```powershell
# 1. Syntax check
$null = [System.Management.Automation.PSParser]::Tokenize((Get-Content .\ModernScript.ps1 -Raw), [ref]$null)

# 2. Run PSScriptAnalyzer
Invoke-ScriptAnalyzer -Path .\ModernScript.ps1 -Severity Warning,Error

# 3. Test execution
.\ModernScript.ps1 -Verbose -WhatIf

# 4. Compare behavior with original (if safe)
$legacy = .\LegacyScript.ps1
$modern = .\ModernScript.ps1
Compare-Object $legacy $modern
```

## Decision Tree

```
Legacy code → Has simple if/else assignments?
    ├─ Yes → Convert to ternary (? :)
    └─ No → Keep if/else

→ Has null checks with assignment?
    ├─ Yes → Convert to null coalescing (??=)
    └─ No → Skip

→ Has sequential command execution?
    ├─ Yes → Success-dependent? → Use &&
    │        Failure-fallback? → Use ||
    └─ No → Keep as-is

→ Has ForEach-Object processing?
    ├─ Yes → Independent items? → Add -Parallel
    │        Ordered processing? → Keep sequential
    └─ No → Skip

→ Has hardcoded paths?
    ├─ Yes → Windows only? → Keep for now (add comment)
    │        Cross-platform? → Use Join-Path + automatic variables
    └─ No → Skip

→ Missing [CmdletBinding()]?
    ├─ Yes → Add it (always beneficial)
    └─ No → Already modern
```

## Example: Complete Modernization

**Before** (PowerShell 5.1):

```powershell
function Get-ServerStatus {
    param($ServerList, $Timeout)
    
    # Set default timeout
    if ($null -eq $Timeout) {
        $Timeout = 30
    }
    
    $results = @()
    foreach ($server in $ServerList) {
        $status = Test-Connection -ComputerName $server -Count 1 -Quiet
        if ($status) {
            $message = 'Online'
        } else {
            $message = 'Offline'
        }
        
        $results += [PSCustomObject]@{
            Server = $server
            Status = $message
        }
    }
    
    # Save to log
    $logPath = 'C:\Logs\server-status.log'
    if (Test-Path $logPath) {
        $results | Export-Csv -Path $logPath -Append -NoTypeInformation
    }
    
    return $results
}
```

**After** (PowerShell 7+):

```powershell
function Get-ServerStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$ServerList,
        
        [Parameter()]
        [int]$Timeout = 30  # Default in parameter
    )
    
    begin {
        # Cross-platform log path
        $logDir = Join-Path ([Environment]::GetFolderPath('CommonApplicationData')) 'Logs'
        $logPath = Join-Path $logDir 'server-status.log'
        
        # Create directory if needed (cross-platform)
        New-Item -Path $logDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    }
    
    process {
        # Parallel processing for performance
        $results = $ServerList | ForEach-Object -Parallel {
            $status = Test-Connection -ComputerName $_ -Count 1 -Quiet
            
            [PSCustomObject]@{
                Server = $_
                Status = $status ? 'Online' : 'Offline'  # Ternary operator
                Timestamp = Get-Date
            }
        } -ThrottleLimit 10
        
        # Pipeline chain - export only if path exists
        Test-Path $logPath && ($results | Export-Csv -Path $logPath -Append -NoTypeInformation)
        
        # Return results
        $results
    }
}
```

**Improvements**:
1. ✅ Added `[CmdletBinding()]` for advanced function features
2. ✅ Default timeout in parameter definition (cleaner than null check)
3. ✅ Pipeline support with `ValueFromPipeline` + `begin/process` blocks
4. ✅ Cross-platform log path using `Join-Path` and `GetFolderPath()`
5. ✅ Parallel processing with `-Parallel` (10x faster for multiple servers)
6. ✅ Ternary operator for status assignment
7. ✅ Pipeline chain `&&` for conditional CSV export
8. ✅ Added timestamp to results
9. ✅ Removed explicit `return` (PowerShell convention)
10. ✅ Removed `@()` array initialization (not needed with pipeline)

## Common Modernization Patterns

### Pattern 1: Boolean Assignment

```powershell
# Before
if ($age -ge 18) { $canVote = $true } else { $canVote = $false }

# After
$canVote = $age -ge 18  # Already returns boolean, no ternary needed
```

### Pattern 2: Default Configuration

```powershell
# Before
if (-not $config) {
    $config = @{ Timeout = 30; Retry = 3 }
}

# After
$config ??= @{ Timeout = 30; Retry = 3 }
```

### Pattern 3: Fallback Value

```powershell
# Before
$value = $env:MY_VAR
if (-not $value) { $value = 'default' }

# After
$value = $env:MY_VAR ?? 'default'
```

### Pattern 4: Validation Chain

```powershell
# Before
$valid = Test-InputFormat $data
if ($valid) {
    $sanitized = Remove-MaliciousContent $data
    if ($sanitized) {
        Save-ToDatabase $sanitized
    }
}

# After
Test-InputFormat $data && Remove-MaliciousContent $data && Save-ToDatabase $_
```

### Pattern 5: Error Fallback

```powershell
# Before
try {
    $data = Get-FromPrimarySource
} catch {
    try {
        $data = Get-FromBackupSource
    } catch {
        $data = Get-FromCachedSource
    }
}

# After
$data = Get-FromPrimarySource || Get-FromBackupSource || Get-FromCachedSource
```

## Best Practices

### Modernization Guidelines

✅ **DO**:
- Test before and after behavior matches
- Modernize one pattern at a time
- Use version control (commit before modernization)
- Add comments for complex ternary/chain expressions
- Verify cross-platform compatibility if targeting multiple OS
- Run PSScriptAnalyzer after changes

❌ **DON'T**:
- Nest ternary operators (unreadable)
- Chain more than 3 operators with `&&`/`||`
- Use `-Parallel` for ordered operations
- Remove error handling in favor of shorter syntax
- Modernize production code without testing

### Performance Considerations

**When -Parallel helps** (10x faster):
- Network I/O (API calls, server pings)
- File operations on multiple files
- Database queries to different sources
- Independent computations

**When -Parallel hurts** (overhead > benefit):
- Very fast operations (< 10ms each)
- Small item counts (< 10 items)
- Operations requiring shared state
- Ordered processing requirements

### Readability vs Modernization

Sometimes verbose is better:

```powershell
# Too clever - hard to read
$result = $a ?? ($b ?? ($c ? $d : $e))

# Better - clear intent
$result = $a ?? $b
$result ??= ($c ? $d : $e)

# Best - for complex logic, use if/else
if ($null -ne $a) {
    $result = $a
} elseif ($null -ne $b) {
    $result = $b
} elseif ($c) {
    $result = $d
} else {
    $result = $e
}
```

**Rule**: If ternary/chains need explanation, use `if/else` instead.

## Anti-Patterns to Avoid

- ❌ Nested ternary: `$x ? ($y ? $a : $b) : $c` (use if/else)
- ❌ Long chains: `cmd1 && cmd2 && cmd3 && cmd4 && cmd5` (split into blocks)
- ❌ Side effects in ternary: `$x ? (Remove-Item $file) : (New-Item $file)` (use if/else)
- ❌ `-Parallel` with shared variables without `$using:` scope
- ❌ Removing `[CmdletBinding()]` to save lines (always keep it)
- ❌ Modernizing without understanding what new syntax does

## Migration Checklist

After modernization, verify:

- [ ] Script executes without errors on PowerShell 7+
- [ ] Behavior matches original (run tests or manual verification)
- [ ] PSScriptAnalyzer shows no new warnings
- [ ] Cross-platform paths use `Join-Path` and automatic variables
- [ ] `-Parallel` used only for independent operations
- [ ] Ternary operators are single-line and readable
- [ ] Pipeline chains are no more than 2-3 commands
- [ ] All functions have `[CmdletBinding()]`
- [ ] Comments added for complex modern syntax
- [ ] Version control commit created (rollback safety)

## Next Steps

1. **Test thoroughly**: Run against original test cases
2. **Add Pester tests**: Use `pester-test-generator` skill
3. **Run analyzer**: `Invoke-ScriptAnalyzer -Path .\ModernScript.ps1`
4. **Document changes**: Add comments explaining modern syntax for team
5. **Deploy gradually**: Test in dev → staging → production

## Reference

- PowerShell 7+ features: `Get-Help about_Operators`
- Ternary operator: `Get-Help about_If`
- Null coalescing: `Get-Help about_Assignment_Operators`
- Pipeline chains: `Get-Help about_Pipeline_Chain_Operators`
- Parallel: `Get-Help ForEach-Object -Parameter Parallel`
- Cross-platform: `Get-Help about_Automatic_Variables`
- Best practices: `.github/instructions/powershell-scripting.instructions.md`
