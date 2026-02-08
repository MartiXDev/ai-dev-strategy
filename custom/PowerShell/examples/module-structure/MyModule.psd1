# MyModule Module Manifest
@{
    RootModule = 'MyModule.psm1'
    ModuleVersion = '1.0.0'
    GUID = '12345678-1234-1234-1234-123456789012'
    
    Author = 'Your Name'
    CompanyName = 'Your Company'
    Copyright = '(c) 2026. All rights reserved.'
    Description = 'Example PowerShell module demonstrating best practices'
    
    PowerShellVersion = '7.0'
    
    FunctionsToExport = @(
        'Get-MyData',
        'Set-MyData'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    
    PrivateData = @{
        PSData = @{
            Tags = @('Example', 'Template', 'BestPractices')
            LicenseUri = 'https://github.com/user/MyModule/blob/main/LICENSE'
            ProjectUri = 'https://github.com/user/MyModule'
            ReleaseNotes = 'Initial release with Get-MyData and Set-MyData cmdlets'
        }
    }
}
