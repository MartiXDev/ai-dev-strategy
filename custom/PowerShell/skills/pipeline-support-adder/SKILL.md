---
name: pipeline-support-adder
description: Add pipeline capabilities to existing PowerShell functions. Refactors functions to accept ValueFromPipeline or ValueFromPipelineByPropertyName, implements begin/process/end blocks, and adds proper pipeline handling patterns.
---

# Pipeline Support Adder

Transform existing PowerShell functions to support pipeline input by adding `ValueFromPipeline`, `ValueFromPipelineByPropertyName`, and refactoring into `begin/process/end` blocks.

## When to Use

- Existing function works but doesn't support pipeline
- Want to make function work with `Get-*` cmdlets (e.g., `Get-Process | Stop-MyProcess`)
- Need to process arrays more idiomatically
- Adding pipeline to legacy scripts
- Making functions composable with other cmdlets

**NOT for**: New functions (add pipeline support from the start using PowerShell instructions).

## Prerequisites

- PowerShell 7+ (or 5.1 with limitations)
- Existing function with parameter block
- Understanding of what pipeline support means for your use case
- Test data to validate pipeline behavior

## Core Workflow

### 1. Analyze Current Function

Identify the parameter that should accept pipeline input:

```powershell
function Get-UserReport {
    param(
        [string]$Username  # Should this come from pipeline?
    )
    
    # Current implementation processes one username
    Write-Output "Report for $Username"
}
```

**Questions to answer**:
- What parameter should accept pipeline input? (Usually the main "target" parameter)
- Should it accept by value or by property name?
- Does the function need to process multiple items?
- Does it need initialization or cleanup?

### 2. Choose Pipeline Binding Type

Two options for pipeline input:

#### Option A: ValueFromPipeline (by value)

Use when piping simple values directly:

```powershell
'Alice', 'Bob' | Get-UserReport
```

**Add to parameter**:
```powershell
[Parameter(ValueFromPipeline = $true)]
[string]$Username
```

#### Option B: ValueFromPipelineByPropertyName (by property)

Use when piping objects with properties:

```powershell
Get-ADUser -Filter * | Get-UserReport  # Username comes from object property
```

**Add to parameter**:
```powershell
[Parameter(ValueFromPipelineByPropertyName = $true)]
[string]$Username
```

#### Option C: Both (most flexible)

```powershell
[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
[string]$Username
```

### 3. Refactor to begin/process/end Blocks

Pipeline functions must use `process` block to handle each piped item:

**Structure**:
```powershell
function Get-UserReport {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Username
    )
    
    begin {
        # Runs ONCE before processing any items
        # Initialize variables, open connections, etc.
    }
    
    process {
        # Runs ONCE PER ITEM from pipeline
        # Main logic goes here
    }
    
    end {
        # Runs ONCE after processing all items
        # Cleanup, close connections, summary output
    }
}
```

### 4. Move Logic to Appropriate Blocks

**Before** (no pipeline support):
```powershell
function Get-UserReport {
    param([string]$Username)
    
    $config = Get-Configuration
    $data = Get-UserData -Name $Username
    Write-Output "Report for $Username: $data"
    Save-ToCache -Data $data
}
```

**After** (with pipeline support):
```powershell
function Get-UserReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Username
    )
    
    begin {
        # Initialize once (not per user)
        Write-Verbose "Loading configuration..."
        $config = Get-Configuration
        $results = [System.Collections.Generic.List[PSCustomObject]]::new()
    }
    
    process {
        # Process each username
        Write-Verbose "Processing user: $Username"
        try {
            $data = Get-UserData -Name $Username -Config $config
            $report = [PSCustomObject]@{
                Username = $Username
                Data = $data
                Timestamp = Get-Date
            }
            $results.Add($report)
            Write-Output $report  # Output immediately for streaming
        }
        catch {
            Write-Error "Failed to get report for $Username: $_"
        }
    }
    
    end {
        # Cleanup and summary
        Write-Verbose "Processed $($results.Count) users"
        Save-ToCache -Data $results
    }
}
```

