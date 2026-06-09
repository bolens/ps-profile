<#
tests/integration/test-runner/runner-integration.tests.ps1

.SYNOPSIS
    Integration tests for run-pester.ps1 flag handling using the real test runner.

.DESCRIPTION
    Validates that the production test runner accepts and processes CLI flags
    correctly via -DryRun and -ListTests modes (no full-suite execution).
#>

BeforeAll {
    . (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:RunPesterPath = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/run-pester.ps1'
    $script:DryRunTestFile = Join-Path $script:TestRepoRoot 'tests/unit/library/common/library-common.tests.ps1'

    if (-not (Test-Path -LiteralPath $script:RunPesterPath)) {
        throw "Test runner script not found at: $script:RunPesterPath"
    }

    function Clear-TestRunnerFlag {
        $env:PS_PROFILE_TEST_RUNNER_ACTIVE = $null
    }

    function Invoke-RunPesterDryRun {
        param([hashtable]$Parameters = @{})

        $defaults = @{
            DryRun   = $true
            Suite    = 'Unit'
            TestFile = $script:DryRunTestFile
        }

        foreach ($key in $defaults.Keys) {
            if (-not $Parameters.ContainsKey($key)) {
                $Parameters[$key] = $defaults[$key]
            }
        }

        return & $script:RunPesterPath @Parameters
    }
}

Describe 'Test Runner Integration (real run-pester.ps1)' {
    BeforeEach { Clear-TestRunnerFlag }

    Context 'Core execution flags' {
        It 'Completes dry run for each suite value' {
            foreach ($suite in @('All', 'Unit', 'Integration', 'Performance')) {
                { & $script:RunPesterPath -DryRun -Suite $suite -TestFile $script:DryRunTestFile } | Should -Not -Throw
            }
        }

        It 'Lists tests without executing them' {
            & $script:RunPesterPath -ListTests -Suite Unit -TestFile $script:DryRunTestFile 2>&1 | Out-Null
            $LASTEXITCODE | Should -Be 0
        }

        It 'Accepts output format and quiet switches' {
            foreach ($format in @('Normal', 'Detailed', 'Minimal', 'None')) {
                { Invoke-RunPesterDryRun @{ OutputFormat = $format } } | Should -Not -Throw
            }
            { Invoke-RunPesterDryRun @{ Quiet = $true } } | Should -Not -Throw
        }
    }

    Context 'Coverage and CI flags' {
        It 'Accepts coverage-related switches' {
            { Invoke-RunPesterDryRun @{ Coverage = $true; MinimumCoverage = 0 } } | Should -Not -Throw
            { Invoke-RunPesterDryRun @{ ShowCoverageSummary = $true } } | Should -Not -Throw
            { Invoke-RunPesterDryRun @{ CI = $true } } | Should -Not -Throw
        }
    }

    Context 'Performance and baseline flags' {
        It 'Accepts performance tracking switches' {
            { Invoke-RunPesterDryRun @{ TrackPerformance = $true } } | Should -Not -Throw
            { Invoke-RunPesterDryRun @{ TrackPerformance = $true; TrackMemory = $true; TrackCPU = $true } } | Should -Not -Throw
        }

        It 'Accepts baseline generation and comparison switches' {
            $baselinePath = Join-Path $TestDrive 'integration-baseline.json'
            { Invoke-RunPesterDryRun @{ GenerateBaseline = $true; BaselinePath = $baselinePath } } | Should -Not -Throw
            { Invoke-RunPesterDryRun @{ CompareBaseline = $true; BaselinePath = $baselinePath; BaselineThreshold = 10 } } | Should -Not -Throw
        }
    }

    Context 'Retry, timeout, and execution control flags' {
        It 'Accepts retry and timeout switches' {
            { Invoke-RunPesterDryRun @{ MaxRetries = 2; RetryOnFailure = $true; ExponentialBackoff = $true } } | Should -Not -Throw
            { Invoke-RunPesterDryRun @{ SuppressRetryWarnings = $true; MaxRetries = 1 } } | Should -Not -Throw
            { Invoke-RunPesterDryRun @{ Timeout = 300 } } | Should -Not -Throw
            { Invoke-RunPesterDryRun @{ TestTimeoutSeconds = 60 } } | Should -Not -Throw
        }

        It 'Accepts fail-fast and repeat switches' {
            { Invoke-RunPesterDryRun @{ FailFast = $true } } | Should -Not -Throw
            { Invoke-RunPesterDryRun @{ Repeat = 2 } } | Should -Not -Throw
            { Invoke-RunPesterDryRun @{ FailOnWarnings = $true } } | Should -Not -Throw
            { Invoke-RunPesterDryRun @{ Progress = $true } } | Should -Not -Throw
        }
    }

    Context 'Filtering and discovery flags' {
        It 'Accepts tag, category, and name filters' {
            { Invoke-RunPesterDryRun @{ TestName = '*library*' } } | Should -Not -Throw
            { Invoke-RunPesterDryRun @{ IncludeTag = 'Unit' } } | Should -Not -Throw
            { Invoke-RunPesterDryRun @{ ExcludeTag = 'Slow' } } | Should -Not -Throw
            { Invoke-RunPesterDryRun @{ OnlyCategories = 'Unit' } } | Should -Not -Throw
            { Invoke-RunPesterDryRun @{ ExcludeCategories = 'Slow' } } | Should -Not -Throw
            { Invoke-RunPesterDryRun @{ TestFilePattern = '*library-common*' } } | Should -Not -Throw
        }

        It 'Accepts parallel execution switches' {
            { Invoke-RunPesterDryRun @{ Parallel = 2 } } | Should -Not -Throw
            { Invoke-RunPesterDryRun @{ MaxParallelThreads = 4 } } | Should -Not -Throw
            { & $script:RunPesterPath -DryRun -Suite Unit -Randomize } | Should -Not -Throw
        }
    }

    Context 'Reporting and analysis flags' {
        It 'Accepts analysis and report switches' {
            $reportPath = Join-Path $TestDrive 'integration-report.html'
            { Invoke-RunPesterDryRun @{ AnalyzeResults = $true } } | Should -Not -Throw
            { Invoke-RunPesterDryRun @{ AnalyzeResults = $true; ReportFormat = 'HTML'; ReportPath = $reportPath; IncludeReportDetails = $true } } | Should -Not -Throw
            { Invoke-RunPesterDryRun @{ ShowSummaryStats = $true } } | Should -Not -Throw
        }
    }

    Context 'Git and configuration flags' {
        It 'Accepts git integration switches in a git repository' {
            Push-Location $script:TestRepoRoot
                        git rev-parse --git-dir 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) {
                { Invoke-RunPesterDryRun @{ ChangedFiles = $true } } | Should -Not -Throw
                { Invoke-RunPesterDryRun @{ ChangedSince = 'HEAD~1' } } | Should -Not -Throw
                { Invoke-RunPesterDryRun @{ ChangedFiles = $true; IncludeUntracked = $true } } | Should -Not -Throw
            }
        }
        finally {
            Pop-Location
        }

        It 'Saves and loads JSON configuration files' {
            $configPath = Join-Path $TestDrive 'integration-config.json'
            Invoke-RunPesterDryRun @{ Coverage = $true; Parallel = 2; SaveConfig = $configPath } 2>&1 | Out-Null

            if (Test-Path -LiteralPath $configPath) {
                { Invoke-RunPesterDryRun @{ ConfigFile = $configPath; Suite = 'Integration' } } | Should -Not -Throw
            }
        }
    }
}
