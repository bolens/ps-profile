<#
scripts/utils/code-quality/modules/TestResultReader.psm1

.SYNOPSIS
    Test result reading utilities for re-running failed tests.

.DESCRIPTION
    Provides functions for reading saved test results and extracting failed test information.
#>

# Import Logging module
$loggingModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'core' 'Logging.psm1'
if ($loggingModulePath -and -not [string]::IsNullOrWhiteSpace($loggingModulePath) -and (Test-Path -LiteralPath $loggingModulePath)) {
    Import-Module $loggingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Reads the last test result file and extracts failed test information.

.DESCRIPTION
    Searches for the most recent test result file (XML or JSON) and extracts
    information about failed tests, including test names and file paths.

.PARAMETER TestResultPath
    Directory path where test results are stored. If not specified, searches default locations.

.PARAMETER RepoRoot
    Repository root directory path.

.OUTPUTS
    Hashtable with FailedTests (array of test names) and TestFiles (array of test file paths)
#>
function Get-FailedTestsFromLastRun {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [string]$TestResultPath,
        [string]$RepoRoot
    )

    $result = @{
        FailedTests = @()
        TestFiles   = @()
        Success     = $false
        Message     = ''
    }

    # Determine search paths
    $searchPaths = @()
    if ($TestResultPath -and -not [string]::IsNullOrWhiteSpace($TestResultPath) -and (Test-Path -LiteralPath $TestResultPath)) {
        $searchPaths += $TestResultPath
    }
    if ($RepoRoot) {
        $defaultPath = Join-Path $RepoRoot 'scripts' 'data' 'test-results'
        if ($defaultPath -and -not [string]::IsNullOrWhiteSpace($defaultPath) -and (Test-Path -LiteralPath $defaultPath)) {
            $searchPaths += $defaultPath
        }
    }

    if ($searchPaths.Count -eq 0) {
        $result.Message = "No test result directory found. Run tests first to generate results."
        return $result
    }

    # Find most recent test result file
    $resultFiles = @()
    foreach ($searchPath in $searchPaths) {
        $resultFiles += Get-ChildItem -Path $searchPath -Filter '*.xml' -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like '*test*result*' -or $_.Name -like '*pester*' } |
        Sort-Object LastWriteTime -Descending
    }

    if ($resultFiles.Count -eq 0) {
        $result.Message = "No test result files found. Run tests first to generate results."
        return $result
    }

    $latestResultFile = $resultFiles[0]
    
    try {
        # Try to parse as XML (NUnit format)
        [xml]$xmlResult = Get-Content $latestResultFile.FullName -ErrorAction Stop
        
        $failedTests = @()
        $testFiles = @()

        if ($xmlResult.'test-results') {
            # NUnit XML format
            $testCases = $xmlResult.'test-results'.SelectNodes('//test-case[@result="Failure" or @result="Error"]')
            foreach ($testCase in $testCases) {
                $testName = $testCase.name
                $failedTests += $testName
                
                # Extract test file path from test name or fixture
                $fixture = $testCase.GetAttribute('fixturename')
                if ($fixture) {
                    # Try to find the test file
                    $testFile = $testCase.GetAttribute('classname')
                    if ($testFile -and $testFile -like '*.tests.ps1') {
                        $testFiles += $testFile
                    }
                }
            }
        }
        elseif ($xmlResult.testRun) {
            # Alternative XML format
            $testCases = $xmlResult.testRun.SelectNodes('//test-case[@outcome="Failed" or @outcome="Error"]')
            foreach ($testCase in $testCases) {
                $testName = $testCase.GetAttribute('name')
                $failedTests += $testName
            }
        }

        # Also try to find test files from the result file location or test names
        if ($failedTests.Count -gt 0) {
            # Extract test file patterns from failed test names
            # Test names often follow pattern: "Describe 'TestName' Context 'SubTest' It 'Should do something'"
            # We can extract the file by looking at the structure
            
            # Try to find test files that might contain these tests
            if ($RepoRoot) {
                $testsDir = Join-Path $RepoRoot 'tests'
                $allTestFiles = Get-ChildItem -Path $testsDir -Filter '*.tests.ps1' -Recurse -ErrorAction SilentlyContinue
                
                # For each failed test, try to find matching test file
                foreach ($failedTest in $failedTests) {
                    # Simple heuristic: look for test files that might contain this test
                    # This is a best-effort approach
                    $matchingFiles = $allTestFiles | Where-Object {
                        $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
                        if ($content) {
                            # Check if test name appears in file (with some flexibility)
                            $testPattern = $failedTest -replace '[\[\](){}]', '\$&'
                            $content -match $testPattern
                        }
                    }
                    
                    if ($matchingFiles) {
                        $testFiles += $matchingFiles.FullName
                    }
                }
            }
        }

        $result.FailedTests = $failedTests | Select-Object -Unique
        $result.TestFiles = $testFiles | Select-Object -Unique
        $result.Success = $true
        $result.Message = "Found $($failedTests.Count) failed test(s) in $($latestResultFile.Name)"
        $result.ResultFile = $latestResultFile.FullName
        
        return $result
    }
    catch {
        $result.Message = "Failed to parse test result file: $($_.Exception.Message)"
        return $result
    }
}

<#
.SYNOPSIS
    Gets test file paths from failed test names.

.DESCRIPTION
    Attempts to map failed test names to their source test files by searching
    test files for matching test names.

.PARAMETER FailedTestNames
    Array of failed test names to map to files.

.PARAMETER RepoRoot
    Repository root directory path.

.OUTPUTS
    System.String[] - Array of test file paths
#>
function Get-TestFilesFromFailedTestNames {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [string[]]$FailedTestNames,
        [string]$RepoRoot
    )

    if (-not $RepoRoot -or [string]::IsNullOrWhiteSpace($RepoRoot) -or -not (Test-Path -LiteralPath $RepoRoot)) {
        return @()
    }

    $testsDir = Join-Path $RepoRoot 'tests'
    if ($testsDir -and -not [string]::IsNullOrWhiteSpace($testsDir) -and -not (Test-Path -LiteralPath $testsDir)) {
        return @()
    }

    $testFiles = @()
    $allTestFiles = Get-ChildItem -Path $testsDir -Filter '*.tests.ps1' -Recurse -ErrorAction SilentlyContinue

    foreach ($testFile in $allTestFiles) {
        try {
            $content = Get-Content $testFile.FullName -Raw -ErrorAction Stop
            foreach ($failedTest in $FailedTestNames) {
                # Escape special regex characters but allow wildcards
                $testPattern = $failedTest -replace '([\[\](){}.*+?^$|\\])', '\$1'
                # Also try without escaping for simple matches
                if ($content -match $testPattern -or $content -like "*$failedTest*") {
                    $testFiles += $testFile.FullName
                    break
                }
            }
        }
        catch {
            # Skip files we can't read
            continue
        }
    }

    return $testFiles | Select-Object -Unique | Sort-Object
}

Export-ModuleMember -Function @(
    'Get-FailedTestsFromLastRun',
    'Get-TestFilesFromFailedTestNames'
)

