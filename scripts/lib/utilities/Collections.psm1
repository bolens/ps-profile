<#
scripts/lib/Collections.psm1

.SYNOPSIS
    Collection creation utilities.

.DESCRIPTION
    Provides helper functions for creating strongly-typed collections with consistent
    patterns. These helpers improve performance over array concatenation and provide
    type safety.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

<#
.SYNOPSIS
    Creates a new generic List of PSCustomObject.

.DESCRIPTION
    Creates a new System.Collections.Generic.List[PSCustomObject] instance.
    This is more performant than array concatenation for building collections.

.OUTPUTS
    System.Collections.Generic.List[PSCustomObject]. A new list instance.

.EXAMPLE
    $items = New-ObjectList
    $items.Add([PSCustomObject]@{ Name = "Item1"; Value = 1 })
    $items.Add([PSCustomObject]@{ Name = "Item2"; Value = 2 })
    $results = $items.ToArray()
#>
function New-ObjectList {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[object]])]
    param()

    # Use object type instead of PSCustomObject since PSCustomObject is a PowerShell type accelerator
    # and may not work reliably with generic types. List[object] works the same for PSCustomObject items.
    try {
        Write-Verbose "New-ObjectList: Starting list creation"
        
        # Use wrapper function if available (for testing), otherwise use direct call
        # Check for wrapper function - try multiple detection methods for test compatibility
        $useWrapper = $false
        try {
            # Method 1: Test function provider directly (fastest, works for global functions)
            if (Test-Path Function:\Invoke-MakeGenericTypeWrapper -ErrorAction SilentlyContinue) {
                $useWrapper = $true
            }
            # Method 2: Get-Command with -All to search all scopes
            elseif (Get-Command Invoke-MakeGenericTypeWrapper -ErrorAction SilentlyContinue -All) {
                $useWrapper = $true
            }
        }
        catch {
            # Silently continue if checks fail
        }
        
        if ($useWrapper) {
            try {
                $genericListType = [System.Collections.Generic.List`1]
                # Save current ErrorActionPreference and set to Stop to ensure exceptions are caught
                $oldErrorAction = $ErrorActionPreference
                $ErrorActionPreference = 'Stop'
                try {
                    $listType = Invoke-MakeGenericTypeWrapper -GenericTypeDefinition $genericListType -TypeArguments @([object])
                }
                finally {
                    $ErrorActionPreference = $oldErrorAction
                }
                # Ensure listType is set even if wrapper returns null
                if ($null -eq $listType) {
                    $useWrapper = $false
                }
            }
            catch {
                # If wrapper call fails, fall back to direct call
                Write-Verbose "New-ObjectList: Wrapper call failed, using direct call: $($_.Exception.Message)"
                $useWrapper = $false
                $listType = $null
            }
        }
        
        if (-not $useWrapper) {
            $listType = [System.Collections.Generic.List`1].MakeGenericType([object])
        }
        
        if ($null -eq $listType) {
            $errorMsg = "New-ObjectList: MakeGenericType returned null for List[object]"
            Write-Verbose $errorMsg
            return $null
        }
        
        Write-Verbose "New-ObjectList: Created generic type: $($listType.FullName)"
        
        # Use wrapper function if available (for testing), otherwise use direct call
        # Check for wrapper function - try multiple detection methods for test compatibility
        $useWrapper = $false
        try {
            # Method 1: Test function provider directly (fastest, works for global functions)
            if (Test-Path Function:\Invoke-CreateInstanceWrapper -ErrorAction SilentlyContinue) {
                $useWrapper = $true
            }
            # Method 2: Get-Command with -All to search all scopes
            elseif (Get-Command Invoke-CreateInstanceWrapper -ErrorAction SilentlyContinue -All) {
                $useWrapper = $true
            }
        }
        catch {
            # Silently continue if checks fail
        }
        
        if ($useWrapper) {
            try {
                # Save current ErrorActionPreference and set to Stop to ensure exceptions are caught
                $oldErrorAction = $ErrorActionPreference
                $ErrorActionPreference = 'Stop'
                try {
                    $list = Invoke-CreateInstanceWrapper -Type $listType
                }
                finally {
                    $ErrorActionPreference = $oldErrorAction
                }
                # If wrapper returns null, fall back to direct call
                if ($null -eq $list) {
                    Write-Verbose "New-ObjectList: Wrapper returned null, falling back to direct call"
                    $list = [System.Activator]::CreateInstance($listType)
                }
            }
            catch {
                # If wrapper call fails, fall back to direct call
                Write-Verbose "New-ObjectList: Wrapper call failed, using direct call: $($_.Exception.Message)"
                $list = [System.Activator]::CreateInstance($listType)
            }
        }
        else {
            $list = [System.Activator]::CreateInstance($listType)
        }
        
        if ($null -eq $list) {
            $errorMsg = "New-ObjectList: CreateInstance returned null for type $($listType.FullName)"
            Write-Verbose $errorMsg
            return $null
        }
        
        # Return the list - ensure it's the only output
        , $list
    }
    catch {
        $errorMsg = "New-ObjectList: Exception occurred: $($_.Exception.Message) | Type: $($_.Exception.GetType().FullName) | StackTrace: $($_.ScriptStackTrace)"
        Write-Verbose $errorMsg
        return $null
    }
}

