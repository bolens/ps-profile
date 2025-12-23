<#
scripts/utils/code-quality/modules/TestPathUtilities.psm1

.SYNOPSIS
    Test path validation, filtering, and logging utilities.

.DESCRIPTION
    Provides functions for validating, filtering, and logging test path discovery.
#>

# Import Logging module for Write-ScriptMessage
$loggingModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'core' 'Logging.psm1'
if ($loggingModulePath -and -not [string]::IsNullOrWhiteSpace($loggingModulePath) -and (Test-Path -LiteralPath $loggingModulePath)) {
    Import-Module $loggingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Import OutputPathUtils module for ConvertTo-RepoRelativePath
$outputPathUtilsModulePath = Join-Path $PSScriptRoot 'OutputPathUtils.psm1'
if ($outputPathUtilsModulePath -and -not [string]::IsNullOrWhiteSpace($outputPathUtilsModulePath) -and (Test-Path -LiteralPath $outputPathUtilsModulePath)) {
    Import-Module $outputPathUtilsModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Validates that test paths exist and are accessible.

.DESCRIPTION
    Checks that the provided test paths exist and logs appropriate messages
    about test discovery results.
#>
function Test-TestPaths {
    param(
        [string[]]$TestPaths,
        [string]$Suite,
        [string]$RepoRoot
    )

    $validPaths = @()
    $invalidPaths = @()

    foreach ($path in $TestPaths) {
        if (Test-Path -LiteralPath $path) {
            $validPaths += $path
        }
        else {
            $invalidPaths += $path
        }
    }

    if ($invalidPaths) {
        Write-ScriptMessage -Message "Invalid test paths: $($invalidPaths -join ', ')" -LogLevel 'Warning'
    }

    if (-not $validPaths) {
        $messageTarget = if ($Suite -eq 'All') { 'tests' } else { "tests/$Suite" }
        $relativeTarget = ConvertTo-RepoRelativePath (Join-Path $RepoRoot $messageTarget)
        Write-ScriptMessage -Message "No valid test paths found for suite '$Suite' under $relativeTarget" -LogLevel 'Warning'
        # Return absolute path for consistency with other return values
        $fallbackPath = Join-Path $RepoRoot 'tests'
        if ($fallbackPath -and -not [string]::IsNullOrWhiteSpace($fallbackPath) -and (Test-Path -LiteralPath $fallbackPath)) {
            return @($fallbackPath)
        }
        return @('tests')  # Fallback to relative if absolute doesn't exist
    }

    return $validPaths
}

<#
.SYNOPSIS
    Logs information about discovered test paths.

.DESCRIPTION
    Outputs informative messages about which test paths were discovered
    for execution.
#>
function Write-TestDiscoveryInfo {
    param(
        [string[]]$TestPaths,
        [string]$Suite,
        [string]$TestFile
    )

    if ([string]::IsNullOrWhiteSpace($TestFile)) {
        $suiteLabel = if ($Suite -eq 'All') { 'all suites' } else { "suite '$Suite'" }
        $pathList = $TestPaths -join ', '
        Write-ScriptMessage -Message ("Running Pester tests for {0}: {1}" -f $suiteLabel, $pathList)
    }
    else {
        if ($Suite -ne 'All') {
            Write-ScriptMessage -Message "TestFile parameter specified; overriding Suite '$Suite'" -LogLevel 'Warning'
        }

        if ($TestPaths.Count -eq 1 -and (Test-Path -LiteralPath $TestPaths[0] -PathType Leaf)) {
            $relativePath = ConvertTo-RepoRelativePath $TestPaths[0]
            Write-ScriptMessage -Message "Running Pester tests: $relativePath"
        }
        else {
            $relativeFiles = $TestPaths | ForEach-Object { ConvertTo-RepoRelativePath $_ }
            Write-ScriptMessage -Message "Running Pester tests: $($relativeFiles -join ', ')"
        }
    }
}

<#
.SYNOPSIS
    Filters test paths to exclude test-runner test files.

.DESCRIPTION
    Normalizes and deduplicates test paths, excluding test-runner test files
    to prevent recursive execution loops. Handles both directories and files.

.PARAMETER TestPaths
    Array of test paths to filter.

.PARAMETER TestRunnerScriptPath
    Path to the test runner script itself (to exclude).

.OUTPUTS
    System.String[] - Filtered and normalized test paths
#>
function Filter-TestPaths {
    param(
        [Parameter(Mandatory)]
        [string[]]$TestPaths,

        [string]$TestRunnerScriptPath
    )

    # List of test-runner test files to exclude
    $testRunnerTestFiles = @(
        'test-runner-integration.tests.ps1',
        'test-runner-error-handling.tests.ps1',
        'baseline-comparison.tests.ps1',
        'test-runner-performance.tests.ps1',
        'test-runner-run-pester.tests.ps1'
    )

    $filteredPaths = @()

    foreach ($path in $TestPaths) {
        if ($path -and -not [string]::IsNullOrWhiteSpace($path) -and -not (Test-Path -LiteralPath $path)) {
            continue
        }

        $resolvedPath = (Resolve-Path $path).ProviderPath

        # Exclude test runner script itself
        if ($TestRunnerScriptPath -and $resolvedPath -eq $TestRunnerScriptPath) {
            continue
        }

        # If it's a directory, expand to individual test files and filter
        if ($resolvedPath -and -not [string]::IsNullOrWhiteSpace($resolvedPath) -and (Test-Path -LiteralPath $resolvedPath -PathType Container)) {
            $testFiles = Get-ChildItem -Path $resolvedPath -Filter '*.tests.ps1' -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Name -notin $testRunnerTestFiles
            } |
            Select-Object -ExpandProperty FullName -Unique

            if ($testFiles) {
                $filteredPaths += $testFiles
            }
        }
        else {
            # For files, check if it's a test-runner test file
            $fileName = Split-Path $resolvedPath -Leaf
            if ($fileName -notin $testRunnerTestFiles) {
                $filteredPaths += $resolvedPath
            }
        }
    }

    return $filteredPaths | Select-Object -Unique | Sort-Object
}

Export-ModuleMember -Function @(
    'Test-TestPaths',
    'Write-TestDiscoveryInfo',
    'Filter-TestPaths'
)