**Key changes**:
1. `begin`: One-time setup (config loading)
2. `process`: Per-item logic (each username)
3. `end`: Cleanup and summary
4. Immediate output in `process` (streaming)
5. Results collection for summary/caching

### 5. Handle Arrays vs Pipeline

Function should work BOTH ways:

```powershell
# Array parameter (traditional)
Get-UserReport -Username @('Alice', 'Bob', 'Charlie')

# Pipeline (modern)
'Alice', 'Bob', 'Charlie' | Get-UserReport

# Pipeline from objects
Get-ADUser -Filter * | Get-UserReport
```

**Implementation**:
```powershell
[Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
[string[]]$Username  # Array type handles both!
```

**Processing**:
```powershell
process {
    # If array parameter, iterate
    foreach ($user in $Username) {
        # Process each user
        Write-Output "Report for $user"
    }
}
```

### 6. Test Pipeline Behavior

Verify all scenarios work:

```powershell
# 1. Single value
Get-UserReport -Username 'Alice'

# 2. Array parameter
Get-UserReport -Username @('Alice', 'Bob')

# 3. Pipeline by value
'Alice', 'Bob' | Get-UserReport

# 4. Pipeline by property name
[PSCustomObject]@{ Username = 'Alice' } | Get-UserReport

# 5. Pipeline from cmdlet
Get-Process | Select-Object -First 3 -ExpandProperty Name | Get-UserReport

# 6. Pipeline with error handling
'Alice', 'InvalidUser', 'Bob' | Get-UserReport -ErrorAction Continue
```

## Decision Tree

```
Function parameter → Should accept pipeline?
    ├─ Yes → What kind of input?
    │   ├─ Simple values (strings, ints) → ValueFromPipeline
    │   ├─ Object properties → ValueFromPipelineByPropertyName
    │   └─ Both → Use both attributes
    │
    └─ No → Leave as-is

→ Needs initialization (DB connection, config)?
    ├─ Yes → Add begin block
    └─ No → begin block optional

→ Must process each item individually?
    ├─ Yes → Add process block (required for pipeline)
    └─ No → ERROR - cannot use pipeline

→ Needs cleanup or summary?
    ├─ Yes → Add end block
    └─ No → end block optional

→ Should output items immediately (streaming)?
    ├─ Yes → Write-Output in process block
    └─ No → Collect in begin, output in end

→ Parameter can be array?
    ├─ Yes → Add foreach loop in process block
    └─ No → Process single value in process block
```

## Example 1: Simple Pipeline Support

**Before**:
```powershell
function Stop-MyService {
    param([string]$ServiceName)
    
    Stop-Service -Name $ServiceName -Force
    Write-Output "Stopped: $ServiceName"
}
```

**After**:
```powershell
function Stop-MyService {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$ServiceName
    )
    
    process {
        foreach ($name in $ServiceName) {
            if ($PSCmdlet.ShouldProcess($name, "Stop service")) {
                try {
                    Stop-Service -Name $name -Force -ErrorAction Stop
                    Write-Verbose "Stopped service: $name"
                    [PSCustomObject]@{
                        Service = $name
                        Status = 'Stopped'
                    }
                }
                catch {
                    Write-Error "Failed to stop $name: $_"
                }
            }
        }
    }
}
```

**Usage**:
```powershell
# Array
Stop-MyService -ServiceName @('Spooler', 'BITS')

# Pipeline
'Spooler', 'BITS' | Stop-MyService

# From Get-Service
Get-Service -Name 'Spool*' | Stop-MyService -WhatIf
```

## Example 2: Pipeline with Initialization

**Before**:
```powershell
function Get-AzureVMStatus {
    param([string]$VMName)
    
    Connect-AzAccount
    $vm = Get-AzVM -Name $VMName
    $vm.PowerState
}
```

