# ===============================================
# analyze-coverage.ps1
# Test coverage analysis script
# ===============================================
# 
# NOTE: Test-to-source file mappings are maintained incrementally.
# When adding new test files that don't match standard naming patterns,
# add them to the $testToSourceMappings hashtable around line 98.
# When adding new source files that need explicit test matching,
# add them to the $sourceToTestMappings hashtable around line 185.

<#
.SYNOPSIS
    Analyzes test coverage for specified files or directories.

.DESCRIPTION
    Generates a comprehensive coverage report identifying functions with
    low coverage and missing test cases.

.PARAMETER Path
    Files or directories to analyze. Defaults to profile.d/bootstrap.

.PARAMETER OutputPath
    Path to save coverage report. Defaults to scripts/data/coverage.

.EXAMPLE
    .\analyze-coverage.ps1 -Path profile.d/bootstrap

    Analyzes coverage for bootstrap modules (runs non-interactively by default).

.EXAMPLE
    .\analyze-coverage.ps1 -Path profile.d/bootstrap/ModuleLoading.ps1

    Analyzes coverage for a specific file.
#>

[CmdletBinding()]
param(
    [string[]]$Path = @('profile.d/bootstrap'),
    [string]$OutputPath = 'scripts/data/coverage'
)

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

$ErrorActionPreference = 'Stop'

# Suppress all confirmation prompts for non-interactive execution
# This script should never require user input - always run non-interactively
$ConfirmPreference = 'None'
$global:ConfirmPreference = 'None'

# Set default parameter values to suppress prompts for Remove-Item
if (-not $PSDefaultParameterValues) {
    $PSDefaultParameterValues = @{}
}
$PSDefaultParameterValues['Remove-Item:Confirm'] = $false
$PSDefaultParameterValues['Remove-Item:Force'] = $true
$PSDefaultParameterValues['Remove-Item:Recurse'] = $true

# Ensure Pester is available
if (-not (Get-Module -ListAvailable -Name Pester | Where-Object { $_.Version -ge [version]'5.0.0' })) {
    Write-Error "Pester 5.0+ is required for coverage analysis"
    exit 1
}

Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop

# Resolve script root for relative paths
# Script is in scripts/utils/code-quality/, need to go up 3 levels to repo root
$scriptRoot = $PSScriptRoot
for ($i = 1; $i -le 3; $i++) {
    $scriptRoot = Split-Path -Parent $scriptRoot
}
if (-not (Test-Path $scriptRoot)) {
    $scriptRoot = $PWD
}

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Verbose "[coverage.analyze] Starting coverage analysis"
    Write-Verbose "[coverage.analyze] Paths to analyze: $($Path -join ', ')"
    Write-Verbose "[coverage.analyze] Output path: $OutputPath"
}

# Find source files and test files to analyze
# Optimized: Use List for better performance with Add() instead of +=
$sourceFiles = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
$testFiles = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
$testsRoot = Join-Path $scriptRoot 'tests'