<#
.SYNOPSIS
    Creates a new generic List of strings.

.DESCRIPTION
    Creates a new System.Collections.Generic.List[string] instance.
    Useful for building string collections efficiently.

.OUTPUTS
    System.Collections.Generic.List[string]. A new list instance.

.EXAMPLE
    $lines = New-StringList
    $lines.Add("Line 1")
    $lines.Add("Line 2")
    $content = $lines -join "`n"
#>
function New-StringList {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[string]])]
    param()

    try {
        Write-Verbose "New-StringList: Starting list creation"
        
        # Use wrapper function if available (for testing), otherwise use direct call
        # Check for wrapper function - try multiple detection methods for test compatibility
        $useWrapper = $false
        try {
            # Method 1: Test function provider directly (fastest, works for global functions)
            if (Test-Path Function:\Invoke-TypeConstructorWrapper -ErrorAction SilentlyContinue) {
                $useWrapper = $true
            }
            # Method 2: Get-Command with -All to search all scopes
            elseif (Get-Command Invoke-TypeConstructorWrapper -ErrorAction SilentlyContinue -All) {
                $useWrapper = $true
            }
        }
        catch {
            # Silently continue if checks fail
        }
        
        if ($useWrapper) {
            try {
                $listType = [System.Collections.Generic.List[string]]
                # Save current ErrorActionPreference and set to Stop to ensure exceptions are caught
                $oldErrorAction = $ErrorActionPreference
                $ErrorActionPreference = 'Stop'
                try {
                    $list = Invoke-TypeConstructorWrapper -Type $listType
                }
                finally {
                    $ErrorActionPreference = $oldErrorAction
                }
                # If wrapper returns null, fall back to direct call
                if ($null -eq $list) {
                    Write-Verbose "New-StringList: Wrapper returned null, falling back to direct call"
                    $list = [System.Collections.Generic.List[string]]::new()
                }
            }
            catch {
                # If wrapper call fails, fall back to direct call
                Write-Verbose "New-StringList: Wrapper call failed, using direct call: $($_.Exception.Message)"
                $list = [System.Collections.Generic.List[string]]::new()
            }
        }
        else {
            $list = [System.Collections.Generic.List[string]]::new()
        }
        
        if ($null -eq $list) {
            $errorMsg = "New-StringList: Constructor returned null"
            Write-Verbose $errorMsg
            return $null
        }
        # Return the list - ensure it's the only output
        , $list
    }
    catch {
        $errorMsg = "New-StringList: Exception occurred: $($_.Exception.Message) | Type: $($_.Exception.GetType().FullName) | StackTrace: $($_.ScriptStackTrace)"
        Write-Verbose $errorMsg
        return $null
    }
}

<#
.SYNOPSIS
    Creates a new generic List of the specified type.

.DESCRIPTION
    Creates a new System.Collections.Generic.List[T] instance for the specified type.
    Provides type-safe collection creation.

.PARAMETER Type
    The type of list elements. Can be a type name string or a Type object.

.OUTPUTS
    System.Collections.Generic.List[T]. A new list instance of the specified type.

.EXAMPLE
    $intList = New-TypedList -Type "int"
    $intList.Add(1)
    $intList.Add(2)

.EXAMPLE
    $fileList = New-TypedList -Type ([System.IO.FileInfo])
    $fileList.Add($file1)
