---
name: powershell-pester-test-generator
description: Generate comprehensive Pester 5.x tests for existing PowerShell functions with BeforeAll, Describe, Context, It blocks, parameter validation, pipeline scenarios, and edge cases. Use this when asked to add tests, create Pester tests, retrofit testing, write unit tests for PowerShell, or generate test coverage.
license: MIT
---

# PowerShell Pester Test Generator (powershell-pester-test-generator)

Automatically generate Pester 5.x test files for existing PowerShell functions with comprehensive coverage of happy paths, error cases, pipeline scenarios, and edge cases.

## When to Use

- Existing functions without tests (retrofit testing)
- Need tests before refactoring (safety net)
- Want consistent test structure across codebase
- Learning Pester best practices through examples
- TDD retrofit for legacy code

**NOT for**: Writing new functions (write tests first with TDD instead).

## Prerequisites

- PowerShell 7+ installed
- Pester 5.x installed: `Install-Module -Name Pester -Force -SkipPublisherCheck`
- Existing PowerShell function(s) to test
- Functions should have `[CmdletBinding()]` and parameter blocks

## Core Workflow

### 1. Analyze Function Signature

Examine the function to understand:
- Parameters (mandatory, optional, types)
- Pipeline support (`ValueFromPipeline`, `ValueFromPipelineByPropertyName`)
- Parameter sets
- Validation attributes
- Return type
- Error handling (`ShouldProcess`, error actions)

Example function:
```powershell
function Get-UserReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,
        
        [Parameter()]
        [ValidateSet('Summary', 'Detailed')]
        [string]$ReportType = 'Summary'
    )
    
    process {
        # Function logic
        [PSCustomObject]@{
            Username = $Username
            Type = $ReportType
            Timestamp = Get-Date
        }
    }
}
```

### 2. Generate Test File Structure

Create test file with Pester 5.x structure:

```powershell
# Tests/Get-UserReport.Tests.ps1
BeforeAll {
    # Import the function or module
    . $PSScriptRoot\..\Public\Get-UserReport.ps1
    # OR: Import-Module $PSScriptRoot\..\MyModule.psd1 -Force
}

Describe 'Get-UserReport' {
    Context 'Parameter validation' {
        It 'Should accept mandatory Username parameter' {
            # Test here
        }
        
        It 'Should reject null or empty Username' {
            # Test here
        }
        
        It 'Should accept valid ReportType values' {
            # Test here
        }
        
        It 'Should reject invalid ReportType values' {
            # Test here
        }
    }
    
    Context 'Basic functionality' {
        It 'Should return PSCustomObject with correct properties' {
            # Test here
        }
        
        It 'Should default to Summary report type' {
            # Test here
        }
        
        It 'Should accept Detailed report type' {
            # Test here
        }
    }
    
    Context 'Pipeline support' {
        It 'Should accept username from pipeline' {
            # Test here
        }
        
        It 'Should process multiple usernames from pipeline' {
            # Test here
        }
    }
    
    Context 'Edge cases' {
        It 'Should handle special characters in username' {
            # Test here
        }
        
        It 'Should handle very long usernames' {
            # Test here
        }
    }
}
```

### 3. Write Individual Test Cases

Fill in each `It` block with assertions:

#### Parameter Validation Tests

```powershell
Context 'Parameter validation' {
    It 'Should have Username as mandatory parameter' {
        $cmd = Get-Command Get-UserReport
        $param = $cmd.Parameters['Username']
        $param.Attributes.Mandatory | Should -BeTrue
    }
    
    It 'Should reject null or empty Username' {
        { Get-UserReport -Username $null } | Should -Throw
        { Get-UserReport -Username '' } | Should -Throw
    }
    
    It 'Should accept valid ReportType values' {
        { Get-UserReport -Username 'test' -ReportType 'Summary' } | Should -Not -Throw
        { Get-UserReport -Username 'test' -ReportType 'Detailed' } | Should -Not -Throw
    }
    
    It 'Should reject invalid ReportType values' {
        { Get-UserReport -Username 'test' -ReportType 'Invalid' } | Should -Throw
    }
}
```

#### Happy Path Tests