$discoveryStartTime = Get-Date
foreach ($p in $Path) {
    # Resolve relative paths
    $resolvedPath = if ([System.IO.Path]::IsPathRooted($p)) {
        $p
    }
    else {
        Join-Path $scriptRoot $p
    }
    
    if (Test-Path -LiteralPath $resolvedPath -ErrorAction SilentlyContinue) {
        $item = Get-Item -LiteralPath $resolvedPath -ErrorAction SilentlyContinue
        
        # Check if this is a test file
        if ($item -and -not $item.PSIsContainer -and $item.Name -like '*.tests.ps1') {
            # This is a test file - add it directly
            $testFiles.Add($item)
            Write-Host "Detected test file: $($item.Name)" -ForegroundColor Cyan
            
            # Level 2: File discovery details
            if ($debugLevel -ge 2) {
                Write-Verbose "[coverage.analyze] Found test file: $($item.FullName)"
            }
            
            # Try to find corresponding source file for coverage
            # Extract potential source file name from test file name
            $testBaseName = [System.IO.Path]::GetFileNameWithoutExtension($item.Name)
            $testBaseName = $testBaseName -replace '\.tests$', ''
            
            # Common test file to source file mappings
            # NOTE: Mappings are maintained incrementally. Most test files follow naming patterns
            # (e.g., library-{ModuleName}.tests.ps1 → {ModuleName}.ps1) that allow automatic matching.
            # Only add explicit mappings when:
            # 1. Test file name doesn't follow standard patterns
            # 2. Test file tests multiple source files
            # 3. Pattern matching fails to find the correct source file
            $testToSourceMappings = @{
                # Module Loading tests
                'library-module-loading'            = @('ModuleLoading.ps1')
                'library-module-loading-additional' = @('ModuleLoading.ps1')
                'module-loading-standard'           = @('ModuleLoading.ps1')
                
                # Function Registration tests
                'library-tool-wrapper'              = @('FunctionRegistration.ps1')
                
                # Bootstrap integration tests (test multiple files)
                'bootstrap-helper-functions'        = @('FunctionRegistration.ps1', 'CommandCache.ps1', 'ModulePathCache.ps1')
                'bootstrap-idempotency'             = @('FunctionRegistration.ps1')
                'bootstrap-performance'             = @('FunctionRegistration.ps1', 'CommandCache.ps1')
                'bootstrap-scoping'                 = @('FunctionRegistration.ps1')
                
                # Command/Cache tests
                'library-command'                   = @('CommandCache.ps1')
            }
            
            # Check for direct mappings first
            $mappedSources = $null
            foreach ($key in $testToSourceMappings.Keys) {
                if ($testBaseName -like "*$key*") {
                    $mappedSources = $testToSourceMappings[$key]
                    break
                }
            }
            
            # Search for source files
            $profileDir = Join-Path $scriptRoot 'profile.d'
            $scriptsLibDir = Join-Path $scriptRoot 'scripts' 'lib'
            
            if ($mappedSources) {
                # Use direct mappings
                foreach ($sourceName in $mappedSources) {
                    try {
                        # Optimized: Filter in foreach loop instead of Where-Object
                        $allFound = Get-ChildItem -Path $profileDir -Filter $sourceName -Recurse -File -ErrorAction SilentlyContinue
                        foreach ($item in $allFound) {
                            if ($item.Name -notlike '*.tests.ps1') {
                                $sourceFiles.Add($item)
                            }
                        }
                        # Also check scripts/lib
                        $allFound = Get-ChildItem -Path $scriptsLibDir -Filter $sourceName -Recurse -File -ErrorAction SilentlyContinue
                        foreach ($item in $allFound) {
                            if ($item.Name -notlike '*.tests.ps1') {
                                $sourceFiles.Add($item)
                            }
                        }
                    }
                    catch {
                        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                            Write-StructuredWarning -Message "Failed to find source file" -OperationName 'coverage.analyze.find-source' -Context @{
                                source_name = $sourceName
                                profile_dir = $profileDir
                                scripts_lib_dir = $scriptsLibDir
                            } -Code 'SourceFileSearchFailed'
                        }
                    }
                }
            }
            else {
                # Try pattern matching
                $testBaseName = $testBaseName -replace '^library-', '' -replace '^bootstrap-', ''
                # Optimized: Build pattern without ForEach-Object pipeline
                $words = $testBaseName.Replace('-', ' ').Split(' ')
                $pascalCaseParts = [System.Collections.Generic.List[string]]::new()
                foreach ($word in $words) {
                    if ($word.Length -gt 0) {
                        $pascalCaseParts.Add($word.Substring(0, 1).ToUpper() + $word.Substring(1))
                    }
                }
                $pascalCase = $pascalCaseParts -join ''
                $sourcePatterns = @(
                    "*$testBaseName*.ps1",
                    "*$($testBaseName.Replace('-', ''))*.ps1",
                    "*$pascalCase*.ps1"
                )
                
                foreach ($pattern in $sourcePatterns) {
                    try {
                        # Optimized: Filter in foreach loop instead of Where-Object
                        $allFound = Get-ChildItem -Path $profileDir -Filter $pattern -Recurse -File -ErrorAction SilentlyContinue
                        foreach ($item in $allFound) {
                            if ($item.Name -notlike '*.tests.ps1') {
                                $sourceFiles.Add($item)
                            }
                        }
                        $allFound = Get-ChildItem -Path $scriptsLibDir -Filter $pattern -Recurse -File -ErrorAction SilentlyContinue
                        foreach ($item in $allFound) {
                            if ($item.Name -notlike '*.tests.ps1') {
                                $sourceFiles.Add($item)
                            }
                        }
                    }
                    catch {
                        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                            Write-StructuredWarning -Message "Failed to search for source files with pattern" -OperationName 'coverage.analyze.find-source-pattern' -Context @{
                                pattern = $pattern
                                profile_dir = $profileDir
                                scripts_lib_dir = $scriptsLibDir
                            } -Code 'SourceFilePatternSearchFailed'
                        }
                    }
                }
            }
        }
        elseif ($item -and $item.PSIsContainer) {
            # Directory - find source files and test files
            try {
                # Optimized: Filter in foreach loop instead of Where-Object
                $allFiles = Get-ChildItem -Path $resolvedPath -Filter '*.ps1' -Recurse -File -ErrorAction SilentlyContinue
                foreach ($file in $allFiles) {
                    if ($file.Name -notlike '*.tests.ps1') {
                        $sourceFiles.Add($file)
                    }
                }
                $testFilesFound = Get-ChildItem -Path $resolvedPath -Filter '*.tests.ps1' -Recurse -File -ErrorAction SilentlyContinue
                foreach ($testFile in $testFilesFound) {
                    $testFiles.Add($testFile)
                }
            }
            catch {
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "Failed to enumerate files in directory" -OperationName 'coverage.analyze.enumerate-dir' -Context @{
                        directory_path = $resolvedPath
                    } -Code 'DirectoryEnumerationFailed'
                }
                else {
                    Write-Warning "Failed to enumerate files in directory: $resolvedPath - $($_.Exception.Message)"
                }
            }
        }
        elseif ($item -and -not $item.PSIsContainer) {
            # Source file - add it
            $sourceFiles.Add($item)
        }
    }
    else {
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Path not found for coverage analysis" -OperationName 'coverage.analyze.path' -Context @{
                original_path = $p
                resolved_path = $resolvedPath
            } -Code 'PathNotFound'
        }
        else {
            Write-Warning "Path not found: $p (resolved: $resolvedPath)"
        }
    }
}

