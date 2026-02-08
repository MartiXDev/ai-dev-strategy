function Get-ModuleHelper {
    <#
    .SYNOPSIS
        Private helper function for internal module use.
    
    .DESCRIPTION
        Returns a helper object with methods for data operations.
        Not exported from module.
    #>
    
    [CmdletBinding()]
    param()
    
    # Return helper object with methods
    [PSCustomObject]@{
        FetchData = {
            param([int]$Id)
            # Simulate data retrieval
            return "Data for ID: $Id"
        }
        StoreData = {
            param([int]$Id, [string]$Value)
            # Simulate data storage
            Write-Verbose "Stored: $Id = $Value"
        }
    }
}
