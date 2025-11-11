<#
scripts/lib/Common.psm1

.SYNOPSIS
    Shared utility functions for PowerShell profile scripts.

.DESCRIPTION
    Provides common functionality used across multiple utility scripts including:
    - Repository root path resolution
    - Module installation and management
    - Command availability checking
    - Directory creation and path validation
    - PowerShell executable detection
    - Consistent output formatting
    - Standardized exit code handling

.NOTES
    This module is designed to be imported by utility scripts in the scripts/ directory.
    It uses $PSScriptRoot for path resolution, which requires PowerShell 3.0+.

    Module Version: 2.0.0
    PowerShell Version: 3.0+
    Author: PowerShell Profile Project

    This module now imports and re-exports functions from specialized submodules
    for better maintainability and organization.

.EXAMPLE
    Import-Module -Path (Join-Path $PSScriptRoot 'Common.psm1')
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    Ensure-ModuleAvailable -ModuleName 'PSScriptAnalyzer'
#>

# Import all submodules
$submodules = @(
    'ExitCodes.psm1',
    'Cache.psm1',
    'Path.psm1',
    'Module.psm1',
    'FileSystem.psm1',
    'Command.psm1',
    'Platform.psm1',
    'Parallel.psm1',
    'Logging.psm1',
    'Performance.psm1',
    'CodeAnalysis.psm1',
    'Metrics.psm1',
    'DataFile.psm1'
)

foreach ($submodule in $submodules) {
    $submodulePath = Join-Path $PSScriptRoot $submodule
    if (Test-Path $submodulePath) {
        Import-Module $submodulePath -DisableNameChecking -ErrorAction SilentlyContinue
    }
    else {
        Write-Warning "Submodule not found: $submodulePath"
    }
}

# Re-export all functions and variables from submodules
# This maintains backward compatibility - all functions are still available
# through the Common module as before

# Note: When importing modules into another module, functions need to be explicitly re-exported
# Collect all functions from imported modules and re-export them
$allFunctions = Get-Command -Module @('ExitCodes', 'Cache', 'Path', 'Module', 'FileSystem', 'Command', 'Platform', 'Parallel', 'Logging', 'Performance', 'CodeAnalysis', 'Metrics', 'DataFile') -ErrorAction SilentlyContinue |
Select-Object -ExpandProperty Name -Unique | Sort-Object

if ($allFunctions.Count -gt 0) {
    Export-ModuleMember -Function $allFunctions
}

# Re-export exit code constants from ExitCodes module
Export-ModuleMember -Variable @(
    'EXIT_SUCCESS',
    'EXIT_VALIDATION_FAILURE',
    'EXIT_SETUP_ERROR',
    'EXIT_OTHER_ERROR'
)