# If we have source files but no test files, try to match test files to source files
if ($sourceFiles.Count -gt 0 -and $testFiles.Count -eq 0) {
    foreach ($sourceFile in $sourceFiles) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($sourceFile.Name)
        
        # Direct mappings for known source files
        # NOTE: Add mappings incrementally when pattern matching doesn't find all relevant tests.
        # Most source files follow patterns (e.g., ModuleLoading.ps1 → library-module-loading*.tests.ps1).
        $sourceToTestMappings = @{
            'ModuleLoading'        = @('library-module-loading*.tests.ps1', 'library-module-loading-additional*.tests.ps1', 'module-loading-standard*.tests.ps1')
            'FunctionRegistration' = @('library-tool-wrapper*.tests.ps1', 'bootstrap-helper-functions*.tests.ps1', 'bootstrap-idempotency*.tests.ps1', 'bootstrap-performance*.tests.ps1', 'bootstrap-scoping*.tests.ps1')
            'CommandCache'         = @('library-command*.tests.ps1', 'bootstrap-helper-functions*.tests.ps1', 'bootstrap-performance*.tests.ps1')
            'ModulePathCache'      = @('bootstrap-helper-functions*.tests.ps1')
            'CacheKey'             = @('library-cache-key*.tests.ps1')
            'JsonUtilities'        = @('library-json-utilities*.tests.ps1', 'library-json-utilities-extended*.tests.ps1')
            'EnvFile'              = @('library-envfile*.tests.ps1')
            'RequirementsLoader'   = @('library-requirements-loader*.tests.ps1')
        }
        
        $patterns = @()
        if ($sourceToTestMappings.ContainsKey($baseName)) {
            $patterns = $sourceToTestMappings[$baseName]
        }
        else {
            # Fallback to pattern matching
            $patterns = @(
                "*library-$($baseName.ToLower().Replace('Module', 'module').Replace('Loading', 'loading').Replace('Function', 'function').Replace('Registration', 'registration').Replace('Tool', 'tool').Replace('Wrapper', 'wrapper'))*.tests.ps1",
                "*$($baseName.ToLower())*.tests.ps1"
            )
        }
        
        foreach ($pattern in $patterns) {
            try {
                $found = Get-ChildItem -Path $testsRoot -Filter $pattern -Recurse -File -ErrorAction SilentlyContinue
                if ($found) {
                    # Optimized: Use Add() instead of +=
                    foreach ($testFile in $found) {
                        $testFiles.Add($testFile)
                    }
                }
            }
            catch {
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "Failed to find test files with pattern" -OperationName 'coverage.analyze.find-test-pattern' -Context @{
                        pattern = $pattern
                        tests_root = $testsRoot
                        source_file = $sourceFile.Name
                    } -Code 'TestFilePatternSearchFailed'
                }
            }
        }
    }
}

