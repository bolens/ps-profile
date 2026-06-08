# Testing Guide

This guide provides comprehensive information about testing in the PowerShell profile codebase, including how to write, run, and maintain tests.

## Table of Contents

- [Overview](#overview)
- [Test Structure](#test-structure)
- [Writing Tests](#writing-tests)
- [Running Tests](#running-tests)
- [Batch Runners](#batch-runners)
- [Coverage Analysis](#coverage-analysis)
- [Advanced Features](#advanced-features)
- [Exit Codes](#exit-codes)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [Related Testing Documentation](#related-testing-documentation)

## Overview

The project uses **Pester 5+** for testing with a comprehensive test runner that supports:

- **Unit tests** - Fast, isolated tests for individual functions and modules
- **Integration tests** - Tests that verify components work together
- **Performance tests** - Tests that measure and track performance metrics

The test runner (`scripts/utils/code-quality/run-pester.ps1`) provides advanced features including retry logic, performance monitoring, baselining, and detailed reporting.

> **Start here.** This is the canonical testing guide. For code examples see [Testing Patterns](../examples/TESTING_PATTERNS.md); for stubs see [Test Stub Guide](TEST_VERIFICATION_MOCKING_GUIDE.md); for coverage workflows see [Coverage Verification](VERIFY_COVERAGE.md). Full index: [Related Testing Documentation](#related-testing-documentation).

## Test Structure

### Directory Organization

Tests are organized into three suites with **domain-driven organization** for better maintainability:

```
tests/
├── unit/                                    # Unit tests (flat directory; prefix-based names)
│   ├── library-*.tests.ps1                # scripts/lib/ modules (and hybrid lib + profile.d)
│   ├── profile-*.tests.ps1                # profile.d/ fragments, bootstrap helpers
│   ├── utility-*.tests.ps1                # scripts/utils/ (includes utility-debug-*)
│   ├── validation-*.tests.ps1             # scripts/checks/ and validation scripts
│   ├── test-runner-*.tests.ps1            # Test runner modules and scripts
│   └── test-support*.tests.ps1            # TestSupport modules (test-support.tests.ps1 umbrella)
│
├── integration/                             # Integration tests (domain subdirectories)
│   ├── bootstrap/                           # Bootstrap function tests
│   ├── cloud-provider/                      # Cloud provider base/helpers
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
│   │   │   ├── error-handling/              # Conversion error paths
│   │   │   ├── network/                     # Network formats
│   │   │   ├── scientific/                  # Scientific formats
│   │   │   ├── specialized/                 # Specialized formats
│   │   │   ├── structured/                  # Structured formats
│   │   │   ├── text-formats/                # Text formats
│   │   │   ├── time/                        # Time formats
│   │   │   └── units/                       # Unit conversions
│   │   ├── document/                        # Document conversions
│   │   └── media/                           # Media conversions
│   │       ├── audio/                       # Audio formats
│   │       ├── colors/                      # Color conversions
│   │       ├── images/                      # Image formats
│   │       └── video/                       # Video formats
│   ├── filesystem/                          # Filesystem utilities
│   ├── fragments/                           # Fragment management
│   ├── profile/                             # Profile loading and structure
│   ├── tools/                               # Development tools
│   │   ├── containers/                      # Container tools
│   │   └── network/                         # Network utilities
│   ├── system/                              # System utilities
│   ├── terminal/                            # Terminal/prompt tools
│   ├── test-runner/                         # Test runner tests
│   ├── utilities/                           # Utility functions
│   ├── validation/                          # Validation pipeline integration
│   ├── cross-platform/                      # Cross-platform tests
│   └── error-handling/                      # Error handling standards
│
├── performance/                             # Performance tests (flat directory only)
│   └── *-performance.tests.ps1              # e.g. beads-performance.tests.ps1
│
├── TestSupport.ps1                          # Thin loader for test utilities
└── TestSupport/                             # Modular test support utilities
    ├── TestPaths.ps1                        # Path resolution utilities
    ├── TestExecution.ps1                    # Script execution helpers
    ├── TestMocks.ps1                        # Mock initialization
    ├── TestModuleLoading.ps1                # Module loading for tests
    └── TestNpmHelpers.ps1                   # NPM package testing
```

> **Unit layout:** Unit tests live in a **flat** `tests/unit/` directory. Category prefixes (`library-`, `profile-`, etc.) encode the target area — not subfolders. Use `run-unit-batch.ps1 -Filter profile-` to run subsets.

> **Integration layout:** Prefer **short file names** inside domain folders. The folder provides context, so drop redundant domain prefixes (e.g. `integration/bootstrap/helper-functions.tests.ps1`, not `bootstrap-helper-functions.tests.ps1`).

### Test File Naming

- **Unit tests**: `tests/unit/*.tests.ps1` (flat directory; prefix indicates target)
- **Integration tests**: `tests/integration/**/*.tests.ps1` (recursive discovery)
- **Performance tests**: `tests/performance/*.tests.ps1` (flat directory only)

All test files must end with `.tests.ps1` to be discovered by the test runner. Integration and performance suites support path-based filtering; unit tests are filtered by filename prefix (e.g. `-Filter profile-` in `run-unit-batch.ps1`).

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
- `Remove-TestArtifacts` - Cleans registered paths and known repo-root spillover after each test
- `Clear-TestRepoRootSpillover` - Removes transient files accidentally created in the repository root

**TestPaths Module** (`TestSupport/TestPaths.ps1`):

- `Get-TestDataPath` / `Get-TestArtifactsPath` - Canonical storage under `tests/test-data` and `tests/test-artifacts`
- `New-TestTempDirectory` / `New-TestTempFile` - Creates transient paths and registers them for cleanup
- `Get-TestArtifactPath` - Single named file under `tests/test-data` (use instead of bare filenames like `backup.dump`)
- `Register-TestCleanupPath` - Registers a path for `Remove-TestArtifacts`

**TestNpmHelpers Module** (`TestSupport/TestNpmHelpers.ps1`):

- `Test-NpmPackageAvailable` - Checks if an NPM package is available

## Writing Tests

For copy-paste examples and a test checklist, see [Testing Patterns](../examples/TESTING_PATTERNS.md). For stubbing external commands and environment state, see [Test Stub Guide](TEST_VERIFICATION_MOCKING_GUIDE.md).

### Basic Test Structure

All tests follow the Pester 5 structure with `Describe`, `Context`, and `It` blocks:

```powershell
<#
tests/unit/my-module.tests.ps1

.SYNOPSIS
    Tests for MyModule functionality.
#>

BeforeAll {
    # Import test support from a Pester hook (not at file top level)
    . $PSScriptRoot/../TestSupport.ps1

    # Import the module or code to test
    $modulePath = Get-TestPath -RelativePath 'scripts/lib/MyModule.psm1'
    Import-Module $modulePath -Force
}

# Transient outputs: never use bare relative paths (for example 'backup.dump' or 'CHANGELOG.md')
# at repository CWD — use Get-TestArtifactPath, New-TestTempDirectory, or New-TestTempFile.

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

### Using TestSupport Stubs

Use TestSupport stubs (not Pester `Mock`) to isolate units under test. Load TestSupport in `BeforeAll`:

```powershell
Describe 'Function with External Dependency' {
    BeforeAll {
        . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    }

    It 'should handle external command failure' {
        Set-TestCommandThrowingMock -CommandName 'mytool' -Message 'Execution failed'

        { MyFunction -Path 'test.txt' } | Should -Not -Throw
    }

    It 'should process command output correctly' {
        Setup-CapturingCommandMock -CommandName 'mytool' -Output @('line1', 'line2', 'line3')

        $result = MyFunction -Path 'test.txt'
        $result.Count | Should -Be 3
    }
}
```

See `docs/guides/TEST_VERIFICATION_MOCKING_GUIDE.md` for full stub patterns.

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

# Pass extra flags through task CLI_ARGS
task test-unit -- -TestName "*MyFunc*" -Quiet
task test-unit-batch -- -Filter profile-
task test-tools -- -RelativePath network
task test-conversion-batch -- -RelativePath data/compression
```

## Batch Runners

For large suites that can exhaust memory in a single PowerShell session, use the
per-file batch wrappers. Each spawns a separate `run-pester.ps1` process per
`*.tests.ps1` file and prints a summary table.

| Script | Task shortcut | Purpose |
|--------|---------------|---------|
| `run-unit-batch.ps1` | `task test-unit-batch` | Unit tests, one file per process |
| `run-performance-batch.ps1` | `task test-performance-batch` | Performance tests, one file per process |
| `run-tools-integration-batch.ps1` | `task test-tools` | Tools integration tests (per-file default) |
| `run-conversion-integration-batch.ps1` | `task test-conversion-batch` | Conversion integration tests |

```powershell
# Unit batch with optional name filter
pwsh -NoProfile -File scripts/utils/code-quality/run-unit-batch.ps1
pwsh -NoProfile -File scripts/utils/code-quality/run-unit-batch.ps1 -Filter profile- -Quiet

# Tools integration (per-file isolation by default)
pwsh -NoProfile -File scripts/utils/code-quality/run-tools-integration-batch.ps1
pwsh -NoProfile -File scripts/utils/code-quality/run-tools-integration-batch.ps1 -RelativePath network -Quiet

# Conversion integration (single session by default; use -PerFile for isolation)
pwsh -NoProfile -File scripts/utils/code-quality/run-conversion-integration-batch.ps1
pwsh -NoProfile -File scripts/utils/code-quality/run-conversion-integration-batch.ps1 -RelativePath data/compression -Parallel 4
```

Batch scripts forward a subset of flags (`-Quiet`, `-Parallel` on conversion batch).
For full runner features (coverage, retries, baselines), call `run-pester.ps1` directly
or use `task test -- <flags>`.

## Coverage Analysis

During development, `analyze-coverage.ps1` is the recommended entry point. It maps
source files to matching tests, runs Pester with coverage enabled, and reports per-file
coverage gaps:

```powershell
# Analyze bootstrap coverage (default path)
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1

# Analyze specific source paths
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path profile.d/00-bootstrap

# Multiple paths
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path profile.d/11-git.ps1,profile.d/02-files.ps1

# Custom report output directory
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path profile.d/bootstrap -OutputPath scripts/data/coverage
```

See [VERIFY_COVERAGE.md](VERIFY_COVERAGE.md) for interpretation guidance.

## Advanced Features

### Retry Logic

Handle flaky tests with automatic retries:

```powershell
# Retry failed tests up to 3 times
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -MaxRetries 3 -RetryOnFailure

# Suppress retry warning noise (logs retries at debug level instead)
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -MaxRetries 3 -SuppressRetryWarnings

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
# CI mode (Normal output, auto-coverage, NUnit XML results)
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -CI

# Treat warnings as failures (not enabled automatically by -CI)
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -CI -FailOnWarnings
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

## Exit Codes

The test runner provides granular exit codes:

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

### Stub Guidelines

- Stub external dependencies (commands, network, environment) via TestSupport helpers
- Don't stub the code under test
- Use `Setup-CapturingCommandMock` when verifying command arguments or output
- Prefer real temp directories (`TestDrive`, `Get-TestPath`) over stubbing filesystem cmdlets

See `docs/guides/TEST_VERIFICATION_MOCKING_GUIDE.md` for details.

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

#### Using Set-TestCommandAvailabilityState

For tests that need to verify behavior when tools are unavailable (even if the real binary exists on PATH):

```powershell
It 'Tests function when tool is unavailable' {
    Set-TestCommandAvailabilityState -CommandName 'docker' -Available $false

    # Test that function handles missing tool gracefully
    { Get-DockerInfo } | Should -Not -Throw
}
```

For multiple commands, prefer `Mark-TestCommandsUnavailable`:

```powershell
BeforeEach {
    Mark-TestCommandsUnavailable -CommandNames @('docker', 'podman', 'kubectl')
}
```

When real binaries on PATH would shadow stubs, also call `Clear-TestCachedCommandCache` in `BeforeEach`.

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

Use category prefixes so the target is obvious from the filename:

| Prefix | Target | Example |
|--------|--------|---------|
| `library-*` | `scripts/lib/` modules | `library-cache.tests.ps1` |
| `profile-*` | `profile.d/` fragments and bootstrap helpers | `profile-module-loading.tests.ps1` |
| `utility-*` | `scripts/utils/` scripts (non-lib) | `utility-docs-generation.tests.ps1` |
| `utility-debug-*` | `scripts/utils/debug/` scripts | `utility-debug-trace-testpath-extended.tests.ps1` |
| `validation-*` | `scripts/checks/` and validation scripts | `validation-idempotency.tests.ps1` |
| `test-runner-*` | Test runner modules/scripts | `test-runner-run-pester.tests.ps1` |
| `test-support*` | TestSupport modules | `test-support-paths.tests.ps1` |

Rules:

- Use **kebab-case**: `profile-command-cache-mgmt-extended.tests.ps1`
- Match the feature or module under test
- **`library-*` vs `profile-*`:** If the primary subject is a `profile.d` bootstrap/fragment file, use `profile-*` even when the test loads bootstrap helpers. Reserve `library-*` for `scripts/lib/` (or tests that primarily exercise lib modules). Hybrid tests that import both may stay `library-*` (e.g. `library-write-missing-tool-warning-message-extended.tests.ps1`).
- **`library-profile-*`:** Unit tests for `scripts/lib/profile/` modules (distinct from `profile-*` fragment tests).

**Integration Tests (`tests/integration/`):**

- Use descriptive names that match the feature/component
- **Drop redundant domain prefixes** when the folder already provides context:
  - `integration/bootstrap/helper-functions.tests.ps1` (not `bootstrap-helper-functions.tests.ps1`)
  - `integration/profile/loading.tests.ps1` (not `profile-loading.tests.ps1`)
  - `integration/test-runner/runner-integration.tests.ps1` (not `test-runner-integration.tests.ps1`)
- Use kebab-case: `fragment-loading.tests.ps1`
- Avoid basename collisions across suites (e.g. unit `profile-fragments-smoke.tests.ps1` vs integration `profile/fragments-integration.tests.ps1`)

**Performance Tests (`tests/performance/`):**

- Flat directory only (no subfolders)
- Include `performance` in the name: `beads-performance.tests.ps1`

#### Extended (`*-extended`) suffix

Many tests use a `-extended` suffix for additional edge-case or regression coverage:

- **Paired:** `validation-idempotency.tests.ps1` + `validation-idempotency-extended.tests.ps1`
- **Extended-only:** `utility-debug-check-profile-log-extended.tests.ps1` (no base file) — **valid** when the suite is intentionally scoped to extended scenarios only

Do not create empty base files solely to satisfy pairing. Prefer `-extended` when adding coverage that is clearly supplementary to an existing file, or when the entire file is edge-case focused.

#### Test Names (inside Describe/It blocks)

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
5. **Verify per-module coverage** - See [Coverage Verification](VERIFY_COVERAGE.md) for `analyze-coverage.ps1` workflows

## Related Testing Documentation

| Guide | Purpose |
| ----- | ------- |
| **[Testing Guide](TESTING.md)** (this doc) | Structure, running tests, runner flags, batch scripts, exit codes |
| [Development Guide](DEVELOPMENT.md) | Setup, workflow, advanced runner features |
| [Testing Patterns](../examples/TESTING_PATTERNS.md) | Copy-paste examples for writing tests |
| [Test Stub Guide](TEST_VERIFICATION_MOCKING_GUIDE.md) | TestSupport stubs, command capture, environment isolation |
| [Coverage Verification](VERIFY_COVERAGE.md) | `analyze-coverage.ps1` per-module verification |
| [Tool Requirements](TOOL_REQUIREMENTS.md) | Required and optional tools for test suites |
| [Development Quick Start](DEVELOPMENT_QUICK_START.md) | Fast profile reload during development |
| [Examples Index](../examples/README.md#testing-patterns) | All code examples including testing |
| [Contributing](../../CONTRIBUTING.md) | Validation workflow before commits |
| [AGENTS.md](../../AGENTS.md) | AI assistant testing guidelines |

**Runner entry points:**

- `scripts/utils/code-quality/run-pester.ps1` — main test runner
- `scripts/utils/code-quality/analyze-coverage.ps1` — development coverage analysis
- Batch wrappers — see [Batch Runners](#batch-runners)

**External:**

- [Pester Documentation](https://pester.dev/docs/quick-start)

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

# Batch runners (per-file isolation)
task test-unit-batch -- -Filter test-runner-
task test-tools -- -RelativePath network -Quiet

# Development coverage analysis
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path profile.d/bootstrap
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
