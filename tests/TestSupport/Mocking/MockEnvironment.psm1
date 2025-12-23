# ===============================================
# MockEnvironment.psm1
# Environment variable mocking utilities
# ===============================================

<#
.SYNOPSIS
    Environment variable mocking utilities.

.DESCRIPTION
    Provides functions for mocking environment variables with automatic cleanup.
    Supports both manual tracking and automatic cleanup in Pester test blocks.
#>

# Import mock registry functions
$modulePath = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module (Join-Path $modulePath 'MockRegistry.psm1') -DisableNameChecking -ErrorAction Stop

<#
.SYNOPSIS
    Mocks an environment variable.

.DESCRIPTION
    Sets an environment variable to a test value and tracks it for cleanup.
    Automatically restores the original value when used in Pester test blocks.

.PARAMETER Name
    Name of the environment variable.

.PARAMETER Value
    Value to set. Use $null to remove/unset the variable.

.PARAMETER RestoreOriginal
    If true, restores original value after test. Default is true for automatic cleanup.

.PARAMETER Scope
    Pester 5 scope hint (for documentation). Mocks are automatically scoped to the current test block.

.EXAMPLE
    Mock-EnvironmentVariable -Name 'PS_PROFILE_TEST_MODE' -Value '1'

.EXAMPLE
    Mock-EnvironmentVariable -Name 'EDITOR' -Value 'vim' -RestoreOriginal

.EXAMPLE
    Mock-EnvironmentVariable -Name 'TEST_VAR' -Value $null  # Unset variable
#>
function Mock-EnvironmentVariable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [object]$Value,

        [switch]$RestoreOriginal = $true,

        [ValidateSet('It', 'Context', 'Describe', 'All')]
        [string]$Scope = 'It'
    )

    # Get original value before setting
    $original = [Environment]::GetEnvironmentVariable($Name, 'Process')
    if ($null -eq $original) {
        # Also check Env: drive
        $original = (Get-Item -Path "Env:\$Name" -ErrorAction SilentlyContinue).Value
    }

    # Set the new value
    if ($null -eq $Value) {
        # Remove/unset the variable
        [Environment]::SetEnvironmentVariable($Name, $null, 'Process')
        Remove-Item -Path "Env:\$Name" -Force -ErrorAction SilentlyContinue
    }
    else {
        # Set the variable
        [Environment]::SetEnvironmentVariable($Name, $Value, 'Process')
        Set-Item -Path "Env:\$Name" -Value $Value -Force
    }

    # Register for automatic cleanup if RestoreOriginal is true
    if ($RestoreOriginal) {
        Register-Mock -Type 'Variable' -Name $Name -MockValue $Value -Original $original
    }

    Write-Verbose "Mocked environment variable: $Name = $Value (original: $original)"
}

<#
.SYNOPSIS
    Restores an environment variable to its original value.

.DESCRIPTION
    Restores an environment variable that was mocked using Mock-EnvironmentVariable.
    This is typically called automatically by Restore-AllMocks, but can be called manually if needed.

.PARAMETER Name
    Name of the environment variable to restore.

.EXAMPLE
    Restore-EnvironmentVariable -Name 'PS_PROFILE_TEST_MODE'
#>
function Restore-EnvironmentVariable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $key = "Variable:$Name"
    $registry = Get-MockRegistry
    if ($registry.Original.ContainsKey($key)) {
        $original = $registry.Original[$key]
        if ($null -eq $original) {
            [Environment]::SetEnvironmentVariable($Name, $null, 'Process')
            Remove-Item -Path "Env:\$Name" -Force -ErrorAction SilentlyContinue
        }
        else {
            [Environment]::SetEnvironmentVariable($Name, $original, 'Process')
            Set-Item -Path "Env:\$Name" -Value $original -Force
        }
        Write-Verbose "Restored environment variable: $Name = $original"
    }
    else {
        Write-Verbose "No original value found for environment variable: $Name"
    }
}

<#
.SYNOPSIS
    Mocks multiple environment variables at once.

.DESCRIPTION
    Convenience function for setting multiple environment variables in a single call.
    All variables are tracked for automatic cleanup.

.PARAMETER Variables
    Hashtable of variable names and values to set.

.PARAMETER RestoreOriginal
    If true, restores original values after test. Default is true.

.EXAMPLE
    Mock-EnvironmentVariables -Variables @{
        'EDITOR' = 'vim'
        'GIT_EDITOR' = 'vim --wait'
        'VISUAL' = 'vim'
    }
#>
function Mock-EnvironmentVariables {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Variables,

        [switch]$RestoreOriginal = $true
    )

    foreach ($name in $Variables.Keys) {
        Mock-EnvironmentVariable -Name $name -Value $Variables[$name] -RestoreOriginal:$RestoreOriginal
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Mock-EnvironmentVariable',
    'Restore-EnvironmentVariable',
    'Mock-EnvironmentVariables'
)

