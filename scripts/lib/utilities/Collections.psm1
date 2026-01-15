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
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
            Write-Verbose "[collections.object-list] Starting list creation"
        }
        
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
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                    Write-Verbose "[collections.object-list] Wrapper call failed, using direct call: $($_.Exception.Message)"
                }
                $useWrapper = $false
                $listType = $null
            }
        }
        
        if (-not $useWrapper) {
            $listType = [System.Collections.Generic.List`1].MakeGenericType([object])
        }
        
        if ($null -eq $listType) {
            $errorMsg = "New-ObjectList: MakeGenericType returned null for List[object]"
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Failed to create generic list type" -OperationName 'collections.object-list' -Context @{
                    error_message = $errorMsg
                } -Code 'MakeGenericTypeFailed'
            }
            else {
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
                    Write-Warning "[collections.object-list] $errorMsg"
                }
            }
            return $null
        }
        
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Verbose "[collections.object-list] Created generic type: $($listType.FullName)"
        }
        
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
                    $debugLevel = 0
                    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                        Write-Host "  [collections.object-list] Wrapper returned null, falling back to direct call" -ForegroundColor DarkGray
                    }
                    $list = [System.Activator]::CreateInstance($listType)
                }
            }
            catch {
                # If wrapper call fails, fall back to direct call
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                    Write-Host "  [collections.object-list] Wrapper call failed, using direct call: $($_.Exception.Message)" -ForegroundColor DarkGray
                }
                $list = [System.Activator]::CreateInstance($listType)
            }
        }
        else {
            $list = [System.Activator]::CreateInstance($listType)
        }
        
        if ($null -eq $list) {
            $errorMsg = "New-ObjectList: CreateInstance returned null for type $($listType.FullName)"
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Failed to create list instance" -OperationName 'collections.object-list' -Context @{
                    type_name     = $listType.FullName
                    error_message = $errorMsg
                } -Code 'CreateInstanceFailed'
            }
            else {
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
                    Write-Warning "[collections.object-list] $errorMsg"
                }
            }
            return $null
        }
        
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Verbose "[collections.object-list] Successfully created List[object] instance"
        }
        
        # Return the list - ensure it's the only output
        , $list
    }
    catch {
        $errorMsg = "New-ObjectList: Exception occurred: $($_.Exception.Message) | Type: $($_.Exception.GetType().FullName) | StackTrace: $($_.ScriptStackTrace)"
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'collections.object-list' -Context @{
                error_message = $errorMsg
            }
        }
        else {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
                Write-Error "[collections.object-list] $errorMsg" -ErrorAction Continue
            }
        }
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
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
            Write-Verbose "[collections.string-list] Starting list creation"
        }
        
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
                    $debugLevel = 0
                    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                        Write-Host "  [collections.string-list] Wrapper returned null, falling back to direct call" -ForegroundColor DarkGray
                    }
                    $list = [System.Collections.Generic.List[string]]::new()
                }
            }
            catch {
                # If wrapper call fails, fall back to direct call
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                    Write-Host "  [collections.string-list] Wrapper call failed, using direct call: $($_.Exception.Message)" -ForegroundColor DarkGray
                }
                $list = [System.Collections.Generic.List[string]]::new()
            }
        }
        else {
            $list = [System.Collections.Generic.List[string]]::new()
        }
        
        if ($null -eq $list) {
            $errorMsg = "New-StringList: Constructor returned null"
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Failed to create string list instance" -OperationName 'collections.string-list' -Context @{
                    error_message = $errorMsg
                } -Code 'ConstructorFailed'
            }
            else {
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
                    Write-Warning "[collections.string-list] $errorMsg"
                }
            }
            return $null
        }
        
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Verbose "[collections.string-list] Successfully created List[string] instance"
        }
        
        # Return the list - ensure it's the only output
        , $list
    }
    catch {
        $errorMsg = "New-StringList: Exception occurred: $($_.Exception.Message) | Type: $($_.Exception.GetType().FullName) | StackTrace: $($_.ScriptStackTrace)"
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'collections.string-list' -Context @{
                error_message = $errorMsg
            }
        }
        else {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
                Write-Error "[collections.string-list] $errorMsg" -ErrorAction Continue
            }
        }
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
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
            Write-Verbose "[collections.typed-list] Starting list creation for type: $Type"
        }
        
        # Handle null, empty, or whitespace-only strings
        if ($null -eq $Type -or ($Type -is [string] -and [string]::IsNullOrWhiteSpace($Type))) {
            $errorMsg = "New-TypedList: Type cannot be null, empty, or whitespace"
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Invalid type parameter" -OperationName 'collections.typed-list' -Context @{
                    type_value    = $Type
                    error_message = $errorMsg
                } -Code 'InvalidTypeParameter'
            }
            else {
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
                    Write-Warning "[collections.typed-list] $errorMsg"
                }
            }
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
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Failed to convert type" -OperationName 'collections.typed-list' -Context @{
                    type_value    = $Type
                    error_message = $_.Exception.Message
                } -Code 'TypeConversionFailed'
            }
            else {
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
                    Write-Warning "[collections.typed-list] $errorMsg"
                }
            }
            return
        }
        
        if ($null -eq $typeObj) {
            $errorMsg = "New-TypedList: Failed to convert '$Type' to Type object"
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Type conversion returned null" -OperationName 'collections.typed-list' -Context @{
                    type_value    = $Type
                    error_message = $errorMsg
                } -Code 'TypeConversionNull'
            }
            else {
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
                    Write-Warning "[collections.typed-list] $errorMsg"
                }
            }
            return $null
        }
        
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Verbose "[collections.typed-list] Resolved type to: $($typeObj.FullName)"
        }
        
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
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                    Write-Verbose "[collections.typed-list] Wrapper call failed, using direct call: $($_.Exception.Message)"
                }
                $useWrapper = $false
                $listType = $null
            }
        }
        
        if (-not $useWrapper) {
            $listType = [System.Collections.Generic.List`1].MakeGenericType($typeObj)
        }
        
        if ($null -eq $listType) {
            $errorMsg = "New-TypedList: MakeGenericType returned null for type $($typeObj.FullName)"
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Failed to create generic list type" -OperationName 'collections.typed-list' -Context @{
                    type_name     = $typeObj.FullName
                    error_message = $errorMsg
                } -Code 'MakeGenericTypeFailed'
            }
            else {
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
                    Write-Warning "[collections.typed-list] $errorMsg"
                }
            }
            return $null
        }
        
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Verbose "[collections.typed-list] Created generic type: $($listType.FullName)"
        }
        
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
                    $debugLevel = 0
                    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                        Write-Host "  [collections.typed-list] Wrapper returned null, falling back to direct call" -ForegroundColor DarkGray
                    }
                    $list = [System.Activator]::CreateInstance($listType)
                }
            }
            catch {
                # If wrapper call fails, fall back to direct call
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
                    Write-Host "  [collections.typed-list] Wrapper call failed, using direct call: $($_.Exception.Message)" -ForegroundColor DarkGray
                }
                $list = [System.Activator]::CreateInstance($listType)
            }
        }
        else {
            $list = [System.Activator]::CreateInstance($listType)
        }
        if ($null -eq $list) {
            $errorMsg = "New-TypedList: CreateInstance returned null for type $($listType.FullName)"
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Failed to create list instance" -OperationName 'collections.typed-list' -Context @{
                    type_name     = $listType.FullName
                    error_message = $errorMsg
                } -Code 'CreateInstanceFailed'
            }
            else {
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
                    Write-Warning "[collections.typed-list] $errorMsg"
                }
            }
            return $null
        }
        
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Verbose "[collections.typed-list] Successfully created List[$($typeObj.FullName)] instance"
        }
        
        # Return the list - ensure it's the only output
        , $list
    }
    catch {
        $errorMsg = "New-TypedList: Exception occurred: $($_.Exception.Message) | Type: $($_.Exception.GetType().FullName) | StackTrace: $($_.ScriptStackTrace)"
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName 'collections.typed-list' -Context @{
                type_value    = $Type
                error_message = $errorMsg
            }
        }
        else {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 1) {
                Write-Error "[collections.typed-list] $errorMsg" -ErrorAction Continue
            }
        }
        return $null
    }
}

Export-ModuleMember -Function @(
    'New-ObjectList',
    'New-StringList',
    'New-TypedList'
)

