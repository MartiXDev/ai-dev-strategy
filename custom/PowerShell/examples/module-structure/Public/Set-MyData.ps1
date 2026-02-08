function Set-MyData {
    <#
    .SYNOPSIS
        Sets data in the MyModule data source.
    
    .DESCRIPTION
        Updates or creates data with the specified identifier and value.
        Supports -WhatIf and -Confirm.
    
    .PARAMETER Id
        The unique identifier of the data to set.
    
    .PARAMETER Value
        The value to set for the specified ID.
    
    .EXAMPLE
        Set-MyData -Id 123 -Value "New data"
        
        Sets data with ID 123 to "New data".
    
    .EXAMPLE
        Set-MyData -Id 123 -Value "Destructive change" -WhatIf
        
        Shows what would happen without making changes.
    #>
    
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory)]
        [ValidateRange(1, 9999)]
        [int]$Id,
        
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Value
    )
    
    process {
        try {
            if ($PSCmdlet.ShouldProcess("ID $Id", "Set value to '$Value'")) {
                Write-Verbose "Setting data for ID: $Id"
                
                # Use private helper function
                $helper = Get-ModuleHelper
                $helper.StoreData($Id, $Value)
                
                Write-Verbose "Successfully set data for ID: $Id"
            }
        }
        catch {
            Write-Error "Failed to set data for ID $Id: $_"
            throw
        }
    }
}
