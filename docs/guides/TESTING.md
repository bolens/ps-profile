# Testing Guide

This guide provides comprehensive information about testing in the PowerShell profile codebase, including how to write, run, and maintain tests.

## Table of Contents

- [Overview](#overview)
- [Test Structure](#test-structure)
- [Writing Tests](#writing-tests)
- [Running Tests](#running-tests)
- [Advanced Features](#advanced-features)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Overview

The project uses **Pester 5+** for testing with a comprehensive test runner that supports:

- **Unit tests** - Fast, isolated tests for individual functions and modules
- **Integration tests** - Tests that verify components work together
- **Performance tests** - Tests that measure and track performance metrics

The test runner (`scripts/utils/code-quality/run-pester.ps1`) provides advanced features including retry logic, performance monitoring, baselining, and detailed reporting.

## Test Structure

### Directory Organization

Tests are organized into three suites with **domain-driven organization** for better maintainability:

```
tests/
├── unit/                                    # Unit tests (isolated, fast)
│   ├── library/                             # Library module tests
│   │   ├── core/                            # Core library modules
│   │   ├── fragment/                        # Fragment management
│   │   ├── path/                            # Path utilities
│   │   ├── file/                            # File utilities
│   │   ├── runtime/                         # Runtime detection
│   │   ├── utilities/                       # Utility modules
│   │   ├── metrics/                         # Metrics modules
│   │   ├── performance/                     # Performance modules
│   │   ├── code-analysis/                   # Code analysis modules
│   │   └── parallel/                        # Parallel execution
│   ├── profile/                             # Profile function tests
│   ├── utilities/                           # Utility function tests
│   ├── validation/                          # Validation script tests
│   └── common/                              # Common/shared tests
│
├── integration/                             # Integration tests
│   ├── bootstrap/                           # Bootstrap function tests
│   ├── conversion/                          # Conversion utilities
│   │   ├── data/                            # Data format conversions
│   │   │   ├── base64/                      # Base64 encoding
│   │   │   ├── binary/                      # Binary formats
│   │   │   ├── columnar/                    # Columnar formats
│   │   │   ├── compression/                 # Compression formats
│   │   │   ├── csv-xml/                     # CSV/XML conversions
│   │   │   ├── database/                    # Database formats
│   │   │   ├── digest/                      # Hash/checksum formats
│   │   │   ├── encoding/                    # Encoding formats
│   │   │   ├── network/                     # Network formats
│   │   │   ├── scientific/                  # Scientific formats
│   │   │   ├── specialized/                 # Specialized formats
│   │   │   ├── structured/                  # Structured formats
│   │   │   ├── text-formats/                # Text formats
│   │   │   ├── time/                        # Time formats
│   │   │   └── units/                      # Unit conversions
│   │   ├── document/                        # Document conversions
│   │   └── media/                          # Media conversions
│   │       ├── audio/                       # Audio formats
│   │       ├── colors/                      # Color conversions
│   │       ├── images/                      # Image formats
│   │       └── video/                       # Video formats
│   ├── filesystem/                         # Filesystem utilities
│   ├── fragments/                           # Fragment management
│   ├── profile/                             # Profile loading
│   ├── tools/                               # Development tools
│   │   ├── containers/                      # Container tools
│   │   └── network/                         # Network utilities
│   ├── system/                             # System utilities
│   ├── terminal/                            # Terminal/prompt tools
│   ├── test-runner/                         # Test runner tests
│   ├── utilities/                           # Utility functions
│   ├── cross-platform/                      # Cross-platform tests
│   └── error-handling/                      # Error handling
│
├── performance/                             # Performance tests
│   ├── performance.tests.ps1
│   └── test-runner-performance.tests.ps1
│
├── TestSupport.ps1                          # Thin loader for test utilities
└── TestSupport/                             # Modular test support utilities
    ├── TestPaths.ps1                        # Path resolution utilities
    ├── TestExecution.ps1                    # Script execution helpers
    ├── TestMocks.ps1                        # Mock initialization
    ├── TestModuleLoading.ps1                # Module loading for tests
    └── TestNpmHelpers.ps1                   # NPM package testing
```

### Test File Naming

- **Unit tests**: `tests/unit/**/*.tests.ps1` (recursive discovery)
- **Integration tests**: `tests/integration/**/*.tests.ps1` (recursive discovery)
- **Performance tests**: `tests/performance/*.tests.ps1`

All test files must end with `.tests.ps1` to be discovered by the test runner. The test runner supports **recursive discovery**, so tests can be organized in subdirectories for better organization.

### TestSupport Path Resolution

All test files use a consistent pattern to resolve the `TestSupport.ps1` path, which works from any subdirectory depth:

```powershell
# Resolve TestSupport.ps1 path (works from any subdirectory depth)
$current = Get-Item $PSScriptRoot
while ($null -ne $current) {
    $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
    if (Test-Path $testSupportPath) {
        . $testSupportPath
        break
    }
    if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
    $current = $current.Parent
}
```

This pattern ensures tests work correctly regardless of their directory depth.

### Test Support Utilities

The `tests/TestSupport.ps1` file is a thin loader that imports modular test utilities from `tests/TestSupport/`. The test support modules provide:

**TestPaths Module** (`TestSupport/TestPaths.ps1`):

- `Get-TestRepoRoot` - Locates the repository root
- `Get-TestPath` - Resolves paths relative to the repository root
- `Get-TestSuitePath` - Gets paths to test suite directories
- `Get-TestSuiteFiles` - Enumerates test files in a suite
- `New-TestTempDirectory` - Creates temporary directories for tests

**TestExecution Module** (`TestSupport/TestExecution.ps1`):

- `Invoke-TestPwshScript` - Executes scripts in isolated PowerShell processes
- `Get-PerformanceThreshold` - Resolves performance thresholds from environment variables

**TestModuleLoading Module** (`TestSupport/TestModuleLoading.ps1`):

The TestModuleLoading module provides utilities for loading profile modules in test environments. It's organized into several categories:

**Core Functions:**

- `Import-TestModule` - Loads a test module and promotes its functions to global scope
- `Import-ModuleGroup` - Generic helper that loads multiple modules from a directory using configuration

**Module Loading Functions:**

- `Ensure-ConversionModulesLoaded` - Ensures conversion modules are loaded for tests (Data, Documents, Media, or All)
- `Ensure-DevToolsModulesLoaded` - Ensures dev-tools modules are loaded for tests

**Helper Functions (Internal):**

- `Import-ConversionHelpers` - Loads conversion module helpers
- `Import-DataConversionModules` - Loads data conversion modules (core, structured, binary, columnar, scientific)
- `Import-DocumentConversionModules` - Loads document conversion modules
- `Import-MediaConversionModules` - Loads media conversion modules (basic and color)
- `Import-DevToolsModules` - Loads dev-tools modules (encoding, crypto, format, QR code, data)

**Configuration Functions:**

- `Get-ConversionHelpersConfig` - Returns helper module configuration
- `Get-DataCoreModulesConfig` - Returns data core modules configuration
- `Get-DataEncodingSubModulesConfig` - Returns encoding sub-modules configuration
- `Get-DataStructuredModulesConfig` - Returns structured data modules configuration
- `Get-DataBinaryModulesConfig` - Returns binary modules configuration
- `Get-DataColumnarModulesConfig` - Returns columnar modules configuration
- `Get-DataScientificModulesConfig` - Returns scientific modules configuration
- `Get-DocumentModulesConfig` - Returns document modules configuration
- `Get-MediaModulesConfig` - Returns media modules configuration
- `Get-MediaColorModulesConfig` - Returns color conversion modules configuration
- `Get-DevToolsEncodingModulesConfig` - Returns dev-tools encoding modules configuration
- `Get-DevToolsCryptoModulesConfig` - Returns dev-tools crypto modules configuration
- `Get-DevToolsFormatModulesConfig` - Returns dev-tools format modules configuration
- `Get-DevToolsQrCodeModulesConfig` - Returns dev-tools QR code modules configuration
- `Get-DevToolsDataModulesConfig` - Returns dev-tools data modules configuration

The module uses a structured approach where module configurations are separated from loading logic, making it easier to maintain and extend. Configuration functions return hashtables (for modules with init functions) or arrays (for modules without init functions).

**TestMocks Module** (`TestSupport/TestMocks.ps1`):

- `Initialize-TestMocks` - Sets up mock functions for testing
- `Remove-TestArtifacts` - Cleans up test artifacts

**TestNpmHelpers Module** (`TestSupport/TestNpmHelpers.ps1`):

- `Test-NpmPackageAvailable` - Checks if an NPM package is available

## Writing Tests

### Basic Test Structure

All tests follow the Pester 5 structure with `Describe`, `Context`, and `It` blocks:

```powershell
<#
tests/unit/my-module.tests.ps1

.SYNOPSIS
    Tests for MyModule functionality.
#>

BeforeAll {
    # Import test support
    . $PSScriptRoot/../TestSupport.ps1

    # Import the module or code to test
    $modulePath = Get-TestPath -RelativePath 'scripts/lib/MyModule.psm1'
    Import-Module $modulePath -Force
}

AfterAll {
    # Cleanup if needed
}

Describe 'MyModule' {
    Context 'FunctionName' {
        It 'should return expected value' {
            $result = FunctionName -Parameter 'value'
            $result | Should -Be 'expected'
        }

        It 'should handle edge cases' {
            { FunctionName -Parameter $null } | Should -Throw
        }
    }
}
```

### Unit Tests

Unit tests should:

- Test individual functions in isolation
- Use mocks for external dependencies
- Be fast (typically < 1 second per test)
- Not have side effects

**Example:**

```powershell
BeforeAll {
    # Resolve TestSupport.ps1 path (works from any subdirectory depth)
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }

    $modulePath = Get-TestPath -RelativePath 'scripts/lib/path/PathResolution.psm1'
    Import-Module $modulePath -Force
}

Describe 'Get-RepoRoot' {
    Context 'Path Resolution' {
        It 'should find repository root from subdirectory' {
            $testPath = Join-Path (Get-TestRepoRoot) 'scripts/utils'
            $result = Get-RepoRoot -ScriptPath $testPath
            $result | Should -Be (Get-TestRepoRoot)
        }

        It 'should throw when repository root not found' {
            $tempDir = New-TestTempDirectory
            { Get-RepoRoot -ScriptPath $tempDir } | Should -Throw
            Remove-Item $tempDir -Recurse -Force
        }
    }
}
```

### Integration Tests

Integration tests should:

- Test multiple components working together
- Use real file system operations when appropriate
- Test profile fragment loading and interactions
- Verify end-to-end workflows

**Example:**

```powershell
BeforeAll {
    # Resolve TestSupport.ps1 path (works from any subdirectory depth)
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }

    $script:ProfilePath = Get-TestPath -RelativePath 'Microsoft.PowerShell_profile.ps1'
}

Describe 'Profile Loading Integration' {
    Context 'Profile Loading' {
        It 'should load successfully in isolated process' {
            $testScript = @"
. '$($script:ProfilePath -replace "'", "''")'
Write-Output 'PROFILE_LOADED_SUCCESSFULLY'
"@
            $result = Invoke-TestPwshScript -ScriptContent $testScript
            $result | Should -Match 'PROFILE_LOADED_SUCCESSFULLY'
        }

        It 'should not pollute global scope excessively' {
            $before = (Get-Variable -Scope Global).Count
            . $script:ProfilePath
            $after = (Get-Variable -Scope Global).Count
            $increase = $after - $before
            $increase | Should -BeLessThan 50
        }
    }
}
```

### Performance Tests

Performance tests should:

- Measure execution time, memory, or CPU usage
- Use performance thresholds (via environment variables or constants)
- Compare against baselines when available
- Be tagged appropriately for filtering

**Example:**

```powershell
BeforeAll {
    # Resolve TestSupport.ps1 path (works from any subdirectory depth)
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }

    $script:MaxLoadTime = Get-PerformanceThreshold -EnvironmentVariable 'PS_PROFILE_MAX_LOAD_MS' -Default 6000
}

Describe 'Profile Performance' {
    Context 'Startup Time' {
        It 'should load within acceptable time' {
            $profilePath = Get-TestPath -RelativePath 'Microsoft.PowerShell_profile.ps1'

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            . $profilePath
            $stopwatch.Stop()

            $loadTime = $stopwatch.ElapsedMilliseconds
            $loadTime | Should -BeLessThan $script:MaxLoadTime
        }
    }
}
```

### Using Mocks

Use Pester mocks to isolate units under test:

```powershell
Describe 'Function with External Dependency' {
    It 'should handle external command failure' {
        Mock -CommandName 'Get-Content' -MockWith {
            throw "File not found"
        }

        { MyFunction -Path 'test.txt' } | Should -Throw
    }

    It 'should process file content correctly' {
        Mock -CommandName 'Get-Content' -MockWith {
            return @('line1', 'line2', 'line3')
        }

        $result = MyFunction -Path 'test.txt'
        $result.Count | Should -Be 3
    }
}
```

### Test Tags

Use tags to organize and filter tests:

```powershell
Describe 'Slow Operations' -Tag 'Slow' {
    It 'should complete long-running task' {
        # Test implementation
    }
}

Describe 'Network Operations' -Tag 'Network', 'Integration' {
    It 'should handle network requests' {
        # Test implementation
    }
}
```

Common tags:

- `Slow` - Tests that take longer to run
- `Network` - Tests that require network access
- `Integration` - Integration tests
- `Unit` - Unit tests
- `Performance` - Performance tests

## Running Tests

### Basic Test Execution

Run all tests:

```powershell
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1
```

Run specific test suites:

```powershell
# Unit tests only
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Suite Unit

# Integration tests only
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Suite Integration

# Performance tests only
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Suite Performance
```

### Running Specific Tests

Run a specific test file:

```powershell
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TestFile tests/unit/path-resolution.tests.ps1
```

Run tests by name (supports wildcards):

```powershell
# Run tests with names containing "Get-RepoRoot"
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TestName "*Get-RepoRoot*"

# Run multiple test patterns
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TestName "*Backup* or *Restore*"
```

### Filtering by Tags

Include or exclude tests by tags:

```powershell
# Run only slow tests
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -IncludeTag 'Slow'

# Exclude network tests
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -ExcludeTag 'Network'

# Multiple tags
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -IncludeTag 'Unit', 'Fast' -ExcludeTag 'Slow'
```

### Output Formats

Control test output verbosity:

```powershell
# Normal output (default)
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -OutputFormat Normal

# Detailed output (shows individual test results)
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -OutputFormat Detailed

# Minimal output (only failures and summary)
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -OutputFormat Minimal

# Quiet mode (minimal output)
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Quiet
```

### Code Coverage

Generate code coverage reports:

```powershell
# Basic coverage
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Coverage

# Coverage with minimum threshold (fails if below 80%)
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Coverage -MinimumCoverage 80

# Coverage with specific output format
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Coverage -CodeCoverageOutputFormat JaCoCo
```

Available coverage formats:

- `JaCoCo` (default) - Java Code Coverage format
- `CoverageGutters` - VS Code Coverage Gutters format
- `Cobertura` - Cobertura XML format

### Parallel Execution

Run tests in parallel for faster execution:

```powershell
# Use all available CPU cores
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Parallel

# Use specific number of threads
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Parallel 4
```

### Using Taskfile Shortcuts

The project includes convenient task shortcuts:

```powershell
# Run all tests
task test

# Run specific suites
task test-unit
task test-integration
task test-performance

# Run with coverage
task test-coverage
```

## Advanced Features

### Retry Logic

Handle flaky tests with automatic retries:

```powershell
# Retry failed tests up to 3 times
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -MaxRetries 3 -RetryOnFailure

# Use exponential backoff (delays: 1s, 2s, 4s, ...)
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -MaxRetries 3 -ExponentialBackoff

# Custom retry delay
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -MaxRetries 3 -RetryDelaySeconds 2
```

### Performance Monitoring

Track execution time, memory, and CPU usage:

```powershell
# Track execution time
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TrackPerformance

# Include memory tracking
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TrackPerformance -TrackMemory

# Include CPU tracking
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TrackPerformance -TrackCPU

# All metrics
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TrackPerformance -TrackMemory -TrackCPU
```

### Performance Baselining

Generate and compare performance baselines:

```powershell
# Generate a baseline
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -GenerateBaseline -BaselinePath "baseline.json" -TrackPerformance

# Compare against baseline (warns if >5% slower)
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -CompareBaseline -BaselinePath "baseline.json" -BaselineThreshold 5

# Compare with custom threshold (10%)
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -CompareBaseline -BaselineThreshold 10 -TrackPerformance
```

### Environment Health Checks

Validate the test environment before running:

```powershell
# Run health checks
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -HealthCheck

# Fail if health checks don't pass
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -HealthCheck -StrictMode
```

Health checks verify:

- Required modules are installed
- Test paths exist
- External tools are available (if needed)

### Test Analysis and Reporting

Generate detailed analysis and custom reports:

```powershell
# Generate analysis
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -AnalyzeResults

# Generate HTML report
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -AnalyzeResults -ReportFormat HTML -ReportPath "test-report.html"

# Generate JSON report
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -AnalyzeResults -ReportFormat JSON -ReportPath "test-report.json"

# Generate Markdown report with details
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -AnalyzeResults -ReportFormat Markdown -ReportPath "test-report.md" -IncludeReportDetails
```

### Test Results Export

Save test results to files:

```powershell
# Save results in NUnit XML format
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -OutputPath "results.xml"

# Save results in JSON format
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -OutputPath "results.json"

# Custom result directory
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TestResultPath "ci/results"
```

### CI Mode

Optimized settings for continuous integration:

```powershell
# CI mode (sets Normal output, enables coverage, treats warnings as failures)
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -CI
```

### Dry Run

Preview what tests would run without executing:

```powershell
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -DryRun
```

### Randomization

Run tests in random order to detect order dependencies:

```powershell
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Randomize
```

### Repeating Tests

Run tests multiple times to detect flakiness:

```powershell
# Run tests 3 times
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Repeat 3
```

### Timeouts

Set timeouts for test execution:

```powershell
# Overall timeout (5 minutes)
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Timeout 300

# Per-test timeout (30 seconds)
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TestTimeoutSeconds 30
```

### Fail Fast

Stop execution on first failure:

```powershell
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -FailFast
```

### Enhanced Test Runner Features

The test runner includes several powerful features for improved workflow and productivity:

#### List Tests Mode

View available tests without running them:

```powershell
# List all tests
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -ListTests

# List with detailed structure (shows Describe/Context blocks)
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -ListTests -ShowDetails

# List tests for specific suite
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Suite Unit -ListTests
```

#### Run Only Failed Tests

Re-run only tests that failed in the last run:

```powershell
# Re-run failed tests from last execution
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -FailedOnly
```

**Note:** Requires a previous test run with saved results (uses `-TestResultPath` or default location).

#### Git Integration

Run tests for changed files automatically:

```powershell
# Run tests for files changed in working directory
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -ChangedFiles

# Include untracked files
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -ChangedFiles -IncludeUntracked

# Run tests for files changed since a branch/commit
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -ChangedSince main
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -ChangedSince HEAD~5
```

The test runner automatically maps changed source files to their corresponding test files.

#### Test File Pattern Filtering

Filter test files by name pattern:

```powershell
# Run only integration test files
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TestFilePattern "*integration*"

# Run only unit test files
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TestFilePattern "*unit*"

# Combine with suite selection
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Suite Integration -TestFilePattern "*profile*"
```

#### Configuration Files

Save and load test runner configurations:

```powershell
# Save current configuration
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Coverage -Parallel -SaveConfig my-config.json

# Load and use saved configuration
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -ConfigFile my-config.json

# Command-line parameters override config file values
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -ConfigFile my-config.json -Suite Unit
```

Configuration files are JSON format and can contain any test runner parameters.

#### Watch Mode

Automatically re-run tests when files change:

```powershell
# Watch for changes and auto-rerun tests
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Watch

# Custom debounce delay (default: 1 second)
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Watch -WatchDebounceSeconds 2

# Watch with summary statistics
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Watch -ShowSummaryStats
```

Press `Ctrl+C` to stop watching. Watch mode monitors test files and source files for changes.

#### Enhanced Summary Statistics

View detailed test statistics:

```powershell
# Show enhanced summary with slowest tests and failure patterns
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -ShowSummaryStats

# Combine with performance tracking
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -ShowSummaryStats -TrackPerformance
```

Summary statistics include:

- Slowest tests (top 5 by default)
- Common failure patterns
- Performance metrics (if tracking enabled)

#### Interactive Test Selection

Select tests interactively from a menu:

```powershell
# Interactive mode - select tests from menu
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Interactive
```

Interactive mode provides:

- Menu of available test files
- Selection by file number (comma-separated)
- Pattern filtering (`filter <pattern>`)
- Select all option (`all`)

#### Multiple Test Files

Run multiple test files at once:

```powershell
# Multiple files using -TestFile
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TestFile file1.tests.ps1, file2.tests.ps1

# Multiple files using -Path alias
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Path file1.tests.ps1, file2.tests.ps1

# Wildcards supported
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TestFile tests/unit/*.tests.ps1
```

#### Enhanced Exit Codes

The test runner now provides granular exit codes:

- `0` - Success (all tests passed)
- `1` - Validation failure
- `2` - Setup error
- `3` - Other runtime error
- `4` - Test failure (at least one test failed)
- `5` - Test timeout
- `6` - Coverage failure (below threshold)
- `7` - No tests found
- `8` - Watch mode canceled

Use exit codes in CI/CD pipelines for conditional logic:

```powershell
# In CI script
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -CI
$exitCode = $LASTEXITCODE

if ($exitCode -eq 4) {
    Write-Host "Tests failed - blocking merge"
    exit 1
}
elseif ($exitCode -eq 6) {
    Write-Host "Coverage below threshold - warning only"
}
```

## Best Practices

### Test Organization

1. **Domain-driven organization** - Tests are organized by feature/domain, not just test type
2. **One test file per feature/component** - Keep tests focused and organized (target: 100-200 lines per file)
3. **Use descriptive test names** - Test names should clearly describe what they verify
4. **Group related tests** - Use `Context` blocks to organize related tests
5. **Keep tests independent** - Tests should not depend on execution order
6. **Logical grouping** - Related tests live together in the same directory

### Test Naming

Use clear, descriptive names:

```powershell
# Good
It 'should return repository root when called from subdirectory'
It 'should throw error when repository root not found'
It 'should handle null input gracefully'

# Bad
It 'test1'
It 'works'
It 'should work'
```

### Test Isolation

- Each test should be independent
- Use `BeforeAll` and `AfterAll` for setup/teardown
- Clean up temporary files and resources
- Don't rely on global state

### Mocking Guidelines

- Mock external dependencies (file system, network, etc.)
- Don't mock the code under test
- Use mocks to control behavior, not just to avoid side effects
- Verify mock calls when behavior matters

### Performance Test Guidelines

- Use environment variables for thresholds when possible
- Compare against baselines for regression detection
- Tag performance tests appropriately
- Keep performance tests separate from functional tests

### Error Handling Patterns

All tests should include comprehensive error handling with JSON-formatted error context:

#### BeforeAll Error Handling

Wrap initialization in try-catch blocks:

```powershell
BeforeAll {
    try {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap
    }
    catch {
        $errorDetails = @{
            Message  = $_.Exception.Message
            Type     = $_.Exception.GetType().FullName
            Location = $_.InvocationInfo.ScriptLineNumber
            Category = 'BeforeAll'
        }
        Write-Error "Failed to initialize tests in BeforeAll: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Stop
        throw
    }
}
```

#### Test-Level Error Handling

Wrap test logic in try-catch blocks with cleanup:

```powershell
It 'Tests conversion functionality' {
    $tempFile = $null
    $outputFile = $null
    try {
        $tempFile = Join-Path $TestDrive 'test.txt'
        Set-Content -Path $tempFile -Value 'test content'

        { Convert-File -InputPath $tempFile -OutputPath $outputFile } | Should -Not -Throw

        if ($outputFile -and -not [string]::IsNullOrWhiteSpace($outputFile) -and (Test-Path -LiteralPath $outputFile)) {
            $outputFile | Should -Exist
        }
    }
    catch {
        $errorDetails = @{
            Message      = $_.Exception.Message
            Type         = $_.Exception.GetType().FullName
            Location     = $_.InvocationInfo.ScriptLineNumber
            Category     = 'Conversion'
            TestFile     = $tempFile
            OutputFile   = $outputFile
        }
        Write-Error "Conversion test failed: $($errorDetails | ConvertTo-Json -Compress)" -ErrorAction Continue
        throw
    }
    finally {
        # Cleanup if needed
        if ($tempFile -and (Test-Path -LiteralPath $tempFile)) {
            Remove-Item -Path $tempFile -ErrorAction SilentlyContinue
        }
    }
}
```

#### Error Testing

Test both success and failure paths:

```powershell
Describe 'Error Handling' {
    It 'should handle valid input' {
        { MyFunction -Input 'valid' } | Should -Not -Throw
    }

    It 'should throw on invalid input' {
        { MyFunction -Input $null } | Should -Throw
    }

    It 'should throw specific error type' {
        { MyFunction -Input 'invalid' } | Should -Throw -ExceptionType 'ArgumentException'
    }
}
```

### Tool Detection Patterns

Use the tool detection framework for graceful skipping when optional tools are missing:

#### Using Test-ToolAvailable

```powershell
It 'Tests docker functionality' {
    $docker = Test-ToolAvailable -ToolName 'docker' -InstallCommand 'scoop install docker' -Silent
    if (-not $docker.Available) {
        $skipMessage = "docker not available"
        if ($docker.InstallCommand) {
            $skipMessage += ". Install with: $($docker.InstallCommand)"
        }
        Set-ItResult -Skipped -Because $skipMessage
        return
    }

    # Test docker functionality
    docker --version | Should -Not -BeNullOrEmpty
}
```

#### Using Mock-CommandAvailabilityPester

For tests that need to verify behavior when tools are unavailable:

```powershell
It 'Tests function when tool is unavailable' {
    Mock-CommandAvailabilityPester -CommandName 'docker' -Available $false -Scope It

    # Test that function handles missing tool gracefully
    { Get-DockerInfo } | Should -Not -Throw
}
```

#### Package Detection

For Python, NPM, and Scoop packages:

```powershell
It 'Tests Python package functionality' {
    if (-not (Test-PythonPackageAvailable -PackageName 'pandas')) {
        Set-ItResult -Skipped -Because "pandas package not available. Install with: pip install pandas"
        return
    }

    # Test pandas functionality
    # ...
}

It 'Tests NPM package functionality' {
    if (-not (Test-NpmPackageAvailable -PackageName 'superjson')) {
        Set-ItResult -Skipped -Because "superjson package not available. Install with: npm install -g superjson"
        return
    }

    # Test superjson functionality
    # ...
}
```

### Test-Path Safety Patterns

Always check for null/empty paths before calling `Test-Path`:

#### Safe Test-Path Pattern

```powershell
# ✅ CORRECT - Always check for null/empty before Test-Path
if ($path -and -not [string]::IsNullOrWhiteSpace($path) -and (Test-Path -LiteralPath $path)) {
    # Use the path
}

# ❌ WRONG - Can cause PowerShell prompts
if (Test-Path $path) {
    # Use the path
}
```

#### Using Test-SafePath (when available)

```powershell
# Use Test-SafePath wrapper for additional safety
if (Test-SafePath -LiteralPath $path) {
    # Use the path
}
```

#### Path Validation in Functions

```powershell
function Test-MyFunction {
    param([string]$InputPath)

    # Validate path parameter
    if ([string]::IsNullOrWhiteSpace($InputPath)) {
        throw "InputPath cannot be null or empty"
    }

    # Check path exists
    if (-not (Test-Path -LiteralPath $InputPath)) {
        throw "InputPath does not exist: $InputPath"
    }

    # Use the path
}
```

### Test Data

- Use realistic test data
- Test edge cases (null, empty, very long, etc.)
- Use `New-TestTempDirectory` for file system tests
- Clean up test data in `AfterAll`
- Always use `$TestDrive` for temporary files (automatically cleaned up)

### Documentation Standards

All test files should include:

#### File Header

```powershell
<#
.SYNOPSIS
    Integration tests for [feature/component name].

.DESCRIPTION
    This test suite validates [what is being tested].

.NOTES
    Tests cover [specific areas covered].
#>
```

#### Function Documentation

For test helper functions:

```powershell
function Test-MyHelper {
    <#
    .SYNOPSIS
        Brief description.

    .DESCRIPTION
        Detailed description.

    .PARAMETER ParameterName
        Parameter description.

    .EXAMPLE
        Test-MyHelper -ParameterName 'value'

    .OUTPUTS
        System.Boolean
    #>
    # Function body
}
```

### Test Organization Guidelines

1. **Group by feature** - Tests for the same feature should be in the same file
2. **Use Context blocks** - Organize related tests within a Describe block
3. **Logical ordering** - Order tests from simple to complex
4. **Consistent naming** - Use consistent naming patterns across test files
5. **One assertion per test** - Each test should verify one thing (when possible)

### Integration Test Guidelines

- Test real interactions between components
- Use isolated processes (`Invoke-TestPwshScript`) when needed
- Verify end-to-end workflows
- Test error recovery and edge cases
- Use `Initialize-TestProfile` for profile-dependent tests
- Mock external tools to prevent hangs during test execution
- Use `Set-ItResult -Skipped` with clear messages for missing dependencies

### Naming Conventions

#### Test File Names

**Unit Tests (`tests/unit/`):**

- Use category prefixes for consistency:
  - `library-*` - Tests for `scripts/lib/` modules (e.g., `library-command.tests.ps1`)
  - `profile-*` - Tests for `profile.d/` fragments (e.g., `profile-security-tools.tests.ps1`)
  - `utility-*` - Tests for utility scripts (e.g., `utility-docs-generation.tests.ps1`)
  - `validation-*` - Tests for validation scripts (e.g., `validation-idempotency.tests.ps1`)
  - `test-runner-*` - Tests for test runner modules/scripts (e.g., `test-runner-run-pester.tests.ps1`)
  - `test-support-*` - Tests for test support modules (e.g., `test-support.tests.ps1`)
- Use kebab-case: `library-command.tests.ps1`
- Match the feature/component being tested

**Integration Tests (`tests/integration/`):**

- Use descriptive names that match the feature/component
- Simplify names where folder context makes prefixes redundant (e.g., `utilities-*.tests.ps1` in `system/` folder instead of `system-utilities-*.tests.ps1`)
- Use kebab-case: `fragment-loading.tests.ps1`

#### Test Names

- Use descriptive, action-oriented names
- Start with what is being tested
- Include expected behavior

```powershell
# Good
It 'ConvertTo-JsonFromYaml converts valid YAML to JSON'
It 'ConvertTo-JsonFromYaml handles missing input file gracefully'
It 'ConvertTo-JsonFromYaml throws error for invalid YAML syntax'

# Bad
It 'test1'
It 'works'
It 'conversion test'
```

## Troubleshooting

### Tests Not Discovered

If tests aren't being discovered:

1. **Check file naming** - Files must end with `.tests.ps1`
2. **Check file location** - Files must be in `tests/unit/`, `tests/integration/`, or `tests/performance/` (or subdirectories - recursive discovery is supported)
3. **Check syntax** - Files must have valid PowerShell syntax
4. **Run with verbose output** - Use `-Verbose` to see discovery details
5. **Check TestSupport path** - Ensure the TestSupport path resolution pattern is correct for your directory depth

```powershell
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Verbose
```

### Test Failures

If tests fail:

1. **Run tests individually** - Isolate the failing test
2. **Check test output** - Use `-OutputFormat Detailed` for more information
3. **Check dependencies** - Ensure required modules are installed
4. **Check environment** - Run health checks with `-HealthCheck`

### Performance Test Failures

If performance tests fail:

1. **Check thresholds** - Verify environment variables are set correctly
2. **Check baseline** - Ensure baseline exists if using `-CompareBaseline`
3. **Check system load** - High system load can affect performance tests
4. **Review recent changes** - Check if recent changes affected performance

### Module Import Errors

If module imports fail:

1. **Check module paths** - Use `Get-TestPath` for path resolution
2. **Check module dependencies** - Ensure all dependencies are available
3. **Check import order** - Import dependencies before dependent modules
4. **Use `-Force`** - Force reload modules if needed

### Flaky Tests

If tests are flaky:

1. **Use retry logic** - Enable `-MaxRetries` for known flaky tests
2. **Add delays** - Use `Start-Sleep` if timing is an issue
3. **Check for race conditions** - Ensure tests are properly isolated
4. **Review test dependencies** - Check for external dependencies that might be unreliable

### Coverage Issues

If coverage is lower than expected:

1. **Check coverage paths** - Ensure code paths are being tested
2. **Review test scope** - Ensure tests cover all branches
3. **Check excluded paths** - Review coverage exclusions
4. **Add missing tests** - Write tests for uncovered code paths

## Additional Resources

- [Pester Documentation](https://pester.dev/docs/quick-start)
- [AGENTS.md](../../AGENTS.md) - AI assistant guidelines
- [CONTRIBUTING.md](../../CONTRIBUTING.md) - Contribution guidelines
- [docs/guides/DEVELOPMENT.md](DEVELOPMENT.md) - Development guide
- [docs/guides/TEST_REFACTORING_PLAN.md](TEST_REFACTORING_PLAN.md) - Test refactoring plan (completed)
- [docs/guides/TEST_REFACTORING_PROGRESS.md](TEST_REFACTORING_PROGRESS.md) - Test refactoring progress report

## Quick Reference

### Common Commands

```powershell
# Run all tests
task test

# Run unit tests
task test-unit

# Run with coverage
task test-coverage

# Run specific test file
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TestFile tests/unit/my-tests.tests.ps1

# Run with retry and performance tracking
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -MaxRetries 3 -TrackPerformance

# Generate HTML report
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -AnalyzeResults -ReportFormat HTML -ReportPath "report.html"
```

### Test File Template

```powershell
<#
tests/unit/my-module.tests.ps1

.SYNOPSIS
    Tests for MyModule functionality.
#>

BeforeAll {
    # Resolve TestSupport.ps1 path (works from any subdirectory depth)
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }

    # Import module to test
    $modulePath = Get-TestPath -RelativePath 'scripts/lib/MyModule.psm1'
    Import-Module $modulePath -Force
}

AfterAll {
    # Cleanup if needed
}

Describe 'MyModule' {
    Context 'FunctionName' {
        It 'should return expected value' {
            $result = FunctionName -Parameter 'value'
            $result | Should -Be 'expected'
        }
    }
}
```
