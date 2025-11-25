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
    [OutputType([System.Collections.Generic.List[PSCustomObject]])]
    param()

    return [System.Collections.Generic.List[PSCustomObject]]::new()
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

    return [System.Collections.Generic.List[string]]::new()
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

    $typeObj = if ($Type -is [type]) {
        $Type
    }
    else {
        [type]$Type
    }

    $listType = [System.Collections.Generic.List`1].MakeGenericType($typeObj)
    return [System.Activator]::CreateInstance($listType)
}

Export-ModuleMember -Function @(
    'New-ObjectList',
    'New-StringList',
    'New-TypedList'
)

