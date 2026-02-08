# Cmdlet Input Processing Methods

Source: https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/cmdlet-input-processing-methods

Cmdlets must override one or more of the input processing methods to perform their work. These methods allow the cmdlet to perform operations of pre-processing, input processing, and post-processing. These methods also allow you to stop cmdlet processing.

## Processing Lifecycle

PowerShell calls cmdlet processing methods in this order:

1. **BeginProcessing()** - Called once at the start
2. **ProcessRecord()** - Called once for each pipeline input object (0 to N times)
3. **EndProcessing()** - Called once at the end
4. **StopProcessing()** - Called if user interrupts (Ctrl+C) or terminating error occurs

## BeginProcessing Method

```csharp
protected override void BeginProcessing()
{
    // One-time initialization
    // Set up resources, validate parameters, prepare for processing
    // Called once per cmdlet instance in pipeline
}
```

### Use Cases
- Initialize resources (database connections, file handles, etc.)
- Validate parameter combinations
- Set up state that will be used across all records
- Perform one-time expensive operations

### Important Notes
- Called once per cmdlet instance in the pipeline
- Called even if there is no pipeline input
- Do NOT process individual records here

## ProcessRecord Method

```csharp
protected override void ProcessRecord()
{
    // Record-by-record processing
    // Handle each pipeline input object
    // Write output using WriteObject()
}
```

### Use Cases
- Process each pipeline input object
- Perform the main work of the cmdlet
- Write output objects to the pipeline
- Handle errors per record (non-terminating errors)

### Important Notes
- Called once for each input object from the pipeline
- Called 0 times if no pipeline input and no mandatory parameters from pipeline
- This is where most cmdlet logic lives
- Use `WriteObject()` to send output to pipeline
- Use `WriteError()` for non-terminating errors

## EndProcessing Method

```csharp
protected override void EndProcessing()
{
    // One-time cleanup and final output
    // Summarize results, close resources
}
```

### Use Cases
- Output summary information
- Close resources (files, connections, etc.)
- Aggregate results from all ProcessRecord calls
- Perform final validation or calculations

### Important Notes
- Called once after all records are processed
- **NOT called** if cmdlet is cancelled or terminating error occurs
- For guaranteed cleanup, implement `IDisposable` pattern

## StopProcessing Method

```csharp
protected override void StopProcessing()
{
    // Handle interruption (Ctrl+C or terminating error)
    // Clean up resources, cancel operations
}
```

### Use Cases
- Clean up resources when cmdlet is interrupted
- Cancel long-running operations
- Release locks or connections

### Important Notes
- Called when user presses Ctrl+C
- Called when terminating error occurs
- Should be quick and safe
- May be called from a different thread

## Resource Cleanup Best Practice

For guaranteed cleanup, implement the complete IDisposable pattern:

```csharp
public class MyCmdlet : Cmdlet, IDisposable
{
    private DatabaseConnection _connection;
    
    protected override void BeginProcessing()
    {
        _connection = new DatabaseConnection();
    }
    
    protected override void ProcessRecord()
    {
        // Use _connection
    }
    
    protected override void EndProcessing()
    {
        // Normal cleanup
        Dispose();
    }
    
    protected override void StopProcessing()
    {
        // Cleanup on interruption
        Dispose();
    }
    
    public void Dispose()
    {
        if (_connection != null)
        {
            _connection.Close();
            _connection = null;
        }
    }
}
```

## Common Patterns

### Simple Read-Only Cmdlet
Override only `ProcessRecord()`:
```csharp
protected override void ProcessRecord()
{
    var result = GetData(ParameterValue);
    WriteObject(result);
}
```

### Cmdlet with Aggregation
Override `ProcessRecord()` and `EndProcessing()`:
```csharp
private List<object> _results = new List<object>();

protected override void ProcessRecord()
{
    _results.Add(ProcessInput(InputObject));
}

protected override void EndProcessing()
{
    var summary = AggregateResults(_results);
    WriteObject(summary);
}
```

### Cmdlet with Initialization
Override all three main methods:
```csharp
protected override void BeginProcessing()
{
    ValidateParameters();
    InitializeResources();
}

protected override void ProcessRecord()
{
    var result = ProcessItem(InputObject);
    WriteObject(result);
}

protected override void EndProcessing()
{
    CleanupResources();
}
```

## Method Override Requirements

**At least one** of the following must be overridden:
- BeginProcessing()
- ProcessRecord()
- EndProcessing()

**Most common pattern**: Override `ProcessRecord()` only.

## Output Methods

Use these methods within processing methods to produce output:

- **WriteObject(object)** - Send object to pipeline
- **WriteObject(object, bool enumerateCollection)** - Send object or enumerate collection
- **WriteError(ErrorRecord)** - Write non-terminating error
- **WriteWarning(string)** - Write warning message
- **WriteVerbose(string)** - Write verbose message
- **WriteDebug(string)** - Write debug message
- **WriteProgress(ProgressRecord)** - Display progress bar
- **WriteInformation(InformationRecord)** - Write information message

## Error Handling in Processing Methods

### Non-Terminating Errors
Use `WriteError()` in ProcessRecord to allow cmdlet to continue with next record:
```csharp
try
{
    ProcessItem(item);
}
catch (Exception ex)
{
    var error = new ErrorRecord(ex, "ProcessingFailed", 
        ErrorCategory.InvalidOperation, item);
    WriteError(error);
}
```

### Terminating Errors
Use `ThrowTerminatingError()` to stop all processing:
```csharp
if (criticalValidationFailed)
{
    var error = new ErrorRecord(new InvalidOperationException(), 
        "CriticalError", ErrorCategory.InvalidOperation, null);
    ThrowTerminatingError(error);
}
```
