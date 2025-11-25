<#
scripts/utils/code-quality/modules/TestPathResolution.psm1

.SYNOPSIS
    Test path resolution utilities.

.DESCRIPTION
    Provides functions for resolving test file and directory paths based on suite specifications.
#>

# Import FileSystem module for Get-PowerShellScripts
$fileSystemModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'FileSystem.psm1'
if (Test-Path $fileSystemModulePath) {
    Import-Module $fileSystemModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Resolves test paths based on suite and file specifications.

.DESCRIPTION
    Determines the appropriate test paths to run based on the Suite parameter
    and TestFile parameter, handling directory-based test organization.

.PARAMETER Suite
    The test suite to run (All, Unit, Integration, Performance).

.PARAMETER TestFile
    Optional specific test file or directory path.

.PARAMETER RepoRoot
    Repository root directory path.

.OUTPUTS
    System.String[]
#>
function Get-TestPaths {
    param(
        [ValidateSet('All', 'Unit', 'Integration', 'Performance')]
        [string]$Suite = 'All',

        [string]$TestFile,

        [string]$RepoRoot
    )

    if ([string]::IsNullOrWhiteSpace($TestFile)) {
        return Get-TestSuitePaths -Suite $Suite -RepoRoot $RepoRoot
    }
    else {
        return Get-SpecificTestPaths -TestFile $TestFile -Suite $Suite -RepoRoot $RepoRoot
    }
}

<#
.SYNOPSIS
    Gets test paths for a specific test suite.

.DESCRIPTION
    Returns the appropriate directory paths for the specified test suite,
    filtering to only existing directories.
#>
function Get-TestSuitePaths {
    param(
        [string]$Suite,
        [string]$RepoRoot
    )

    $testPaths = @()
    switch ($Suite) {
        'Unit' {
            $testPaths = @('tests/unit')
        }
        'Integration' {
            $testPaths = @('tests/integration')
        }
        'Performance' {
            $testPaths = @('tests/performance')
        }
        default {
            $testPaths = @('tests/unit', 'tests/integration', 'tests/performance')
        }
    }

    # Convert to full paths and filter to existing directories
    $existingPaths = $testPaths |
    ForEach-Object { Join-Path $RepoRoot $_ } |
    Where-Object { Test-Path $_ }

    if (-not $existingPaths) {
        # Fallback to tests directory if no suite directories exist
        return @(Join-Path $RepoRoot 'tests')
    }

    return $existingPaths
}

<#
.SYNOPSIS
    Resolves specific test file or directory paths.

.DESCRIPTION
    Handles resolution of user-specified test files or directories,
    including recursive discovery of .tests.ps1 files in directories.
#>
function Get-SpecificTestPaths {
    param(
        [string]$TestFile,
        [string]$Suite,
        [string]$RepoRoot
    )

    if ([string]::IsNullOrWhiteSpace($TestFile)) {
        throw "TestFile parameter cannot be null or empty"
    }

    try {
        $resolvedTestPath = (Resolve-Path -Path $TestFile -ErrorAction Stop).ProviderPath
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        throw "Test file or directory not found: $TestFile"
    }
    catch {
        throw "Failed to resolve test path '$TestFile': $($_.Exception.Message)"
    }

    if (Test-Path -LiteralPath $resolvedTestPath -PathType Container) {
        return Get-TestFilesFromDirectory -Directory $resolvedTestPath
    }
    else {
        return @($resolvedTestPath)
    }
}

<#
.SYNOPSIS
    Gets all test files from a directory recursively.

.DESCRIPTION
    Searches for .tests.ps1 files in the specified directory and subdirectories,
    returning their full paths sorted by name.
#>
function Get-TestFilesFromDirectory {
    param(
        [string]$Directory
    )

    $testScripts = Get-PowerShellScripts -Path $Directory -Recurse -SortByName |
    Where-Object { $_.Name -like '*.tests.ps1' }

    if (-not $testScripts) {
        return @($Directory)
    }

    return $testScripts | Select-Object -ExpandProperty FullName
}

Export-ModuleMember -Function @(
    'Get-TestPaths',
    'Get-TestSuitePaths',
    'Get-SpecificTestPaths',
    'Get-TestFilesFromDirectory'
)

