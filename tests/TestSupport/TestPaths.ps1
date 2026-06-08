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
    Register-TestCleanupPath -Path $path
    return $path
}

<#
.SYNOPSIS
    Gets the tests/test-data directory path.
.DESCRIPTION
    Resolves and optionally creates the test-data directory used for transient test files.
.PARAMETER StartPath
    Optional path used to determine repository root.
.PARAMETER EnsureExists
    Creates the directory when it does not already exist.
.OUTPUTS
    System.String
#>
function Get-TestDataPath {
    param(
        [string]$StartPath = $PSScriptRoot,
        [switch]$EnsureExists
    )

    $repoRoot = Get-TestRepoRoot -StartPath $StartPath
    $testDataPath = Join-Path $repoRoot (Join-Path 'tests' 'test-data')

    if ($EnsureExists -and -not (Test-Path -LiteralPath $testDataPath)) {
        New-Item -ItemType Directory -Path $testDataPath -Force | Out-Null
    }

    return $testDataPath
}

<#
.SYNOPSIS
    Gets the tests/test-artifacts directory path.
.DESCRIPTION
    Resolves and optionally creates the test-artifacts directory used for generated test reports.
.PARAMETER StartPath
    Optional path used to determine repository root.
.PARAMETER EnsureExists
    Creates the directory when it does not already exist.
.OUTPUTS
    System.String
#>
function Get-TestArtifactsPath {
    param(
        [string]$StartPath = $PSScriptRoot,
        [switch]$EnsureExists
    )

    $repoRoot = Get-TestRepoRoot -StartPath $StartPath
    $testArtifactsPath = Join-Path $repoRoot (Join-Path 'tests' 'test-artifacts')

    if ($EnsureExists -and -not (Test-Path -LiteralPath $testArtifactsPath)) {
        New-Item -ItemType Directory -Path $testArtifactsPath -Force | Out-Null
    }

    return $testArtifactsPath
}

<#
.SYNOPSIS
    Creates a transient test data file path.
.DESCRIPTION
    Returns a unique file path under tests/test-data and optionally writes file content.
.PARAMETER Prefix
    Prefix used for the generated filename.
.PARAMETER Extension
    File extension to use (with or without a leading dot).
.PARAMETER StartPath
    Optional path used to determine repository root.
.PARAMETER Content
    Optional content written to the generated file path.
.OUTPUTS
    System.String
#>
function New-TestTempFile {
    param(
        [string]$Prefix = 'PesterTest',
        [string]$Extension = '.tmp',
        [string]$StartPath = $PSScriptRoot,
        [string]$Content
    )

    $testDataPath = Get-TestDataPath -StartPath $StartPath -EnsureExists
    $normalizedExtension = if ([string]::IsNullOrWhiteSpace($Extension)) { '.tmp' } elseif ($Extension.StartsWith('.')) { $Extension } else { ".$Extension" }
    $fileName = '{0}-{1}{2}' -f $Prefix, ([System.Guid]::NewGuid().ToString()), $normalizedExtension
    $tempFilePath = Join-Path $testDataPath $fileName

    if ($PSBoundParameters.ContainsKey('Content')) {
        Set-Content -Path $tempFilePath -Value $Content -Encoding UTF8
    }

    Register-TestCleanupPath -Path $tempFilePath
    return $tempFilePath
}

<#
.SYNOPSIS
    Returns a path for a transient test artifact under tests/test-data.
.DESCRIPTION
    Use this instead of bare filenames (for example backup.dump) that would write to the
    repository root when a real external tool is invoked during integration tests.
.PARAMETER FileName
    File name to place under tests/test-data.
.PARAMETER StartPath
    Optional path used to determine the repository root.
.OUTPUTS
    System.String
#>
function Get-TestArtifactPath {
    param(
        [Parameter(Mandatory)]
        [string]$FileName,

        [string]$StartPath = $PSScriptRoot
    )

    $testDataPath = Get-TestDataPath -StartPath $StartPath -EnsureExists
    $artifactPath = Join-Path $testDataPath $FileName
    Register-TestCleanupPath -Path $artifactPath
    return $artifactPath
}

<#
.SYNOPSIS
    Reads the exact on-disk bytes for a file so tests can restore it later.
.PARAMETER Path
    Absolute path to the file to back up.
.OUTPUTS
    System.Byte[]
#>
function Backup-TestFileBytes {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    return [System.IO.File]::ReadAllBytes($Path)
}

<#
.SYNOPSIS
    Restores a file from a byte-for-byte backup created by Backup-TestFileBytes.
.PARAMETER Path
    Absolute path to the file to restore.
.PARAMETER Bytes
    Original file bytes captured before a temporary test mutation.
