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

Tests are organized into three suites:

```
tests/
├── unit/              # Unit tests (*.tests.ps1)
├── integration/       # Integration tests (*.tests.ps1)
└── performance/      # Performance tests (*.tests.ps1)
└── TestSupport.ps1   # Shared test utilities
```

### Test File Naming

- **Unit tests**: `tests/unit/*.tests.ps1`
- **Integration tests**: `tests/integration/*.tests.ps1`
- **Performance tests**: `tests/performance/*.tests.ps1`

All test files must end with `.tests.ps1` to be discovered by the test runner.

### Test Support Utilities

The `tests/TestSupport.ps1` file provides shared utilities for all tests:

- `Get-TestRepoRoot` - Locates the repository root
- `Get-TestPath` - Resolves paths relative to the repository root
- `Get-TestSuitePath` - Gets paths to test suite directories
- `Get-TestSuiteFiles` - Enumerates test files in a suite
- `New-TestTempDirectory` - Creates temporary directories for tests
- `Invoke-TestPwshScript` - Executes scripts in isolated PowerShell processes
- `Get-PerformanceThreshold` - Resolves performance thresholds from environment variables

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
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Get-TestPath -RelativePath 'scripts/lib/PathResolution.psm1'
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
    . $PSScriptRoot/../TestSupport.ps1

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
    . $PSScriptRoot/../TestSupport.ps1

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

## Best Practices

### Test Organization

1. **One test file per module/component** - Keep tests focused and organized
2. **Use descriptive test names** - Test names should clearly describe what they verify
3. **Group related tests** - Use `Context` blocks to organize related tests
4. **Keep tests independent** - Tests should not depend on execution order

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

### Error Testing

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

### Test Data

- Use realistic test data
- Test edge cases (null, empty, very long, etc.)
- Use `New-TestTempDirectory` for file system tests
- Clean up test data in `AfterAll`

### Integration Test Guidelines

- Test real interactions between components
- Use isolated processes (`Invoke-TestPwshScript`) when needed
- Verify end-to-end workflows
- Test error recovery and edge cases

## Troubleshooting

### Tests Not Discovered

If tests aren't being discovered:

1. **Check file naming** - Files must end with `.tests.ps1`
2. **Check file location** - Files must be in `tests/unit/`, `tests/integration/`, or `tests/performance/`
3. **Check syntax** - Files must have valid PowerShell syntax
4. **Run with verbose output** - Use `-Verbose` to see discovery details

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
    . $PSScriptRoot/../TestSupport.ps1

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