#>
function New-TypedList {
    [CmdletBinding()]
    [OutputType([System.Collections.IList])]
    param(
        [Parameter(Mandatory)]
        [object]$Type
    )

    try {
        Write-Verbose "New-TypedList: Starting list creation for type: $Type"
        
        # Handle null, empty, or whitespace-only strings
        if ($null -eq $Type -or ($Type -is [string] -and [string]::IsNullOrWhiteSpace($Type))) {
            $errorMsg = "New-TypedList: Type cannot be null, empty, or whitespace"
            Write-Verbose $errorMsg
            return
        }
        
        $typeObj = $null
        try {
            if ($Type -is [type]) {
                $typeObj = $Type
            }
            else {
                # Try to convert string to type - this may throw an exception for invalid types
                $typeObj = [type]$Type
            }
        }
        catch {
            # Type conversion failed (invalid type name, etc.)
            $errorMsg = "New-TypedList: Failed to convert '$Type' to Type object: $($_.Exception.Message)"
            Write-Verbose $errorMsg
            return
        }
        
        if ($null -eq $typeObj) {
            $errorMsg = "New-TypedList: Failed to convert '$Type' to Type object"
            Write-Verbose $errorMsg
            return $null
        }
        
        Write-Verbose "New-TypedList: Resolved type to: $($typeObj.FullName)"
        
        # Use wrapper function if available (for testing), otherwise use direct call
        # Check for wrapper function - try multiple detection methods for test compatibility
        $useWrapper = $false
        try {
            # Method 1: Test function provider directly (fastest, works for global functions)
            if (Test-Path Function:\Invoke-MakeGenericTypeWrapper -ErrorAction SilentlyContinue) {
                $useWrapper = $true
            }
            # Method 2: Get-Command with -All to search all scopes
            elseif (Get-Command Invoke-MakeGenericTypeWrapper -ErrorAction SilentlyContinue -All) {
                $useWrapper = $true
            }
        }
        catch {
            # Silently continue if checks fail
        }
        
        if ($useWrapper) {
            try {
                $genericListType = [System.Collections.Generic.List`1]
                # Save current ErrorActionPreference and set to Stop to ensure exceptions are caught
                $oldErrorAction = $ErrorActionPreference
                $ErrorActionPreference = 'Stop'
                try {
                    $listType = Invoke-MakeGenericTypeWrapper -GenericTypeDefinition $genericListType -TypeArguments @($typeObj)
                }
                finally {
                    $ErrorActionPreference = $oldErrorAction
                }
                # Ensure listType is set even if wrapper returns null
                if ($null -eq $listType) {
                    $useWrapper = $false
                }
            }
            catch {
                # If wrapper call fails, fall back to direct call
                Write-Verbose "New-TypedList: Wrapper call failed, using direct call: $($_.Exception.Message)"
                $useWrapper = $false
                $listType = $null
            }
        }
        
        if (-not $useWrapper) {
            $listType = [System.Collections.Generic.List`1].MakeGenericType($typeObj)
        }
        
        if ($null -eq $listType) {
            $errorMsg = "New-TypedList: MakeGenericType returned null for type $($typeObj.FullName)"
            Write-Verbose $errorMsg
            return $null
        }
        
        Write-Verbose "New-TypedList: Created generic type: $($listType.FullName)"
        
        # Use wrapper function if available (for testing), otherwise use direct call
        # Check for wrapper function - try multiple detection methods for test compatibility
        $useWrapper = $false
        try {
            # Method 1: Test function provider directly (fastest, works for global functions)
            if (Test-Path Function:\Invoke-CreateInstanceWrapper -ErrorAction SilentlyContinue) {
                $useWrapper = $true
            }
            # Method 2: Get-Command with -All to search all scopes
            elseif (Get-Command Invoke-CreateInstanceWrapper -ErrorAction SilentlyContinue -All) {
                $useWrapper = $true
            }
        }
        catch {
            # Silently continue if checks fail
        }
        
        if ($useWrapper) {
            try {
                # Save current ErrorActionPreference and set to Stop to ensure exceptions are caught
                $oldErrorAction = $ErrorActionPreference
                $ErrorActionPreference = 'Stop'
                try {
                    $list = Invoke-CreateInstanceWrapper -Type $listType
                }
                finally {
                    $ErrorActionPreference = $oldErrorAction
                }
                # If wrapper returns null, fall back to direct call
                if ($null -eq $list) {
                    Write-Verbose "New-TypedList: Wrapper returned null, falling back to direct call"
                    $list = [System.Activator]::CreateInstance($listType)
                }
            }
            catch {
                # If wrapper call fails, fall back to direct call
                Write-Verbose "New-TypedList: Wrapper call failed, using direct call: $($_.Exception.Message)"
                $list = [System.Activator]::CreateInstance($listType)
            }
        }
        else {
            $list = [System.Activator]::CreateInstance($listType)
        }
        if ($null -eq $list) {
            $errorMsg = "New-TypedList: CreateInstance returned null for type $($listType.FullName)"
            Write-Verbose $errorMsg
            return $null
        }
        
        # Return the list - ensure it's the only output
        , $list
    }
    catch {
        $errorMsg = "New-TypedList: Exception occurred: $($_.Exception.Message) | Type: $($_.Exception.GetType().FullName) | StackTrace: $($_.ScriptStackTrace)"
        Write-Verbose $errorMsg
        return $null
    }
}

Export-ModuleMember -Function @(
    'New-ObjectList',
    'New-StringList',
    'New-TypedList'
)