#>
function Restore-TestFileBytes {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [byte[]]$Bytes
    )

    [System.IO.File]::WriteAllBytes($Path, $Bytes)
}

<#
.SYNOPSIS
    Writes literal file content without adding PowerShell's default trailing newline.
.PARAMETER Path
    Absolute path to the file to write.
.PARAMETER Content
    Exact text content to persist.
#>
function Write-TestFileLiteralContent {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Content
    )

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

<#
.SYNOPSIS
    Initializes the per-test cleanup path registry.
#>
function Initialize-TestCleanupRegistry {
    if (-not (Get-Variable -Name 'TestCleanupPaths' -Scope Global -ErrorAction SilentlyContinue)) {
        $global:TestCleanupPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    }
}

<#
.SYNOPSIS
    Registers a file or directory for removal after the current test.
.PARAMETER Path
    Absolute or relative path created during the test.
#>
function Register-TestCleanupPath {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    Initialize-TestCleanupRegistry

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return
    }

    try {
        $resolvedPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
    }
    catch {
        $resolvedPath = $Path
    }

    [void]$global:TestCleanupPaths.Add($resolvedPath)
}

<#
.SYNOPSIS
    Removes paths registered during the current or most recent test.
#>
function Clear-RegisteredTestCleanupPaths {
    if ($env:PS_PROFILE_SKIP_TEST_CLEANUP -eq '1') {
        return
    }

    Initialize-TestCleanupRegistry

    foreach ($path in @($global:TestCleanupPaths | Sort-Object { $_.Length } -Descending)) {
        if ($path -and -not [string]::IsNullOrWhiteSpace($path) -and (Test-Path -LiteralPath $path)) {
            Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    $global:TestCleanupPaths.Clear()
}

<#
.SYNOPSIS
    Removes all transient content under tests/test-data and tests/test-artifacts.
.DESCRIPTION
    Deletes every file and directory inside the gitignored test storage folders while
    preserving the parent directories themselves. Safe to call before and after test runs
    because these locations are only used for generated test output.
.PARAMETER StartPath
    Optional path used to determine the repository root.
.OUTPUTS
    System.Collections.Hashtable
    Summary with RemovedItemCount and cleaned directory paths.
#>
function Clear-TestTransientStorage {
    param(
        [string]$StartPath = $PSScriptRoot
    )

    $summary = @{
        RemovedItemCount = 0
        CleanedPaths     = @()
    }

    if ($env:PS_PROFILE_SKIP_TEST_CLEANUP -eq '1') {
        return $summary
    }

    try {
        $repoRoot = Get-TestRepoRoot -StartPath $StartPath
    }
    catch {
        return $summary
    }

    foreach ($relativePath in @('tests\test-data', 'tests\test-artifacts')) {
        $storageRoot = Join-Path $repoRoot $relativePath
        if (-not (Test-Path -LiteralPath $storageRoot)) {
            continue
        }

        $summary.CleanedPaths += $storageRoot

        $children = @(Get-ChildItem -LiteralPath $storageRoot -Force -ErrorAction SilentlyContinue)
        foreach ($child in $children) {
            Remove-Item -LiteralPath $child.FullName -Recurse -Force -ErrorAction SilentlyContinue
            if (-not (Test-Path -LiteralPath $child.FullName)) {
                $summary.RemovedItemCount++
            }
        }
    }

    return $summary
}

<#
.SYNOPSIS
    Gets or creates a test script path in the test artifacts directory.
.DESCRIPTION
    Creates a test script file in tests/test-artifacts/ that mirrors repository-relative script paths.
    This allows tests to model paths like scripts/utils/*.ps1 without writing under real source directories.
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

    # Relative input must still model scripts/ paths, but generated fixtures should live under test-artifacts.
    $normalizedRelative = ($RelativePath -replace '\\', '/').TrimStart('/')
    if ($normalizedRelative -notmatch '^scripts/') {
        throw "Get-TestScriptPath RelativePath must begin with 'scripts/' (got: $RelativePath)"
    }

    $relativeWithPlatformSeparator = $normalizedRelative -replace '/', [IO.Path]::DirectorySeparatorChar
    $testScriptPath = Join-Path $repoRoot (Join-Path 'tests' (Join-Path 'test-artifacts' $relativeWithPlatformSeparator))

    # Ensure parent directory exists
    $parentDir = Split-Path -Path $testScriptPath -Parent
    if (-not (Test-Path -LiteralPath $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    # Create the file if it doesn't exist
    if (-not (Test-Path -LiteralPath $testScriptPath)) {
        Set-Content -Path $testScriptPath -Value $Content -ErrorAction SilentlyContinue
    }

    Register-TestCleanupPath -Path $testScriptPath
    return $testScriptPath
}

