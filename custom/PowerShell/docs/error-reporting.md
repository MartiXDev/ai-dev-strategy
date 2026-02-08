# Error Reporting Concepts

Source: https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/error-reporting-concepts

Windows PowerShell provides two mechanisms for reporting errors: one mechanism for **terminating errors** and another mechanism for **non-terminating errors**. It is important for your cmdlet to report errors correctly so that the host application that is running your cmdlets can react in an appropriate manner.

## Terminating Errors

### Definition
An error that prevents the cmdlet from continuing to process the current object or any further input objects, regardless of their content.

### When to Use
- Error prevents processing the current object AND all future objects
- Cmdlet explicitly should not continue regardless of content
- Cmdlet doesn't accept/return objects, or accepts/returns only one object
- Critical validation or initialization failures

### How to Report
```csharp
var error = new ErrorRecord(
    exception,              // The underlying exception
    "ErrorIdentifier",      // A string identifier for this error type
    ErrorCategory.InvalidOperation, // Error category
    targetObject            // The object being processed when error occurred
);
ThrowTerminatingError(error);
```

### Behavior
- Immediately stops the cmdlet
- No more records are processed
- Pipeline execution stops for this cmdlet
- Exception propagates to PowerShell runtime

## Non-Terminating Errors

### Definition
An error related to a specific input object that allows the cmdlet to continue processing other input objects.

### When to Use
- Error is specific to current input object
- Want cmdlet to continue processing remaining objects
- Error doesn't prevent processing future objects
- Per-record validation or processing failures

### How to Report
```csharp
var error = new ErrorRecord(
    exception,
    "ErrorIdentifier",
    ErrorCategory.InvalidOperation,
    targetObject
);
WriteError(error);
```

### Behavior
- Error is recorded but processing continues
- ProcessRecord continues with next pipeline object
- User can control behavior with `-ErrorAction` parameter
- Errors are collected in `$Error` automatic variable

## Decision Matrix

| Scenario | Error Type |
|----------|-----------|
| Cannot open required file for writing | Terminating |
| Missing required parameter | Terminating |
| Invalid parameter combination | Terminating |
| Cannot connect to required service and cmdlet has only one purpose | Terminating |
| Network timeout on one of many servers being processed | Non-terminating |
| Invalid data format in one input object | Non-terminating |
| Permission denied on one file in a collection | Non-terminating |
| Object doesn't exist (when processing multiple) | Non-terminating |

## ErrorRecord Construction

```csharp
public ErrorRecord(
    Exception exception,        // The underlying exception
    string errorId,            // Unique identifier for this error type
    ErrorCategory errorCategory, // Classification of the error
    object targetObject        // Object being operated on when error occurred
)
```

### Error Categories
- **NotSpecified** - Use when no other category fits
- **OpenError** - Opening a resource failed
- **CloseError** - Closing a resource failed
- **DeviceError** - Device reported error
- **DeadlockDetected** - Deadlock detected
- **InvalidArgument** - Argument is invalid
- **InvalidData** - Data is invalid
- **InvalidOperation** - Operation is invalid for current state
- **InvalidResult** - Result is invalid
- **InvalidType** - Type is invalid
- **MetadataError** - Metadata is corrupt
- **NotImplemented** - Feature not implemented
- **NotInstalled** - Resource not installed
- **ObjectNotFound** - Object cannot be found
- **OperationStopped** - Operation was stopped (Ctrl+C)
- **OperationTimeout** - Operation timed out
- **SyntaxError** - Syntax is incorrect
- **ParserError** - Parser error
- **PermissionDenied** - Permission denied
- **ResourceBusy** - Resource is busy
- **ResourceExists** - Resource already exists
- **ResourceUnavailable** - Resource is unavailable
- **ReadError** - Read operation failed
- **WriteError** - Write operation failed
- **FromStdErr** - Error from stderr stream
- **SecurityError** - Security violation

## Best Practices

### 1. Use Descriptive Error IDs
```csharp
// Good
"FileNotFound"
"InvalidConfigurationFormat"
"DatabaseConnectionFailed"

// Bad
"Error1"
"Err"
"Failed"
```

### 2. Choose Appropriate Error Category
Select the most specific category that describes the error condition.

### 3. Provide Meaningful Exception Messages
```csharp
// Good
new FileNotFoundException($"Configuration file not found: {configPath}")

// Bad
new Exception("Error")
```

### 4. Include Target Object
Always provide the object being processed when the error occurred for context.

### 5. Respect -ErrorAction
Non-terminating errors respect the `-ErrorAction` parameter:
- **Continue** (default) - Display error and continue
- **SilentlyContinue** - Suppress error and continue
- **Stop** - Treat as terminating error
- **Inquire** - Prompt user whether to continue
- **Ignore** - Completely ignore the error

### 6. Error Variable Support
Errors are automatically added to `$Error` and can be captured with `-ErrorVariable`:
```powershell
Get-MyData -ErrorVariable myErrors
```

## Common Patterns

### Pattern 1: Try-Catch with WriteError
```csharp
protected override void ProcessRecord()
{
    foreach (var item in Items)
    {
        try
        {
            ProcessItem(item);
        }
        catch (Exception ex)
        {
            var error = new ErrorRecord(
                ex,
                "ProcessItemFailed",
                ErrorCategory.InvalidOperation,
                item
            );
            WriteError(error);
            // Continue with next item
        }
    }
}
```

### Pattern 2: Validation with ThrowTerminatingError
```csharp
protected override void BeginProcessing()
{
    if (string.IsNullOrEmpty(RequiredPath))
    {
        var ex = new ArgumentException("Path cannot be null or empty");
        var error = new ErrorRecord(
            ex,
            "InvalidPath",
            ErrorCategory.InvalidArgument,
            RequiredPath
        );
        ThrowTerminatingError(error);
    }
}
```

### Pattern 3: Conditional Error Type
```csharp
protected override void ProcessRecord()
{
    try
    {
        if (!ValidateInput(InputObject))
        {
            if (StrictMode)
            {
                // Terminating in strict mode
                ThrowTerminatingError(CreateError("InvalidInput"));
            }
            else
            {
                // Non-terminating in normal mode
                WriteError(CreateError("InvalidInput"));
                return;
            }
        }
        
        ProcessValidInput(InputObject);
    }
    catch (Exception ex)
    {
        WriteError(new ErrorRecord(ex, "ProcessingFailed", 
            ErrorCategory.NotSpecified, InputObject));
    }
}
```

### Pattern 4: ShouldProcess with Error Handling
```csharp
protected override void ProcessRecord()
{
    if (ShouldProcess(target, "Perform operation"))
    {
        try
        {
            PerformOperation(target);
        }
        catch (UnauthorizedAccessException ex)
        {
            var error = new ErrorRecord(
                ex,
                "UnauthorizedAccess",
                ErrorCategory.PermissionDenied,
                target
            );
            WriteError(error);
        }
    }
}
```

## Testing Error Conditions

```powershell
# Test non-terminating error continues
$results = Get-MyData -Items @('valid', 'invalid', 'valid2') -ErrorAction SilentlyContinue
# Should have 2 results

# Test terminating error stops
try {
    Get-MyData -RequiredParam $null
} catch {
    # Should catch terminating error
}

# Capture errors in variable
Get-MyData -Items @('item1', 'item2') -ErrorVariable myErrors
# $myErrors contains error records
```