```powershell
Context 'Basic functionality' {
    It 'Should return PSCustomObject with correct properties' {
        $result = Get-UserReport -Username 'alice'
        $result | Should -BeOfType [PSCustomObject]
        $result.Username | Should -Be 'alice'
        $result.Type | Should -BeIn @('Summary', 'Detailed')
        $result.Timestamp | Should -BeOfType [DateTime]
    }
    
    It 'Should default to Summary report type' {
        $result = Get-UserReport -Username 'bob'
        $result.Type | Should -Be 'Summary'
    }
    
    It 'Should accept Detailed report type' {
        $result = Get-UserReport -Username 'charlie' -ReportType 'Detailed'
        $result.Type | Should -Be 'Detailed'
    }
}
```

#### Pipeline Tests

```powershell
Context 'Pipeline support' {
    It 'Should accept username from pipeline' {
        $result = 'david' | Get-UserReport
        $result.Username | Should -Be 'david'
    }
    
    It 'Should process multiple usernames from pipeline' {
        $results = @('eve', 'frank', 'grace') | Get-UserReport
        $results | Should -HaveCount 3
        $results[0].Username | Should -Be 'eve'
        $results[1].Username | Should -Be 'frank'
        $results[2].Username | Should -Be 'grace'
    }
}
```

#### Edge Case Tests

```powershell
Context 'Edge cases' {
    It 'Should handle special characters in username' {
        $result = Get-UserReport -Username 'user@domain.com'
        $result.Username | Should -Be 'user@domain.com'
    }
    
    It 'Should handle very long usernames' {
        $longName = 'a' * 256
        $result = Get-UserReport -Username $longName
        $result.Username | Should -Be $longName
    }
    
    It 'Should handle Unicode characters' {
        $result = Get-UserReport -Username 'ユーザー'
        $result.Username | Should -Be 'ユーザー'
    }
}
```

### 4. Add Setup/Teardown if Needed

For tests requiring state management:

```powershell
BeforeAll {
    # Module-wide setup
    Import-Module $PSScriptRoot\..\MyModule.psd1 -Force
    
    # Create test data directory
    $script:TestDataPath = Join-Path $TestDrive 'TestData'
    New-Item -Path $script:TestDataPath -ItemType Directory -Force
}

Describe 'Get-UserReport' {
    BeforeEach {
        # Per-test setup (runs before each It block)
        $script:TestFile = Join-Path $TestDataPath "test-$(New-Guid).txt"
    }
    
    AfterEach {
        # Per-test cleanup (runs after each It block)
        if (Test-Path $script:TestFile) {
            Remove-Item $script:TestFile -Force
        }
    }
    
    # ... test contexts ...
}
```

### 5. Run Tests

Execute with Pester 5.x:

```powershell
# Run all tests in file
Invoke-Pester -Path .\Tests\Get-UserReport.Tests.ps1

# Run with detailed output
Invoke-Pester -Path .\Tests\Get-UserReport.Tests.ps1 -Output Detailed

# Run specific test
Invoke-Pester -Path .\Tests\Get-UserReport.Tests.ps1 -FullNameFilter '*Pipeline*'

# Generate code coverage report
$config = New-PesterConfiguration
$config.Run.Path = '.\Tests'
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = '.\Public\*.ps1'
Invoke-Pester -Configuration $config
```

## Decision Tree

```
Function to test → Has parameters?
    ├─ Yes → Mandatory params?
    │   ├─ Yes → Add parameter validation tests
    │   │        Test mandatory enforcement
    │   │
    │   └─ No → Test default values work
    │
    └─ No parameters → Test basic execution
        Add happy path tests
        
→ Has pipeline support?
    ├─ Yes → Add pipeline tests (single + multiple values)
    └─ No → Skip pipeline tests

→ Has validation attributes?
    ├─ Yes → Test validation enforcement (ValidateSet, ValidateRange, etc.)
    └─ No → Skip validation tests

→ Has error handling?
    ├─ Yes → Test error scenarios, ShouldProcess
    └─ No → Focus on happy path
    
→ Complex logic/edge cases?
    ├─ Yes → Add edge case context (special chars, empty, null, large data)
    └─ No → Basic tests sufficient
```

## Example: Complete Test File

**Function**: `Get-FileMetadata.ps1`

