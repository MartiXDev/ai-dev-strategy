# PowerShell Expert System

A comprehensive AI-powered system for creating and editing top-quality PowerShell 7+ scripts, modules, and binary cmdlets.

## Overview

This system provides **three complementary approaches** to PowerShell development assistance:

### 1. **PowerShell Instructions** (`.github/instructions/powershell-scripting.instructions.md`)
- **When**: Automatically activated when editing `.ps1`, `.psm1`, `.psd1`, or `.cs` files
- **What**: Provides scripting conventions, best practices, and style guidelines
- **Use for**: Writing NEW code with best practices
- **Think of it as**: Your always-on PowerShell linter and style guide

### 2. **PowerShell Expert Agent** (`.github/agents/powershell-expert.agent.md`)
- **When**: Invoke explicitly for complex PowerShell tasks
- **What**: Deep expertise in module architecture, binary cmdlet development, advanced patterns
- **Use for**: Designing NEW modules from scratch, complex architecture decisions
- **Think of it as**: Your senior PowerShell architect consultant

### 3. **PowerShell Skills** (`custom/PowerShell/skills/*/SKILL.md`)
- **When**: Invoke explicitly for focused code transformations
- **What**: Focused, actionable workflows for transforming EXISTING code
- **Use for**: Converting scripts to modules, adding tests, modernizing syntax, adding pipeline support
- **Think of it as**: Your specialized refactoring toolkit

**Key Insight**: Instructions write new code, Agent designs architecture, Skills transform existing code.

## When to Use What

### Use Instructions (Automatic)
✅ Writing NEW script functions  
✅ Adding parameter validation  
✅ Implementing error handling  
✅ Cross-platform path handling  
✅ Following PowerShell conventions  
✅ Daily scripting tasks  

**How**: Just edit any PowerShell file — instructions are automatically applied.

### Use PowerShell Expert Agent (Invoke Explicitly)
✅ Designing a NEW PowerShell module from scratch  
✅ Creating binary cmdlets in C#  
✅ Complex module architecture decisions  
✅ Performance-critical automation design  
✅ Advanced cmdlet scenarios  

**How**: Use the task tool or invoke the agent explicitly:
```
@agent powershell-expert Design a module for managing cloud resources with cmdlets Get-CloudResource, New-CloudResource, Remove-CloudResource
```

### Use PowerShell Skills (Invoke Explicitly)
✅ **Convert EXISTING scripts to module** → `module-builder`  
✅ **Add tests to EXISTING functions** → `pester-test-generator`  
✅ **Modernize PS 5.1 → PS 7+** → `powershell-modernizer`  
✅ **Add pipeline to EXISTING function** → `pipeline-support-adder`  
✅ **Publish to PowerShell Gallery** → `gallery-publisher`  

**How**: Reference the skill when you need focused transformation:
```
Use the module-builder skill to convert my Get-ServerStatus.ps1 script into a proper module
Use the pester-test-generator skill to add tests for Get-UserReport function
```

See [Skills README](skills/README.md) for detailed skill documentation.

## Quick Start Examples

### Example 1: Simple Script Function
The instructions will automatically guide you to:
```powershell
function Get-UserReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Username
    )
    
    process {
        foreach ($user in $Username) {
            # Process each user
            [PSCustomObject]@{
                Username = $user
                LastLogin = (Get-Date)
                Status = 'Active'
            }
        }
    }
}
```

### Example 2: Module Development
Invoke the PowerShell Expert agent for:
- Module manifest creation
- Public/Private function organization
- Binary cmdlet integration
- Pester test structure
- PowerShell Gallery publishing

### Example 3: Binary Cmdlet
The agent will help you create:
```csharp
[Cmdlet(VerbsCommon.Get, "CompanyResource")]
[OutputType(typeof(CompanyResource))]
public class GetCompanyResourceCommand : Cmdlet
{
    [Parameter(Mandatory = true, ValueFromPipeline = true)]
    public string[] Name { get; set; }
    
    protected override void ProcessRecord()
    {
        foreach (var name in Name)
        {
            var resource = FetchResource(name);
            WriteObject(resource);
        }
    }
}
```

