# ===============================================
# MockReflection.psm1
# Reflection-based mocking utilities for testing .NET static methods
# ===============================================

<#
.SYNOPSIS
    Reflection-based mocking utilities for testing .NET static methods and error paths.

.DESCRIPTION
    Provides utilities to mock or intercept static .NET method calls that cannot be
    directly mocked with Pester. Uses reflection and wrapper functions to enable
    testing of error paths and edge cases.
#>

<#
.SYNOPSIS
    Creates a testable wrapper for MakeGenericType that can be mocked.

.DESCRIPTION
    Creates a PowerShell function wrapper around Type.MakeGenericType that can be
    intercepted and mocked for testing error paths.

.PARAMETER GenericTypeDefinition
    The generic type definition (e.g., [System.Collections.Generic.List`1]).

.PARAMETER TypeArguments
    Array of type arguments for the generic type.

.PARAMETER ForceNull
    If true, forces the function to return null (for testing error paths).

.PARAMETER ForceException
    If true, forces the function to throw an exception (for testing catch blocks).

.EXAMPLE
    $listType = Invoke-MakeGenericTypeWrapper -GenericTypeDefinition [System.Collections.Generic.List`1] -TypeArguments @([object])
#>
function Invoke-MakeGenericTypeWrapper {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [type]$GenericTypeDefinition,

        [Parameter(Mandatory)]
        [type[]]$TypeArguments,

        [switch]$ForceNull,

        [switch]$ForceException
    )

    if ($ForceException) {
        throw [System.InvalidOperationException]::new("Mocked exception for testing")
    }

    if ($ForceNull) {
        return $null
    }

    return $GenericTypeDefinition.MakeGenericType($TypeArguments)
}

<#
.SYNOPSIS
    Creates a testable wrapper for Activator.CreateInstance that can be mocked.

.DESCRIPTION
    Creates a PowerShell function wrapper around Activator.CreateInstance that can be
    intercepted and mocked for testing error paths.

.PARAMETER Type
    The type to create an instance of.

.PARAMETER ForceNull
    If true, forces the function to return null (for testing error paths).

.PARAMETER ForceException
    If true, forces the function to throw an exception (for testing catch blocks).

.EXAMPLE
    $instance = Invoke-CreateInstanceWrapper -Type $listType
#>
function Invoke-CreateInstanceWrapper {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [type]$Type,

        [switch]$ForceNull,

        [switch]$ForceException
    )

    if ($ForceException) {
        throw [System.InvalidOperationException]::new("Mocked exception for testing")
    }

    if ($ForceNull) {
        return $null
    }

    return [System.Activator]::CreateInstance($Type)
}

<#
.SYNOPSIS
    Creates a testable wrapper for type constructors that can be mocked.

.DESCRIPTION
    Creates a PowerShell function wrapper around type constructors that can be
    intercepted and mocked for testing error paths.

.PARAMETER Type
    The type to create an instance of.

.PARAMETER ForceNull
    If true, forces the function to return null (for testing error paths).

.PARAMETER ForceException
    If true, forces the function to throw an exception (for testing catch blocks).

.EXAMPLE
    $instance = Invoke-TypeConstructorWrapper -Type [System.Collections.Generic.List[string]]
#>
function Invoke-TypeConstructorWrapper {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [type]$Type,

        [switch]$ForceNull,

        [switch]$ForceException
    )

    if ($ForceException) {
        throw [System.InvalidOperationException]::new("Mocked exception for testing")
    }

    if ($ForceNull) {
        return $null
    }

    return $Type::new()
}

# Export functions
Export-ModuleMember -Function @(
    'Invoke-MakeGenericTypeWrapper',
    'Invoke-CreateInstanceWrapper',
    'Invoke-TypeConstructorWrapper'
)

# Also create global functions so they're available to modules that check with Get-Command
# This ensures modules can find the wrapper functions even when they're mocked
if (-not (Get-Command Invoke-MakeGenericTypeWrapper -ErrorAction SilentlyContinue -Scope Global)) {
    Set-Item -Path Function:\global:Invoke-MakeGenericTypeWrapper -Value ${function:Invoke-MakeGenericTypeWrapper} -Force
}
if (-not (Get-Command Invoke-CreateInstanceWrapper -ErrorAction SilentlyContinue -Scope Global)) {
    Set-Item -Path Function:\global:Invoke-CreateInstanceWrapper -Value ${function:Invoke-CreateInstanceWrapper} -Force
}
if (-not (Get-Command Invoke-TypeConstructorWrapper -ErrorAction SilentlyContinue -Scope Global)) {
    Set-Item -Path Function:\global:Invoke-TypeConstructorWrapper -Value ${function:Invoke-TypeConstructorWrapper} -Force
}