```powershell
function Get-FileMetadata {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript({ Test-Path $_ })]
        [string]$Path,
        
        [Parameter()]
        [switch]$IncludeHash
    )
    
    process {
        $item = Get-Item -Path $Path
        $result = [PSCustomObject]@{
            Name = $item.Name
            Size = $item.Length
            Created = $item.CreationTime
        }
        
        if ($IncludeHash) {
            $hash = Get-FileHash -Path $Path -Algorithm SHA256
            $result | Add-Member -NotePropertyName 'Hash' -NotePropertyValue $hash.Hash
        }
        
        $result
    }
}
```

**Generated Test**: `Tests/Get-FileMetadata.Tests.ps1`

```powershell
BeforeAll {
    . $PSScriptRoot\..\Public\Get-FileMetadata.ps1
}

Describe 'Get-FileMetadata' {
    BeforeAll {
        # Create test file in Pester's automatic test drive
        $script:TestFile = Join-Path $TestDrive 'test.txt'
        'Test content' | Out-File -FilePath $script:TestFile -Encoding utf8
    }
    
    Context 'Parameter validation' {
        It 'Should have Path as mandatory parameter' {
            $cmd = Get-Command Get-FileMetadata
            $param = $cmd.Parameters['Path']
            $param.Attributes.Mandatory | Should -Contain $true
        }
        
        It 'Should reject non-existent path' {
            { Get-FileMetadata -Path 'C:\NonExistent\File.txt' } | Should -Throw
        }
        
        It 'Should accept valid file path' {
            { Get-FileMetadata -Path $script:TestFile } | Should -Not -Throw
        }
    }
    
    Context 'Basic functionality' {
        It 'Should return PSCustomObject with required properties' {
            $result = Get-FileMetadata -Path $script:TestFile
            $result | Should -BeOfType [PSCustomObject]
            $result.PSObject.Properties.Name | Should -Contain 'Name'
            $result.PSObject.Properties.Name | Should -Contain 'Size'
            $result.PSObject.Properties.Name | Should -Contain 'Created'
        }
        
        It 'Should return correct file name' {
            $result = Get-FileMetadata -Path $script:TestFile
            $result.Name | Should -Be 'test.txt'
        }
        
        It 'Should return file size greater than zero' {
            $result = Get-FileMetadata -Path $script:TestFile
            $result.Size | Should -BeGreaterThan 0
        }
        
        It 'Should return valid creation time' {
            $result = Get-FileMetadata -Path $script:TestFile
            $result.Created | Should -BeOfType [DateTime]
            $result.Created | Should -BeLessThan (Get-Date)
        }
    }
    
    Context 'IncludeHash switch' {
        It 'Should not include hash by default' {
            $result = Get-FileMetadata -Path $script:TestFile
            $result.PSObject.Properties.Name | Should -Not -Contain 'Hash'
        }
        
        It 'Should include hash when switch is specified' {
            $result = Get-FileMetadata -Path $script:TestFile -IncludeHash
            $result.PSObject.Properties.Name | Should -Contain 'Hash'
        }
        
        It 'Should return valid SHA256 hash' {
            $result = Get-FileMetadata -Path $script:TestFile -IncludeHash
            $result.Hash | Should -MatchExactly '^[A-F0-9]{64}$'
        }
    }
    
    Context 'Pipeline support' {
        It 'Should accept path from pipeline' {
            $result = $script:TestFile | Get-FileMetadata
            $result.Name | Should -Be 'test.txt'
        }
        
        It 'Should accept path from pipeline by property name' {
            $obj = [PSCustomObject]@{ Path = $script:TestFile }
            $result = $obj | Get-FileMetadata
            $result.Name | Should -Be 'test.txt'
        }
        
        It 'Should process multiple files from pipeline' {
            $file1 = Join-Path $TestDrive 'file1.txt'
            $file2 = Join-Path $TestDrive 'file2.txt'
            'Content1' | Out-File $file1
            'Content2' | Out-File $file2
            
            $results = @($file1, $file2) | Get-FileMetadata
            $results | Should -HaveCount 2
            $results[0].Name | Should -Be 'file1.txt'
            $results[1].Name | Should -Be 'file2.txt'
        }
    }
    
    Context 'Edge cases' {
        It 'Should handle files with special characters in name' {
            $specialFile = Join-Path $TestDrive 'test file (copy) [1].txt'
            'Test' | Out-File $specialFile
            $result = Get-FileMetadata -Path $specialFile
            $result.Name | Should -Be 'test file (copy) [1].txt'
        }
        
        It 'Should handle empty files' {
            $emptyFile = Join-Path $TestDrive 'empty.txt'
            New-Item -Path $emptyFile -ItemType File -Force
            $result = Get-FileMetadata -Path $emptyFile
            $result.Size | Should -Be 0
        }
        
        It 'Should handle large files' -Skip {
            # Skipped in CI - takes too long
            # Manual test: Create 1GB file and verify
        }
    }
}
```