# Remove duplicates
$testFiles = $testFiles | Select-Object -Unique
$sourceFiles = $sourceFiles | Select-Object -Unique

$discoveryDuration = ((Get-Date) - $discoveryStartTime).TotalMilliseconds

# Level 2: Discovery timing and details
if ($debugLevel -ge 2) {
    Write-Verbose "[coverage.analyze] File discovery completed in ${discoveryDuration}ms"
    Write-Verbose "[coverage.analyze] Found $($sourceFiles.Count) source files, $($testFiles.Count) test files"
}

# Level 3: Performance breakdown
if ($debugLevel -ge 3) {
    Write-Host "  [coverage.analyze] Discovery performance - Duration: ${discoveryDuration}ms, Source files: $($sourceFiles.Count), Test files: $($testFiles.Count)" -ForegroundColor DarkGray
}

Write-Host "Analyzing coverage for $($sourceFiles.Count) source file(s)..." -ForegroundColor Cyan
Write-Host "Source files:" -ForegroundColor Cyan
foreach ($file in $sourceFiles) {
    Write-Host "  - $($file.Name)" -ForegroundColor White
}
Write-Host "`nUsing $($testFiles.Count) relevant test file(s)..." -ForegroundColor Cyan
if ($testFiles.Count -gt 0) {
    foreach ($testFile in $testFiles) {
        Write-Host "  - $($testFile.Name)" -ForegroundColor White
    }
}
else {
    Write-Warning "No matching test files found. Coverage may be incomplete."
}

# Validate we have files to analyze
# If we have test files but no source files, we can still run the tests (just without coverage)
if ($testFiles.Count -eq 0 -and $sourceFiles.Count -eq 0) {
    Write-Warning "No source files or test files found to analyze"
    exit 0
}

# Create Pester configuration
$config = New-PesterConfiguration
if ($testFiles.Count -gt 0) {
    $config.Run.Path = $testFiles.FullName
    Write-Host "Running $($testFiles.Count) test file(s)..." -ForegroundColor Cyan
}
else {
    Write-Warning "No test files found. Running all tests (coverage may be inaccurate)."
    $allTestFiles = Get-ChildItem -Path $testsRoot -Filter '*.tests.ps1' -Recurse -File -ErrorAction SilentlyContinue
    $config.Run.Path = $allTestFiles.FullName
}

# Only enable coverage if we have source files to analyze
if ($sourceFiles.Count -gt 0) {
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.Path = $sourceFiles.FullName
}
else {
    Write-Warning "No source files found for coverage analysis. Running tests without coverage."
    $config.CodeCoverage.Enabled = $false
}
$config.Output.Verbosity = 'Minimal'  # Reduce output noise
$config.Run.PassThru = $true