**After**:
```powershell
function Get-AzureVMStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$VMName,
        
        [Parameter()]
        [string]$ResourceGroup
    )
    
    begin {
        # Connect once for all VMs
        Write-Verbose "Connecting to Azure..."
        $context = Get-AzContext
        if (-not $context) {
            Connect-AzAccount
        }
        $vmCount = 0
    }
    
    process {
        foreach ($name in $VMName) {
            Write-Verbose "Checking VM: $name"
            try {
                $params = @{ Name = $name }
                if ($ResourceGroup) { $params.ResourceGroupName = $ResourceGroup }
                
                $vm = Get-AzVM @params -Status -ErrorAction Stop
                $vmCount++
                
                [PSCustomObject]@{
                    VMName = $vm.Name
                    ResourceGroup = $vm.ResourceGroupName
                    PowerState = $vm.PowerState
                    ProvisioningState = $vm.ProvisioningState
                }
            }
            catch {
                Write-Error "Failed to get status for $name: $_"
            }
        }
    }
    
    end {
        Write-Verbose "Checked $vmCount VMs"
    }
}
```

**Usage**:
```powershell
# Single VM
Get-AzureVMStatus -VMName 'WebServer01'

# Multiple VMs from pipeline
'WebServer01', 'WebServer02', 'DBServer01' | Get-AzureVMStatus

# From CSV
Import-Csv .\vms.csv | Get-AzureVMStatus

# With resource group
Get-AzVM -ResourceGroupName 'Production' | Get-AzureVMStatus
```

## Example 3: Property Name Binding

**Before**:
```powershell
function Send-UserNotification {
    param(
        [string]$Email,
        [string]$Message
    )
    
    Send-MailMessage -To $Email -Subject "Notification" -Body $Message
}
```

**After**:
```powershell
function Send-UserNotification {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('EmailAddress', 'Mail')]  # Match different property names
        [string]$Email,
        
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Message
    )
    
    begin {
        Write-Verbose "Starting notification batch..."
        $sentCount = 0
    }
    
    process {
        if ($PSCmdlet.ShouldProcess($Email, "Send notification")) {
            try {
                Send-MailMessage -To $Email -Subject "Notification" -Body $Message -SmtpServer 'smtp.example.com'
                $sentCount++
                Write-Verbose "Sent to: $Email"
            }
            catch {
                Write-Error "Failed to send to $Email: $_"
            }
        }
    }
    
    end {
        Write-Verbose "Sent $sentCount notifications"
    }
}
```

**Usage**:
```powershell
# From CSV with columns: Email, Message
Import-Csv .\notifications.csv | Send-UserNotification

# From custom objects
$users = @(
    [PSCustomObject]@{ Email = 'alice@example.com'; Message = 'Welcome' }
    [PSCustomObject]@{ Email = 'bob@example.com'; Message = 'Update available' }
)
$users | Send-UserNotification -WhatIf

# From AD users (EmailAddress property → Email via Alias)
Get-ADUser -Filter * -Properties EmailAddress | 
    Select-Object EmailAddress, @{N='Message';E={'Password expiring soon'}} |
    Send-UserNotification
```

## Common Patterns

### Pattern 1: Streaming Output

Output items immediately for pipeline chaining:

```powershell
process {
    foreach ($item in $InputObject) {
        $result = Process-Item $item
        Write-Output $result  # Immediate output (streaming)
    }
}
```

### Pattern 2: Collecting Results

Collect all items for batch processing:

```powershell
begin {
    $results = [System.Collections.Generic.List[object]]::new()
}

process {
    $results.Add($InputObject)
}

end {
    # Process all at once
    $processed = Process-Batch -Items $results
    Write-Output $processed
}
```

### Pattern 3: Progress Reporting

