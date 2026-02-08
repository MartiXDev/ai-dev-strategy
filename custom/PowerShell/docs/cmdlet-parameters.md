# Cmdlet Parameters

Source: https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/cmdlet-parameters

Cmdlet parameters provide the mechanism that allows a cmdlet to accept input. Parameters can accept input directly from the command line, or from objects passed to the cmdlet through the pipeline. The arguments (also known as values) of these parameters can specify the input that the cmdlet accepts, how the cmdlet should perform its actions, and the data that the cmdlet returns to the pipeline.

## Parameter Types

### Named Parameters
Standard parameters that can be specified by name on the command line.

### Positional Parameters
Parameters that can be specified without naming them, based on their position in the command.

### Switch Parameters
Boolean parameters that don't require a value. Their presence indicates `$true`, absence indicates `$false`.

### Required Parameters
Parameters that must be provided for the cmdlet to execute.

### Optional Parameters
Parameters that have default values or are not necessary for cmdlet execution.

### Dynamic Parameters
Parameters that are added to the cmdlet at runtime based on the value of another parameter or runtime conditions.

## Parameter Declaration

Parameters are declared as public properties of the cmdlet class, decorated with the `[Parameter()]` attribute.

```csharp
[Parameter(
    Position = 0,
    Mandatory = true,
    ValueFromPipeline = true,
    ValueFromPipelineByPropertyName = true,
    HelpMessage = "Specifies the name of the resource"
)]
[ValidateNotNullOrEmpty()]
[Alias("Name")]
public string ResourceName { get; set; }
```

## Parameter Attributes

### Parameter Attribute Properties
- **Mandatory** - Specifies if the parameter is required
- **Position** - Specifies the position for positional parameter
- **ValueFromPipeline** - Accepts value from pipeline object
- **ValueFromPipelineByPropertyName** - Accepts value from pipeline object property matching parameter name
- **ValueFromRemainingArguments** - Accepts all remaining arguments
- **HelpMessage** - Short help message for the parameter
- **ParameterSetName** - Specifies which parameter set this parameter belongs to

## Validation Attributes

### ValidateNotNull
Ensures the parameter value is not null.

### ValidateNotNullOrEmpty
Ensures the parameter value is not null or empty (for strings, arrays, collections).

### ValidateCount
Validates the number of elements in an array/collection parameter.

### ValidateLength
Validates the length of a string parameter.

### ValidateRange
Validates that a numeric parameter falls within a specified range.

### ValidatePattern
Validates that a string parameter matches a regular expression pattern.

### ValidateSet
Validates that a parameter value matches one of a predefined set of values.

### ValidateScript
Validates a parameter value using a custom script block.

## Parameter Sets

Parameter sets allow a cmdlet to expose different groups of parameters for different scenarios. Each parameter set should have at least one unique parameter (ideally a required one).

```csharp
// Parameter set "ByName"
[Parameter(Mandatory = true, ParameterSetName = "ByName")]
public string Name { get; set; }

// Parameter set "ById"
[Parameter(Mandatory = true, ParameterSetName = "ById")]
public int Id { get; set; }

// Common to both sets
[Parameter(ParameterSetName = "ByName")]
[Parameter(ParameterSetName = "ById")]
public SwitchParameter Force { get; set; }
```

## Parameter Aliases

Use the `[Alias()]` attribute to provide alternative names for parameters:

```csharp
[Parameter()]
[Alias("CN", "MachineName")]
public string ComputerName { get; set; }
```

## Common Parameters

PowerShell automatically adds common parameters to all cmdlets:
- **Verbose** - Provides detailed information about the operation
- **Debug** - Provides debugging information
- **ErrorAction** - Specifies how to respond to errors
- **ErrorVariable** - Stores errors in a variable
- **WarningAction** - Specifies how to respond to warnings
- **WarningVariable** - Stores warnings in a variable
- **OutVariable** - Stores output in a variable
- **OutBuffer** - Determines buffer size for output

## ShouldProcess Parameters

When a cmdlet supports ShouldProcess, PowerShell automatically adds:
- **WhatIf** - Shows what would happen without executing
- **Confirm** - Prompts for confirmation before executing

## Best Practices

1. Use approved parameter names from standard cmdlet parameters list
2. Use singular nouns for parameter names (e.g., `ComputerName`, not `ComputerNames`)
3. Use Pascal casing for parameter names
4. Provide meaningful help messages
5. Use appropriate validation attributes
6. Design parameter sets to avoid ambiguity
7. Use `SwitchParameter` type for boolean flags
8. Accept pipeline input when appropriate
9. Provide sensible defaults for optional parameters
10. Use strongly-typed parameters (avoid `object` type when possible)
