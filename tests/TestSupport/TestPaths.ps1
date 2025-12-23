# ===============================================
# TestPaths.ps1
# Test path resolution and directory utilities
# ===============================================

<#
.SYNOPSIS
    Locates the repository root directory for the tests.
.DESCRIPTION
    Walks up from the supplied start path until it finds a .git folder and returns that directory.
.PARAMETER StartPath
    The path to begin searching from; defaults to the calling script root.
.OUTPUTS
    System.String
#>
function Get-TestRepoRoot {
    param(
        [Parameter()]
        [string]$StartPath = $PSScriptRoot
    )

    $current = Get-Item -LiteralPath $StartPath
    while ($null -ne $current) {
        if (Test-Path -LiteralPath (Join-Path $current.FullName '.git')) {
            return $current.FullName
        }
        $current = $current.Parent
    }

    throw "Unable to locate repository root starting from $StartPath"
}

<#
.SYNOPSIS
    Resolves a path relative to the repository root.
.DESCRIPTION
    Combines the repository root with the provided relative path and optionally validates existence.
.PARAMETER RelativePath
    The path relative to the repository root to resolve.
.PARAMETER StartPath
    Optional path used to locate the repository root when different from the current script.
.PARAMETER EnsureExists
    When set, throws if the resolved path does not exist.
.OUTPUTS
    System.String
#>
function Get-TestPath {
    param(
        [Parameter(Mandatory)]
        [string]$RelativePath,

        [string]$StartPath = $PSScriptRoot,

        [switch]$EnsureExists
    )

    $repoRoot = Get-TestRepoRoot -StartPath $StartPath
    $fullPath = Join-Path $repoRoot $RelativePath

    if ($EnsureExists -and -not (Test-Path -LiteralPath $fullPath)) {
        throw "Resolved test path does not exist: $fullPath"
    }

    return $fullPath
}

<#
.SYNOPSIS
    Returns the path to a test suite directory.
.DESCRIPTION
    Resolves the absolute path for the unit, integration, or performance test suite folders.
.PARAMETER Suite
    The name of the suite to resolve; must be Unit, Integration, or Performance.
.PARAMETER StartPath
    Optional start path used to determine the repository root.
.PARAMETER EnsureExists
    When supplied, validates that the suite path exists on disk.
.OUTPUTS
    System.String
#>
function Get-TestSuitePath {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Unit', 'Integration', 'Performance')]
        [string]$Suite,

        [string]$StartPath = $PSScriptRoot,

        [switch]$EnsureExists
    )

    $relative = Join-Path 'tests' ($Suite.ToLower())
    return Get-TestPath -RelativePath $relative -StartPath $StartPath -EnsureExists:$EnsureExists
}

<#
.SYNOPSIS
    Enumerates test files for a given suite.
.DESCRIPTION
    Retrieves all *.tests.ps1 files under the requested suite directory, sorted by full path.
.PARAMETER Suite
    The target suite to enumerate; must be Unit, Integration, or Performance.
.PARAMETER StartPath
    Optional start path used to determine the repository root.
.OUTPUTS
    System.IO.FileInfo
#>
function Get-TestSuiteFiles {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Unit', 'Integration', 'Performance')]
        [string]$Suite,

        [string]$StartPath = $PSScriptRoot
    )

    $suitePath = Get-TestSuitePath -Suite $Suite -StartPath $StartPath -EnsureExists
    $scripts = Get-ChildItem -LiteralPath $suitePath -Filter '*.tests.ps1' -File -Recurse | Sort-Object FullName
    return $scripts
}

<#
.SYNOPSIS
    Creates a temporary directory for tests.
.DESCRIPTION
    Generates a unique directory in the test-data directory using the provided prefix and returns its path.
.PARAMETER Prefix
    Text used at the start of the generated directory name.
.OUTPUTS
    System.String
#>
function New-TestTempDirectory {
    param(
        [string]$Prefix = 'PesterTest'
    )

    # Use test-data directory instead of system temp to keep all test artifacts together
    $repoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $testDataRoot = Join-Path $repoRoot 'tests' 'test-data'
    
    # Ensure test-data directory exists
    if ($testDataRoot -and -not [string]::IsNullOrWhiteSpace($testDataRoot) -and -not (Test-Path -LiteralPath $testDataRoot)) {
        New-Item -ItemType Directory -Path $testDataRoot -Force | Out-Null
    }
    
    $uniqueName = '{0}-{1}' -f $Prefix, ([System.Guid]::NewGuid().ToString())
    $path = Join-Path $testDataRoot $uniqueName
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    return $path
}

<#
.SYNOPSIS
    Gets or creates a test script path in the test artifacts directory.
.DESCRIPTION
    Creates a test script file in tests/test-artifacts/ that mirrors the repository structure.
    This allows tests to create scripts in locations like scripts/utils/ without polluting the actual repository.
    The path resolution functions will still work correctly since tests/test-artifacts/ is under the repo root.
.PARAMETER RelativePath
    The relative path from the repository root (e.g., 'scripts/utils/test.ps1').
.PARAMETER StartPath
    Optional path used to determine the repository root.
.PARAMETER Content
    Optional content to write to the file. Defaults to '# Test script'.
.OUTPUTS
    System.String - The full path to the created test script file.
#>
function Get-TestScriptPath {
    param(
        [Parameter(Mandatory)]
        [string]$RelativePath,

        [string]$StartPath = $PSScriptRoot,

        [string]$Content = '# Test script'
    )

    $repoRoot = Get-TestRepoRoot -StartPath $StartPath
    $testArtifactsRoot = Join-Path $repoRoot 'tests' 'test-artifacts'
    
    # Ensure test-artifacts directory exists
    if (-not (Test-Path -LiteralPath $testArtifactsRoot)) {
        New-Item -ItemType Directory -Path $testArtifactsRoot -Force | Out-Null
    }
    
    # Create the full path in test-artifacts mirroring the repository structure
    $testScriptPath = Join-Path $testArtifactsRoot $RelativePath
    
    # Ensure parent directory exists
    $parentDir = Split-Path -Path $testScriptPath -Parent
    if (-not (Test-Path -LiteralPath $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }
    
    # Create the file if it doesn't exist
    if (-not (Test-Path -LiteralPath $testScriptPath)) {
        Set-Content -Path $testScriptPath -Value $Content -ErrorAction SilentlyContinue
    }
    
    return $testScriptPath
}

