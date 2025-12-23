# ===============================================
# MockRegistry.psm1
# Mock registry and management utilities
# ===============================================

<#
.SYNOPSIS
    Mock registry and management utilities.

.DESCRIPTION
    Provides functions for tracking, managing, and restoring mocks.
    This module handles the registry that tracks all mocks for cleanup purposes.
#>

# Module-level variables for tracking mocks
$script:MockRegistry = @{
    Functions = @{}
    Commands  = @{}
    Variables = @{}
    Original  = @{}
}

<#
.SYNOPSIS
    Registers a mock in the mock registry.

.DESCRIPTION
    Tracks mocks for cleanup and management purposes.

.PARAMETER Type
    Type of mock: 'Function', 'Command', or 'Variable'.

.PARAMETER Name
    Name of the item being mocked.

.PARAMETER MockValue
    The mock implementation or value.

.PARAMETER Original
    The original value (if any) for restoration.

.EXAMPLE
    Register-Mock -Type 'Command' -Name 'git' -MockValue $mockScript -Original $original
#>
function Register-Mock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Function', 'Command', 'Variable')]
        [string]$Type,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [object]$MockValue,

        [object]$Original = $null
    )

    $key = "$Type`:$Name"
    $script:MockRegistry[$Type][$Name] = @{
        MockValue  = $MockValue
        Original   = $Original
        Registered = Get-Date
    }

    if ($Original) {
        $script:MockRegistry.Original[$key] = $Original
    }
}

<#
.SYNOPSIS
    Clears all registered mocks.

.DESCRIPTION
    Removes all mocks from the registry. Does not restore original values.
    Use Restore-AllMocks to restore originals.
#>
function Clear-MockRegistry {
    [CmdletBinding()]
    param()

    $script:MockRegistry.Functions.Clear()
    $script:MockRegistry.Commands.Clear()
    $script:MockRegistry.Variables.Clear()
    $script:MockRegistry.Original.Clear()
}

<#
.SYNOPSIS
    Restores all original values from mocks.

.DESCRIPTION
    Restores original function/command/variable values that were replaced by mocks.
#>
function Restore-AllMocks {
    [CmdletBinding()]
    param()

    # Restore functions
    foreach ($name in $script:MockRegistry.Functions.Keys) {
        $mock = $script:MockRegistry.Functions[$name]
        if ($mock.Original) {
            if (Test-Path "Function:\$name") {
                Set-Item -Path "Function:\$name" -Value $mock.Original -Force -ErrorAction SilentlyContinue
            }
            elseif ($mock.Original -is [scriptblock]) {
                Set-Item -Path "Function:\$name" -Value $mock.Original -Force -ErrorAction SilentlyContinue
            }
        }
        else {
            # Remove mock if no original
            Remove-Item -Path "Function:\$name" -Force -ErrorAction SilentlyContinue
        }
    }

    # Restore variables
    foreach ($name in $script:MockRegistry.Variables.Keys) {
        $mock = $script:MockRegistry.Variables[$name]
        if ($mock.Original) {
            Set-Variable -Name $name -Value $mock.Original -Scope Global -Force -ErrorAction SilentlyContinue
        }
        else {
            Remove-Variable -Name $name -Scope Global -Force -ErrorAction SilentlyContinue
        }
    }

    Clear-MockRegistry
}

<#
.SYNOPSIS
    Gets the mock registry for inspection.

.DESCRIPTION
    Returns the current state of the mock registry. Useful for debugging.

.EXAMPLE
    $registry = Get-MockRegistry
    $registry.Commands.Keys
#>
function Get-MockRegistry {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return $script:MockRegistry
}

# Export functions
Export-ModuleMember -Function @(
    'Register-Mock',
    'Clear-MockRegistry',
    'Restore-AllMocks',
    'Get-MockRegistry'
)