```powershell
begin {
    $totalCount = 0
    $processedCount = 0
}

process {
    $totalCount++  # Count in process block (don't know total upfront with pipeline)
    
    # Process item
    Process-Item $InputObject
    
    $processedCount++
    Write-Progress -Activity "Processing" -Status "$processedCount processed" -PercentComplete -1
}

end {
    Write-Progress -Activity "Processing" -Completed
    Write-Verbose "Processed $processedCount items"
}
```

### Pattern 4: Error Accumulation

```powershell
begin {
    $errors = [System.Collections.Generic.List[string]]::new()
}

process {
    try {
        Process-Item $InputObject
    }
    catch {
        $errors.Add("Failed on $($InputObject): $_")
        Write-Error $_
    }
}

end {
    if ($errors.Count -gt 0) {
        Write-Warning "Encountered $($errors.Count) errors"
    }
}
```

## Best Practices

### Pipeline Design

✅ **DO**:
- Accept pipeline input on the primary parameter
- Use `process` block for per-item logic
- Use `begin` for one-time initialization
- Use `end` for cleanup and summary
- Output items immediately in `process` (streaming)
- Support both pipeline and array parameters
- Add `[CmdletBinding()]` for advanced features
- Use `Write-Verbose` for progress information

❌ **DON'T**:
- Put per-item logic in `begin` or `end`
- Collect all items before processing (kills streaming)
- Forget `foreach` when parameter is array type
- Mix pipeline and `-ArgumentList` approaches
- Output in `begin` (nothing processed yet)

### Parameter Attributes

```powershell
# Good - flexible
[Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
[Alias('Name', 'ComputerName')]  # Match various property names
[string[]]$Server

# Good - specific
[Parameter(Mandatory, ValueFromPipelineByPropertyName)]
[string]$Email

# Avoid - too restrictive
[Parameter(Mandatory, ValueFromPipeline)]
[string]$Server  # Not array - can't handle parameter arrays
```

### Performance Tips

- Use `[System.Collections.Generic.List[T]]` for collections (not `@() +=`)
- Stream output when possible (don't collect everything)
- Initialize resources in `begin`, not `process`
- Use `-ErrorAction SilentlyContinue` carefully (hides issues)

## Anti-Patterns to Avoid

- ❌ No `process` block with pipeline parameters
- ❌ Putting all logic in `begin` block
- ❌ Not handling arrays in pipeline parameters
- ❌ Collecting all items before processing (defeats streaming)
- ❌ No error handling in `process` (one failure stops all)
- ❌ Not using `$PSCmdlet.ShouldProcess` for destructive operations
- ❌ Forgetting to test both pipeline and parameter array scenarios

## Testing Checklist

After adding pipeline support:

- [ ] Function accepts single value via parameter
- [ ] Function accepts array via parameter
- [ ] Function accepts single value from pipeline
- [ ] Function accepts multiple values from pipeline
- [ ] Function accepts objects by property name
- [ ] `begin` block runs once
- [ ] `process` block runs once per item
- [ ] `end` block runs once after all items
- [ ] Error in one item doesn't stop others
- [ ] `-WhatIf` and `-Confirm` work (if SupportsShouldProcess)
- [ ] `-Verbose` shows per-item progress
- [ ] Output is correct for all input methods

## Next Steps

1. **Add Pester tests**: Use `pester-test-generator` skill to test pipeline scenarios
2. **Update help**: Add `.PARAMETER` help for pipeline attributes
3. **Add examples**: Show both parameter and pipeline usage in comment-based help
4. **Consider performance**: For large datasets, test streaming vs batch processing
5. **Chain cmdlets**: Test with other pipeline-enabled cmdlets

## Reference

- Pipeline mechanics: `Get-Help about_Pipelines`
- Parameter attributes: `Get-Help about_Functions_Advanced_Parameters`
- Processing blocks: `Get-Help about_Functions_Advanced_Methods`
- Best practices: `.github/instructions/powershell-scripting.instructions.md`
- Expert guidance: `.github/agents/powershell-expert.agent.md`