## Features

### PowerShell 7+ Cross-Platform
- ✅ Windows, Linux, macOS compatibility
- ✅ Cross-platform path handling
- ✅ OS detection patterns
- ✅ Environment variable abstraction

### Approved Verb Compliance
- ✅ Always uses approved PowerShell verbs (`Get-Verb`)
- ✅ Verb-Noun naming convention
- ✅ Proper cmdlet naming patterns

### Error Handling
- ✅ Terminating vs non-terminating errors
- ✅ ErrorRecord construction
- ✅ Proper error categories
- ✅ Try-Catch-Finally patterns

### Pipeline Support
- ✅ `ValueFromPipeline` implementation
- ✅ `ValueFromPipelineByPropertyName` support
- ✅ Begin/Process/End block structure
- ✅ Efficient streaming

### Parameter Validation
- ✅ Built-in validation attributes
- ✅ Custom validation scripts
- ✅ Parameter sets
- ✅ Dynamic parameters

### ShouldProcess Support
- ✅ `-WhatIf` and `-Confirm` implementation
- ✅ ConfirmImpact configuration
- ✅ Destructive operation protection

### Testing with Pester 5.x
- ✅ Unit test structure
- ✅ Integration test patterns
- ✅ Mocking and test isolation
- ✅ Code coverage

## Directory Structure

```
custom/PowerShell/
├── README.md                          # This file
├── skills/                            # 🆕 Focused transformation skills
│   ├── README.md                     # Skills overview and usage guide
│   ├── module-builder/               # Convert scripts → module
│   │   └── SKILL.md
│   ├── pester-test-generator/        # Add tests to existing functions
│   │   └── SKILL.md
│   ├── powershell-modernizer/        # Upgrade PS 5.1 → PS 7+
│   │   └── SKILL.md
│   ├── pipeline-support-adder/       # Add pipeline to functions
│   │   └── SKILL.md
│   └── gallery-publisher/            # Publish to PowerShell Gallery
│       └── SKILL.md
├── docs/                              # Microsoft Learn documentation (offline)
│   ├── 00-index.md                   # Documentation index
│   ├── implementation-plan.md        # Original implementation plan
│   ├── cmdlet-overview.md
│   ├── approved-verbs.md
│   ├── cmdlet-parameters.md
│   ├── cmdlet-input-processing-methods.md
│   ├── cmdlet-development-guidelines.md
│   └── error-reporting.md
├── examples/                          # Reference implementations
│   ├── basic-script.ps1              # Simple script with best practices
│   ├── advanced-function.ps1         # Advanced function with all features
│   ├── module-structure/             # Complete module example
│   │   ├── MyModule.psd1
│   │   ├── MyModule.psm1
│   │   ├── Public/
│   │   └── Private/
│   └── binary-cmdlet/                # C# cmdlet example
│       ├── MyCmdlet.csproj
│       └── GetMyResourceCommand.cs
└── cheat-sheet.md                    # Quick reference guide

.github/
├── instructions/
│   └── powershell-scripting.instructions.md  # Auto-applied conventions
└── agents/
    └── powershell-expert.agent.md            # Expert agent for complex tasks
```

## Integration with Overnight Workflow

PowerShell tasks can be executed overnight using the task category `[POWERSHELL]`:

```markdown
# tasks.md
- [ ] T001 [POWERSHELL] Create deployment automation script
- [ ] T002 [POWERSHELL] Build PowerShell module for API client
- [ ] T003 [POWERSHELL] Write Pester tests for existing scripts
```

Configuration in `overnight-config.json`:
```json
"POWERSHELL": {
  "agent": ".github/agents/powershell-expert.agent.md",
  "overnightModel": "gpt-4.1-mini",
  "daytimeModel": "claude-sonnet-4-5"
}
```

## Documentation Reference

All documentation is cached locally in `docs/` for offline access:

- **[Documentation Index](docs/00-index.md)** - Start here
- **[Cmdlet Overview](docs/cmdlet-overview.md)** - Cmdlet fundamentals
- **[Approved Verbs](docs/approved-verbs.md)** - Complete verb list
- **[Parameters](docs/cmdlet-parameters.md)** - Parameter attributes and validation
- **[Processing Methods](docs/cmdlet-input-processing-methods.md)** - Cmdlet lifecycle
- **[Error Reporting](docs/error-reporting.md)** - Error handling patterns

## Best Practices Summary

### ✅ DO
- Use approved verbs from `Get-Verb`
- Implement pipeline support with `ValueFromPipeline`
- Add parameter validation with `[ValidateXxx]` attributes
- Use `[CmdletBinding()]` for advanced functions
- Handle errors appropriately (terminating vs non-terminating)
- Support `-WhatIf` and `-Confirm` for destructive operations
- Write comment-based help for all exported functions
- Test with Pester 5.x
- Use cross-platform path handling

### ❌ DON'T
- Use non-approved verbs or aliases in production code
- Use plural nouns (always singular)
- Hardcode Windows-specific paths
- Suppress errors without handling them
- Use `Write-Host` in functions (use `Write-Output` or `Write-Verbose`)
- Use `Invoke-Expression` with user input
- Ignore cross-platform compatibility

## Common Patterns

### Script Function Template
See [examples/advanced-function.ps1](examples/advanced-function.ps1)

### Module Template
See [examples/module-structure/](examples/module-structure/)

### Binary Cmdlet Template
See [examples/binary-cmdlet/](examples/binary-cmdlet/)

## Troubleshooting

### Instructions Not Activating?
- Verify file extension is `.ps1`, `.psm1`, `.psd1`, or `.cs`
- Check the `applyTo` pattern in `.github/instructions/powershell-scripting.instructions.md`

### Agent Not Working?
- Verify agent file exists at `.github/agents/powershell-expert.agent.md`
- Check `overnight-config.json` for correct agent path in `POWERSHELL` category
- Invoke explicitly if not using overnight execution

### Build Errors for Binary Cmdlets?
- Ensure `PowerShellStandard.Library` NuGet package is installed
- Target framework should be `net6.0` or later
- Run `dotnet restore` before `dotnet build`

## Resources

- **Online Documentation**: [PowerShell Cmdlet Development](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/cmdlet-overview)
- **Get Approved Verbs**: Run `Get-Verb` in PowerShell
- **PowerShell Gallery**: [powershellgallery.com](https://www.powershellgallery.com/)
- **Pester Testing**: [pester.dev](https://pester.dev/)

## Version History

- **v1.1.0** (2026-02-08) - PowerShell Skills added
  - 5 new skills for transforming existing code
  - module-builder: Convert scripts → modules
  - pester-test-generator: Add tests to functions
  - powershell-modernizer: Upgrade PS 5.1 → PS 7+
  - pipeline-support-adder: Add pipeline support
  - gallery-publisher: Publish to PowerShell Gallery

- **v1.0.0** (2026-02-08) - Initial implementation
  - PowerShell scripting instructions
  - PowerShell Expert agent
  - Microsoft Learn documentation cache
  - Example scripts and templates
  - Integration with overnight workflow

## Contributing

To enhance this system:

1. **Add new patterns**: Update `.github/instructions/powershell-scripting.instructions.md`
2. **Extend agent knowledge**: Edit `.github/agents/powershell-expert.agent.md`
3. **Add examples**: Create new scripts in `examples/`
4. **Update documentation**: Keep `docs/` in sync with Microsoft Learn

## License

This PowerShell expert system is part of the ai-dev-strategy repository. See main repository LICENSE.

---

**Need help?** 
- For writing NEW code → The instructions guide you automatically
- For designing NEW architecture → Invoke the PowerShell Expert agent
- For transforming EXISTING code → Use one of the 5 PowerShell skills
- For cmdlet development reference → Check `docs/` directory
- For skill documentation → See `skills/README.md`