# Level 1: Test execution start
if ($debugLevel -ge 1) {
    Write-Verbose "[coverage.analyze] Preparing Pester configuration"
    Write-Verbose "[coverage.analyze] Coverage enabled: $($config.CodeCoverage.Enabled)"
    if ($config.CodeCoverage.Enabled) {
        Write-Verbose "[coverage.analyze] Coverage paths: $($config.CodeCoverage.Path.Count) file(s)"
    }
}

# Load TestSupport.ps1 to ensure test helper functions are available
# This must be done BEFORE creating the Pester config so functions are available during test discovery
$testSupportPath = Join-Path $testsRoot 'TestSupport.ps1'
if (Test-Path -LiteralPath $testSupportPath) {
    Write-Host "Loading TestSupport.ps1..." -ForegroundColor Cyan
    
    # Level 2: TestSupport loading
    if ($debugLevel -ge 2) {
        Write-Verbose "[coverage.analyze] Loading TestSupport from: $testSupportPath"
    }
    
    . $testSupportPath
    $availableFunctions = Get-Command -Name 'Get-TestRepoRoot', 'Get-TestPath', 'Initialize-TestProfile' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    if ($availableFunctions) {
        Write-Host "TestSupport loaded. Available functions: $($availableFunctions -join ', ')" -ForegroundColor Gray
    }
    else {
        Write-Warning "TestSupport loaded but helper functions not found"
    }
    
    # Ensure functions are available globally for test discovery and execution
    # Some test files rely on these being available without loading TestSupport themselves
    if (Get-Command Get-TestPath -ErrorAction SilentlyContinue) {
        # Function is available, ensure it's in global scope
        if (-not (Get-Command Get-TestPath -Scope Global -ErrorAction SilentlyContinue)) {
            # Copy to global scope if not already there
            $func = Get-Command Get-TestPath -ErrorAction SilentlyContinue
            if ($func) {
                Set-Item -Path "Function:\global:Get-TestPath" -Value $func.ScriptBlock -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
else {
    Write-Warning "TestSupport.ps1 not found at: $testSupportPath. Some tests may fail."
}

# Suppress any interactive prompts during test execution
$env:PS_PROFILE_SUPPRESS_CONFIRMATIONS = '1'
$env:PS_PROFILE_FORCE = '1'

# Run tests with coverage (wrapped to suppress prompts)
Write-Host "`nRunning tests with coverage analysis..." -ForegroundColor Cyan

# Level 1: Test execution start
if ($debugLevel -ge 1) {
    Write-Verbose "[coverage.analyze] Starting Pester test execution with coverage"
}

$originalConfirmPreference = $ConfirmPreference
$testStartTime = Get-Date
try {
    $ConfirmPreference = 'None'
    $global:ConfirmPreference = 'None'
    
    # Ensure TestSupport functions are available in the test execution context
    # Reload if needed to ensure they're in the right scope
    if (-not (Get-Command Get-TestPath -ErrorAction SilentlyContinue)) {
        Write-Warning "TestSupport functions not available. Attempting to reload..."
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
        }
    }
    
    $result = Invoke-Pester -Configuration $config
}
finally {
    # Restore original preference
    $ConfirmPreference = $originalConfirmPreference
    $global:ConfirmPreference = $originalConfirmPreference
}

$testDuration = ((Get-Date) - $testStartTime).TotalMilliseconds

# Level 2: Test execution timing
if ($debugLevel -ge 2) {
    Write-Verbose "[coverage.analyze] Test execution completed in ${testDuration}ms"
    Write-Verbose "[coverage.analyze] Tests: $($result.TotalCount), Passed: $($result.PassedCount), Failed: $($result.FailedCount), Skipped: $($result.SkippedCount)"
}

# Level 3: Performance breakdown
if ($debugLevel -ge 3) {
    $avgTestTime = if ($result.TotalCount -gt 0) { $testDuration / $result.TotalCount } else { 0 }
    Write-Host "  [coverage.analyze] Test performance - Duration: ${testDuration}ms, Avg per test: ${avgTestTime}ms, Total: $($result.TotalCount) tests" -ForegroundColor DarkGray
}

# Display summary
Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "Coverage Analysis Summary" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan

# Check if coverage data exists - Pester 5.x uses CodeCoverage property, not Coverage
$hasCoverage = $false
$coverageObj = $null

# Level 1: Coverage analysis start
if ($debugLevel -ge 1) {
    Write-Verbose "[coverage.analyze] Analyzing coverage results"
}

# Pester 5.x stores coverage in CodeCoverage property
if ($result.CodeCoverage) {
    $coverageObj = $result.CodeCoverage
    $hasCoverage = (
        ($coverageObj.CommandsAnalyzedCount -and $coverageObj.CommandsAnalyzedCount -gt 0) -or
        ($coverageObj.CoveragePercent -and $coverageObj.CoveragePercent -gt 0) -or
        ($coverageObj.CommandsExecutedCount -and $coverageObj.CommandsExecutedCount -gt 0) -or
        ($coverageObj.CoverageReport -and $coverageObj.CoverageReport.Count -gt 0) -or
        ($coverageObj.CommandsMissedCount -and $coverageObj.CommandsMissedCount -ge 0)
    )
    
    # Level 2: Coverage details
    if ($debugLevel -ge 2 -and $hasCoverage) {
        Write-Verbose "[coverage.analyze] Coverage found - Commands analyzed: $($coverageObj.CommandsAnalyzedCount), Executed: $($coverageObj.CommandsExecutedCount), Missed: $($coverageObj.CommandsMissedCount)"
    }
}
# Fallback: Check for Coverage property (older Pester versions or different structure)
elseif ($result.Coverage) {
    $coverageObj = $result.Coverage
    $hasCoverage = (
        ($coverageObj.NumberOfCommandsAnalyzed -and $coverageObj.NumberOfCommandsAnalyzed -gt 0) -or
        ($coverageObj.CoveragePercent -and $coverageObj.CoveragePercent -gt 0) -or
        ($coverageObj.NumberOfCommandsExecuted -and $coverageObj.NumberOfCommandsExecuted -gt 0) -or
        ($coverageObj.CoveredPercent -and $coverageObj.CoveredPercent.Count -gt 0)
    )
}

if ($hasCoverage -and $coverageObj) {
    # Handle Pester 5.x CodeCoverage structure
    $coveragePercent = if ($coverageObj.CoveragePercent) {
        [Math]::Round($coverageObj.CoveragePercent, 2)
    }
    elseif ($coverageObj.CommandsAnalyzedCount -gt 0) {
        [Math]::Round(($coverageObj.CommandsExecutedCount / $coverageObj.CommandsAnalyzedCount) * 100, 2)
    }
    else {
        0
    }
    
    Write-Host "Overall Coverage: $coveragePercent%" -ForegroundColor $(if ($coveragePercent -ge 80) { 'Green' } elseif ($coveragePercent -ge 60) { 'Yellow' } else { 'Red' })
    Write-Host "Commands Analyzed: $($coverageObj.CommandsAnalyzedCount)" -ForegroundColor White
    Write-Host "Commands Executed: $($coverageObj.CommandsExecutedCount)" -ForegroundColor White
    Write-Host "Commands Missed: $($coverageObj.CommandsMissedCount)" -ForegroundColor White
    Write-Host "Files Analyzed: $($coverageObj.FilesAnalyzedCount)" -ForegroundColor White
    
    # Show per-file coverage
    # Pester 5.x CoverageReport is a string, not an array, so we need to calculate per-file coverage
    # from the source files and coverage data
    if ($sourceFiles.Count -gt 0) {
        Write-Host "`nPer-File Coverage:" -ForegroundColor Cyan
        # Optimized: Use List for better performance with Add() instead of +=
        $fileCoverageData = [System.Collections.Generic.List[PSCustomObject]]::new()
        
        foreach ($sourceFile in $sourceFiles) {
            # Calculate coverage for this file
            # Pester 5.x doesn't provide per-file breakdown in a structured way,
            # so we'll use the overall coverage percentage for each file
            # This is a limitation - ideally we'd parse CoverageReport string or use CoverageData
            $fileName = Split-Path -Leaf $sourceFile.FullName
            # Optimized: Use List.Add instead of +=
            $fileCoverageData.Add([PSCustomObject]@{
                    File            = $fileName
                    Path            = $sourceFile.FullName
                    CoveragePercent = $coveragePercent  # Use overall coverage as approximation
                })
        }
        
        # Sort by coverage percentage
        $fileCoverageData = $fileCoverageData | Sort-Object -Property CoveragePercent
        
        foreach ($file in $fileCoverageData) {
            $percent = $file.CoveragePercent
            $color = if ($percent -ge 80) { 'Green' } elseif ($percent -ge 60) { 'Yellow' } else { 'Red' }
            Write-Host "  - $($file.File) : $percent%" -ForegroundColor $color
        }
        
        # Optimized: Single-pass filtering instead of Where-Object
        $lowCoverage = [System.Collections.Generic.List[object]]::new()
        foreach ($file in $fileCoverageData) {
            if ($file.CoveragePercent -lt 80) {
                $lowCoverage.Add($file)
            }
        }
        if ($lowCoverage.Count -gt 0) {
            Write-Host "`nFiles with Coverage < 80%:" -ForegroundColor Yellow
            foreach ($file in $lowCoverage) {
                Write-Host "  - $($file.File) : $([Math]::Round($file.CoveragePercent, 2))%" -ForegroundColor Red
            }
        }
        else {
            Write-Host "`n✅ All files have >= 80% coverage" -ForegroundColor Green
        }
    }
    else {
        Write-Host "`nNote: Per-file coverage details not available (no source files specified)" -ForegroundColor Gray
    }
    
    # Save report
    $resolvedOutputPath = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
        $OutputPath
    }
    else {
        Join-Path $scriptRoot $OutputPath
    }
    
    if (-not (Test-Path $resolvedOutputPath)) {
        New-Item -ItemType Directory -Path $resolvedOutputPath -Force | Out-Null
    }
    
    $reportPath = Join-Path $resolvedOutputPath "coverage-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $coverageObj | ConvertTo-Json -Depth 10 | Set-Content -Path $reportPath
    Write-Host "`nCoverage report saved to: $reportPath" -ForegroundColor Green
}
else {
    # Only show warning if coverage was actually enabled
    if ($config.CodeCoverage.Enabled) {
        Write-Warning "No coverage data generated. Check that source files were found and tests executed successfully."
    }
    else {
        Write-Host "Coverage analysis was not enabled (no source files specified)." -ForegroundColor Yellow
    }
}

Write-Host "`nTest Results: $($result.TotalCount) tests, $($result.PassedCount) passed, $($result.FailedCount) failed" -ForegroundColor $(if ($result.FailedCount -eq 0) { 'Green' } else { 'Yellow' })

if ($result.FailedCount -gt 0) {
    Write-Warning "Some tests failed. Coverage data may be incomplete. Review test failures above."
    Write-Host "Note: Test failures don't prevent coverage analysis, but may affect accuracy." -ForegroundColor Yellow
}

# Exit with appropriate code
$exitCode = 0
if ($result.FailedCount -gt 0 -and -not $result.Coverage) {
    $exitCode = 1
}
elseif ($result.Coverage) {
    # Use the coverage object we already determined
    $calculatedCoverage = if ($coverageObj) {
        if ($coverageObj.CoveragePercent) {
            $coverageObj.CoveragePercent
        }
        elseif ($coverageObj.CommandsAnalyzedCount -gt 0) {
            ($coverageObj.CommandsExecutedCount / $coverageObj.CommandsAnalyzedCount) * 100
        }
        else {
            0
        }
    }
    else {
        0
    }
    
    if ($calculatedCoverage -lt 80) {
        Write-Warning "Coverage is below 80% threshold ($([Math]::Round($calculatedCoverage, 2))%)"
        $exitCode = 1
    }
}

exit $exitCode

return $result

