# Cmdlet Development Guidelines

Source: https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/cmdlet-development-guidelines

The topics in this section provide development guidelines that you can use to produce well-formed cmdlets. By leveraging the common functionality provided by the Windows PowerShell runtime and by following these guidelines, you can develop robust cmdlets with minimal effort and provide the user with a consistent experience. Additionally, you will reduce the test burden because common functionality does not require retesting.

## Guidelines Categories

- **Required Development Guidelines** - Must follow for cmdlet compliance
- **Strongly Encouraged Development Guidelines** - Should follow for best practices
- **Advisory Development Guidelines** - Consider following for optimal experience

## Key Principles

1. **Consistency** - Follow PowerShell naming and behavior conventions
2. **Simplicity** - Leverage PowerShell runtime features instead of reimplementing
3. **Robustness** - Handle errors appropriately and validate input
4. **Composability** - Design cmdlets to work well in pipelines
5. **Documentation** - Provide clear help and examples
