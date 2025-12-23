<#
scripts/utils/code-quality/modules/TestLister.psm1

.SYNOPSIS
    Test listing utilities for displaying available tests.

.DESCRIPTION
    Provides functions for discovering and listing tests without running them.
#>

# Import Logging module
$loggingModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib' 'core' 'Logging.psm1'
if ($loggingModulePath -and -not [string]::IsNullOrWhiteSpace($loggingModulePath) -and (Test-Path -LiteralPath $loggingModulePath)) {
    Import-Module $loggingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Lists all tests in the specified test paths.

.DESCRIPTION
    Discovers and lists all tests from the provided test file paths without executing them.
    Parses test files to extract test names and structure.

.PARAMETER TestPaths
    Array of test file or directory paths to scan.

.PARAMETER RepoRoot
    Repository root directory path.

.OUTPUTS
    Hashtable with TestFiles (array), TestCount (int), and Tests (array of hashtables with Name, File, Describe, Context)
#>
function Get-TestList {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string[]]$TestPaths,
        [string]$RepoRoot
    )

    $result = @{
        TestFiles = @()
        TestCount = 0
        Tests     = @()
    }

    foreach ($testPath in $TestPaths) {
        if ($testPath -and -not [string]::IsNullOrWhiteSpace($testPath) -and -not (Test-Path -LiteralPath $testPath)) {
            continue
        }

        $resolvedPath = (Resolve-Path $testPath).ProviderPath

        if ($resolvedPath -and -not [string]::IsNullOrWhiteSpace($resolvedPath) -and (Test-Path -LiteralPath $resolvedPath -PathType Container)) {
            # Directory - find all test files
            $testFiles = Get-ChildItem -Path $resolvedPath -Filter '*.tests.ps1' -Recurse -File -ErrorAction SilentlyContinue
        }
        else {
            # Single file
            $testFiles = @(Get-Item $resolvedPath)
        }

        foreach ($testFile in $testFiles) {
            if ($testFile.Name -notlike '*.tests.ps1') {
                continue
            }

            $result.TestFiles += $testFile.FullName

            try {
                $content = Get-Content $testFile.FullName -Raw -ErrorAction Stop
                
                # Parse test structure using regex
                # Look for Describe, Context, and It blocks
                $describePattern = "(?m)^\s*Describe\s+['""]([^'""]+)['""]"
                $contextPattern = "(?m)^\s*Context\s+['""]([^'""]+)['""]"
                $itPattern = "(?m)^\s*It\s+['""]([^'""]+)['""]"

                $describes = [regex]::Matches($content, $describePattern)
                $contexts = [regex]::Matches($content, $contextPattern)
                $its = [regex]::Matches($content, $itPattern)

                # Build test list
                foreach ($itMatch in $its) {
                    $testInfo = @{
                        Name     = $itMatch.Groups[1].Value
                        File     = $testFile.FullName
                        Describe = ''
                        Context  = ''
                    }

                    # Find the closest Describe block before this It
                    $itPosition = $itMatch.Index
                    $closestDescribe = $describes | Where-Object { $_.Index -lt $itPosition } | Sort-Object Index -Descending | Select-Object -First 1
                    if ($closestDescribe) {
                        $testInfo.Describe = $closestDescribe.Groups[1].Value
                    }

                    # Find the closest Context block before this It
                    $closestContext = $contexts | Where-Object { $_.Index -lt $itPosition } | Sort-Object Index -Descending | Select-Object -First 1
                    if ($closestContext) {
                        $testInfo.Context = $closestContext.Groups[1].Value
                    }

                    $result.Tests += $testInfo
                    $result.TestCount++
                }
            }
            catch {
                Write-ScriptMessage -Message "Failed to parse test file $($testFile.FullName): $($_.Exception.Message)" -LogLevel 'Warning'
            }
        }
    }

    $result.TestFiles = $result.TestFiles | Select-Object -Unique | Sort-Object
    return $result
}

<#
.SYNOPSIS
    Displays a formatted list of tests.

.DESCRIPTION
    Outputs a user-friendly formatted list of tests with their structure.

.PARAMETER TestList
    Hashtable returned from Get-TestList.

.PARAMETER ShowDetails
    Show detailed information including Describe and Context blocks.

.OUTPUTS
    None - writes to console
#>
function Show-TestList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$TestList,
        [switch]$ShowDetails
    )

    Write-Host "`n=== Test Discovery Results ===" -ForegroundColor Cyan
    Write-Host "Test Files: $($TestList.TestFiles.Count)" -ForegroundColor Green
    Write-Host "Total Tests: $($TestList.TestCount)" -ForegroundColor Green
    Write-Host ""

    if ($TestList.TestFiles.Count -gt 0) {
        Write-Host "Test Files:" -ForegroundColor Yellow
        foreach ($file in $TestList.TestFiles) {
            $relativePath = if ($file -like "*$($TestList.TestFiles[0].Split([IO.Path]::DirectorySeparatorChar)[-3])*") {
                # Try to make relative
                $file
            }
            else {
                $file
            }
            Write-Host "  - $relativePath" -ForegroundColor Gray
        }
        Write-Host ""
    }

    if ($TestList.Tests.Count -gt 0) {
        if ($ShowDetails) {
            Write-Host "Tests (with structure):" -ForegroundColor Yellow
            $currentFile = ''
            $currentDescribe = ''
            $currentContext = ''

            foreach ($test in $TestList.Tests) {
                if ($test.File -ne $currentFile) {
                    $currentFile = $test.File
                    Write-Host "`n  File: $currentFile" -ForegroundColor Cyan
                }

                if ($test.Describe -ne $currentDescribe) {
                    $currentDescribe = $test.Describe
                    if ($currentDescribe) {
                        Write-Host "    Describe: $currentDescribe" -ForegroundColor Magenta
                    }
                }

                if ($test.Context -ne $currentContext) {
                    $currentContext = $test.Context
                    if ($currentContext) {
                        Write-Host "      Context: $currentContext" -ForegroundColor Blue
                    }
                }

                Write-Host "        It: $($test.Name)" -ForegroundColor White
            }
        }
        else {
            Write-Host "Tests:" -ForegroundColor Yellow
            foreach ($test in $TestList.Tests) {
                $testPath = if ($test.Describe) {
                    if ($test.Context) {
                        "$($test.Describe) > $($test.Context) > $($test.Name)"
                    }
                    else {
                        "$($test.Describe) > $($test.Name)"
                    }
                }
                else {
                    $test.Name
                }
                Write-Host "  - $testPath" -ForegroundColor Gray
            }
        }
    }

    Write-Host ""
}

Export-ModuleMember -Function @(
    'Get-TestList',
    'Show-TestList'
)