## Common Test Patterns

### Testing ShouldProcess Functions

```powershell
Context 'ShouldProcess support' {
    It 'Should support WhatIf' {
        # Capture WhatIf output
        $result = Set-MyData -Name 'test' -WhatIf
        # Verify no changes were made
    }
    
    It 'Should prompt for confirmation when ConfirmPreference is low' {
        # Test with -Confirm
    }
}
```

### Testing Error Handling

```powershell
Context 'Error handling' {
    It 'Should throw descriptive error for invalid input' {
        { Get-MyData -Id -1 } | Should -Throw -ExpectedMessage '*Invalid ID*'
    }
    
    It 'Should write non-terminating error with ErrorAction Continue' {
        $result = Get-MyData -Id 999 -ErrorAction SilentlyContinue -ErrorVariable err
        $err | Should -Not -BeNullOrEmpty
    }
}
```

### Testing Output Types

```powershell
Context 'Output validation' {
    It 'Should return string type' {
        $result = Get-MyData -Id 1
        $result | Should -BeOfType [string]
    }
    
    It 'Should return array when multiple items exist' {
        $results = Get-MyData -All
        $results | Should -BeOfType [array]
        $results.Count | Should -BeGreaterThan 0
    }
}
```

## Best Practices

### Test Organization

✅ **DO**:
- One test file per function (`Get-MyData.Tests.ps1`)
- Use `Context` to group related tests
- Use descriptive `It` block names
- Test both success and failure paths
- Include edge cases
- Use `BeforeAll` for setup, not `BeforeEach` (performance)

❌ **DON'T**:
- Mix tests for multiple functions in one file
- Write tests dependent on execution order
- Use hard-coded paths (use `$TestDrive` instead)
- Skip error case testing
- Forget to test pipeline support

### Pester 5.x Specific

✅ **Use**:
- `BeforeAll` instead of `BeforeDiscovery` for most cases
- `-Path` parameter (not `-Script`)
- `Should -Be`, `Should -Contain` (not `Should Be`)
- `$TestDrive` for temp files (auto-cleaned)

❌ **Avoid**:
- Pester 4.x syntax (`Should` without `-`)
- Global state changes without cleanup
- Tests that require internet connectivity (or tag with `-Tag 'Integration'`)

### Coverage Goals

Aim for:
- **80%+ code coverage** for public functions
- **100% coverage** for critical/security functions
- All parameter combinations tested
- All error paths tested
- All `if/else` branches tested

## Anti-Patterns to Avoid

- ❌ Testing implementation details (private functions, internal state)
- ❌ Tests dependent on specific timing or environment
- ❌ Not using `$TestDrive` for file system tests
- ❌ Hardcoding expected values instead of calculating them
- ❌ Overly complex tests (test the test!)
- ❌ Not testing negative cases (what should fail?)

## Next Steps

1. **Run tests frequently**: `Invoke-Pester` after every change
2. **Integrate with CI/CD**: Run tests on every commit
3. **Track coverage**: Use `CodeCoverage` configuration
4. **Refactor with confidence**: Tests act as safety net
5. **Document test scenarios**: Add comments for complex test logic

## Reference

- Pester 5.x docs: `Get-Help about_Pester`
- Assertion reference: `Get-Help Should -Full`
- Configuration: `Get-Help New-PesterConfiguration -Full`
- Best practices: `.github/instructions/powershell-scripting.instructions.md`
