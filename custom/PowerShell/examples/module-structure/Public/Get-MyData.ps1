function Get-MyData {
    <#
    .SYNOPSIS
        Retrieves data from the MyModule data source.
    
    .DESCRIPTION
        Gets data based on the specified identifier. Supports pipeline input.
    
    .PARAMETER Id
        The unique identifier of the data to retrieve.
    
    .EXAMPLE
        Get-MyData -Id 123
        
        Retrieves data with ID 123.
    
    .EXAMPLE
        1, 2, 3 | Get-MyData
        
        Retrieves data for IDs 1, 2, and 3 via pipeline.
    #>
    
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateRange(1, 9999)]
        [int[]]$Id
    )
    
    begin {
        Write-Verbose "Starting Get-MyData"
        $helper = Get-ModuleHelper
    }
    
    process {
        foreach ($identifier in $Id) {
            try {
                Write-Verbose "Retrieving data for ID: $identifier"
                
                # Use private helper function
                $data = $helper.FetchData($identifier)
                
                [PSCustomObject]@{
                    Id = $identifier
                    Data = $data
                    RetrievedAt = Get-Date
                }
            }
            catch {
                Write-Error "Failed to retrieve data for ID $identifier: $_"
            }
        }
    }
}
