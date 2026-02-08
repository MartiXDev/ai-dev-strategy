# PowerShell Cmdlet Development Documentation

This directory contains curated documentation from Microsoft Learn for PowerShell cmdlet development and best practices.

## Core Concepts

### Getting Started
- [Cmdlet Overview](cmdlet-overview.md) - Introduction to cmdlets, base classes, and architecture
- [Cmdlet Development Guidelines](cmdlet-development-guidelines.md) - Required, recommended, and advisory guidelines

### Cmdlet Fundamentals
- [Approved Verbs](approved-verbs.md) - Complete list of approved PowerShell verbs and naming conventions
- [Cmdlet Parameters](cmdlet-parameters.md) - Parameter types, attributes, validation, and parameter sets
- [Input Processing Methods](cmdlet-input-processing-methods.md) - BeginProcessing, ProcessRecord, EndProcessing lifecycle
- [Error Reporting](error-reporting.md) - Terminating vs non-terminating errors, ErrorRecord, best practices

## Quick Reference

### Cmdlet Base Classes
- **System.Management.Automation.Cmdlet** - Lightweight, minimal dependencies (most common)
- **System.Management.Automation.PSCmdlet** - Extended runtime access (scripts, providers, session state)

### Processing Methods (in order)
1. `BeginProcessing()` - One-time initialization
2. `ProcessRecord()` - Per-record processing (0 to N times)
3. `EndProcessing()` - One-time cleanup and summary
4. `StopProcessing()` - Called on Ctrl+C or terminating error

### Essential Attributes
- `[Cmdlet(VerbsCommon.Get, "Resource")]` - Declares class as cmdlet
- `[Parameter(Mandatory = true, Position = 0, ValueFromPipeline = true)]` - Declares parameter
- `[ValidateNotNullOrEmpty()]` - Validates parameter is not null/empty
- `[ValidateSet("Value1", "Value2")]` - Validates parameter against set
- `[Alias("AliasName")]` - Provides parameter alias

### Output Methods
- `WriteObject(object)` - Send to pipeline
- `WriteError(ErrorRecord)` - Non-terminating error
- `ThrowTerminatingError(ErrorRecord)` - Terminating error
- `WriteWarning(string)` - Warning message
- `WriteVerbose(string)` - Verbose message
- `WriteDebug(string)` - Debug message

## Approved Verb Categories

- **Common**: Get, Set, Add, Remove, New, Clear, Copy, Move, etc.
- **Data**: Import, Export, Convert, Backup, Restore, Sync, etc.
- **Lifecycle**: Install, Uninstall, Start, Stop, Enable, Disable, etc.
- **Diagnostic**: Test, Debug, Measure, Trace, Resolve, Repair, etc.
- **Communications**: Connect, Disconnect, Read, Write, Send, Receive, etc.

See [approved-verbs.md](approved-verbs.md) for complete list.

## Development Workflow

1. Choose approved verb and specific noun
2. Derive from `Cmdlet` or `PSCmdlet` base class
3. Add `[Cmdlet]` attribute to class
4. Define parameters with `[Parameter]` attributes
5. Add validation attributes as needed
6. Override processing methods (at minimum `ProcessRecord`)
7. Implement error handling (terminating vs non-terminating)
8. Add ShouldProcess support for destructive operations
9. Build and test with PowerShell
10. Create module manifest (.psd1) if distributing

## Best Practices Summary

✅ **DO**
- Use approved verbs from `Get-Verb`
- Follow Verb-Noun naming (e.g., `Get-Process`)
- Use Pascal casing for cmdlet names
- Support pipeline input where appropriate
- Implement proper error handling
- Validate parameters with attributes
- Provide comment-based help
- Support `-WhatIf` and `-Confirm` for changes

❌ **DON'T**
- Use non-approved verbs
- Use plural nouns (use singular)
- Do your own parameter parsing
- Throw exceptions for non-terminating errors
- Ignore PowerShell conventions
- Hardcode paths or assumptions about OS

## Planning & Architecture

- [Implementation Plan](implementation-plan.md) - Original plan for building the PowerShell Expert System

## Skills Reference

For focused code transformations on **existing** PowerShell code, see the skills directory:

- [Skills Overview](../skills/README.md) - Introduction to PowerShell transformation skills
- [module-builder](../skills/module-builder/SKILL.md) - Convert scripts to module structure
- [pester-test-generator](../skills/pester-test-generator/SKILL.md) - Generate Pester 5.x tests
- [powershell-modernizer](../skills/powershell-modernizer/SKILL.md) - Upgrade PS 5.1 to PS 7+
- [pipeline-support-adder](../skills/pipeline-support-adder/SKILL.md) - Add pipeline support to functions
- [gallery-publisher](../skills/gallery-publisher/SKILL.md) - Publish to PowerShell Gallery

## Related Resources

- **Online**: [PowerShell Cmdlet Documentation](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/cmdlet-overview)
- **Get approved verbs**: Run `Get-Verb` in PowerShell
- **SDK**: Install via NuGet: `Microsoft.PowerShell.SDK`

## Document Sources

All documentation is sourced from Microsoft Learn (learn.microsoft.com) and adapted for offline reference.

Last updated: 2026-02-08
