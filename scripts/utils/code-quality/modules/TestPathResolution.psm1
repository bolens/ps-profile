<#
scripts/utils/code-quality/modules/TestPathResolution.psm1

.SYNOPSIS
    Test path resolution utilities.

.DESCRIPTION
    Provides functions for resolving test file and directory paths based on suite specifications.

.NOTES
    Module Version: 2.0.0
    PowerShell Version: 5.0+ (for enum support)
    
    This module now uses enums for type-safe configuration values.
#>

# Import CommonEnums for TestSuite enum
$commonEnumsPath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'lib' 'core' 'CommonEnums.psm1'
if ($commonEnumsPath -and (Test-Path -LiteralPath $commonEnumsPath)) {
    Import-Module $commonEnumsPath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Import FileSystem module for Get-PowerShellScripts
# Use proper path resolution to find the lib directory
$currentPath = $PSScriptRoot
$libPath = $null
$maxDepth = 10
$depth = 0

while ($null -eq $libPath -and $depth -lt $maxDepth) {
    $testLibPath = Join-Path $currentPath 'lib'
    if ($testLibPath -and -not [string]::IsNullOrWhiteSpace($testLibPath) -and (Test-Path -LiteralPath $testLibPath)) {
        $libPath = $testLibPath
        break
    }
    $parent = Split-Path -Parent $currentPath
    if ($null -eq $parent -or $parent -eq $currentPath) {
        break
    }
    $currentPath = $parent
    $depth++
}

if ($null -ne $libPath) {
    $fileSystemModulePath = Join-Path $libPath 'file' 'FileSystem.psm1'
    if ($fileSystemModulePath -and -not [string]::IsNullOrWhiteSpace($fileSystemModulePath) -and (Test-Path -LiteralPath $fileSystemModulePath)) {
        try {
            Import-Module $fileSystemModulePath -DisableNameChecking -ErrorAction Stop -Global
        }
        catch {
            Write-Warning "Failed to import FileSystem module: $_"
        }
    }
    else {
        Write-Warning "FileSystem module not found at: $fileSystemModulePath"
    }
}
else {
    Write-Warning "Could not locate lib directory from $PSScriptRoot"
}

<#
.SYNOPSIS
    Resolves test paths based on suite and file specifications.

.DESCRIPTION
    Determines the appropriate test paths to run based on the Suite parameter
    and TestFile parameter, handling directory-based test organization.
    Supports multiple test files or directories.

.PARAMETER Suite
    The test suite to run. Must be a TestSuite enum value.

.PARAMETER TestFile
    Optional specific test file(s) or directory path(s). Can accept multiple files as an array.

.PARAMETER RepoRoot
    Repository root directory path.

.OUTPUTS
    System.String[]
#>
function Get-TestPaths {
    param(
        [TestSuite]$Suite = [TestSuite]::All,

        [string[]]$TestFile,

        [string]$RepoRoot
    )

    # Convert enum to string
    $suiteString = $Suite.ToString()

    if ($null -eq $TestFile -or $TestFile.Count -eq 0 -or ($TestFile.Count -eq 1 -and [string]::IsNullOrWhiteSpace($TestFile[0]))) {
        return Get-TestSuitePaths -Suite $suiteString -RepoRoot $RepoRoot
    }
    else {
        return Get-SpecificTestPaths -TestFile $TestFile -Suite $suiteString -RepoRoot $RepoRoot
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
    $existingDirs = $testPaths |
    ForEach-Object { Join-Path $RepoRoot $_ } |
    Where-Object { $_ -and -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_) }

    if (-not $existingDirs) {
        # Fallback to tests directory if no suite directories exist
        $existingDirs = @(Join-Path $RepoRoot 'tests')
    }

    # Expand directories to individual test files (similar to analyze-coverage.ps1)
    $allTestFiles = @()
    foreach ($dir in $existingDirs) {
        $testFiles = Get-TestFilesFromDirectory -Directory $dir
        $allTestFiles += $testFiles
    }

    # Remove duplicates and return sorted paths
    return $allTestFiles | Sort-Object -Unique
}

<#
.SYNOPSIS
    Resolves specific test file or directory paths.

.DESCRIPTION
    Handles resolution of user-specified test files or directories,
    including recursive discovery of .tests.ps1 files in directories.
    Supports multiple test files or directories.
#>
function Get-SpecificTestPaths {
    param(
        [string[]]$TestFile,
        [string]$Suite,
        [string]$RepoRoot
    )

    if ($null -eq $TestFile -or $TestFile.Count -eq 0) {
        throw "TestFile parameter cannot be null or empty"
    }

    $allPaths = @()
    
    foreach ($testPath in $TestFile) {
        if ([string]::IsNullOrWhiteSpace($testPath)) {
            continue
        }

        try {
            $resolvedTestPath = (Resolve-Path -Path $testPath -ErrorAction Stop).ProviderPath
        }
        catch [System.Management.Automation.ItemNotFoundException] {
            throw "Test file or directory not found: $testPath"
        }
        catch {
            throw "Failed to resolve test path '$testPath': $($_.Exception.Message)"
        }

        if (Test-Path -LiteralPath $resolvedTestPath -PathType Container) {
            $directoryPaths = Get-TestFilesFromDirectory -Directory $resolvedTestPath
            $allPaths += $directoryPaths
        }
        else {
            $allPaths += $resolvedTestPath
        }
    }

    # Remove duplicates and return sorted paths
    return $allPaths | Sort-Object -Unique
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

