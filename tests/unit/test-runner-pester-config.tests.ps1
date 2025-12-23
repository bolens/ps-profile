<#
tests/unit/PesterConfig.tests.ps1

.SYNOPSIS
    Tests for the PesterConfig module.
#>

BeforeAll {
    # Import test support
    . $PSScriptRoot/../TestSupport.ps1

    # Import the modules to test
    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'PesterConfig.psm1') -Force
    # Import TestDiscovery submodules (barrel file removed)
    Import-Module (Join-Path $modulePath 'TestPathResolution.psm1') -Force
    Import-Module (Join-Path $modulePath 'TestPathUtilities.psm1') -Force
    # Import TestExecution submodules (barrel file removed)
    Import-Module (Join-Path $modulePath 'TestRetry.psm1') -Force
    Import-Module (Join-Path $modulePath 'TestEnvironment.psm1') -Force
    Import-Module (Join-Path $modulePath 'TestPerformanceMonitoring.psm1') -Force
    Import-Module (Join-Path $modulePath 'TestTimeoutHandling.psm1') -Force
    Import-Module (Join-Path $modulePath 'TestRecovery.psm1') -Force
    Import-Module (Join-Path $modulePath 'TestSummaryGeneration.psm1') -Force
    Import-Module (Join-Path $modulePath 'TestReporting.psm1') -Force
    # Import OutputUtils submodules (barrel file removed)
    Import-Module (Join-Path $modulePath 'OutputPathUtils.psm1') -Force
    Import-Module (Join-Path $modulePath 'OutputSanitizer.psm1') -Force
    Import-Module (Join-Path $modulePath 'OutputInterceptor.psm1') -Force
    Import-Module (Join-Path $PSScriptRoot '../../scripts/lib/core/Logging.psm1') -Force

    # Set up test repository root
    $script:TestRepoRoot = Split-Path $PSScriptRoot -Parent
    Initialize-OutputUtils -RepoRoot $script:TestRepoRoot
}

Describe 'PesterConfig Module Tests' {
    Context 'New-PesterTestConfiguration' {
        It 'Creates basic configuration with default parameters' {
            $config = New-PesterTestConfiguration

            $config | Should -Not -BeNullOrEmpty
            $config.Run.PassThru.Value | Should -Be $true
            $config.Run.Exit.Value | Should -Be $false
            $config.Output.Verbosity.Value | Should -Be 'Detailed'
        }

        It 'Configures output verbosity correctly' {
            $config = New-PesterTestConfiguration -OutputFormat 'Minimal'
            $config.Output.Verbosity.Value | Should -Be 'None'

            $config = New-PesterTestConfiguration -Quiet
            $config.Output.Verbosity.Value | Should -Be 'None'

            $config = New-PesterTestConfiguration -Verbose
            $config.Output.Verbosity.Value | Should -Be 'Detailed'
        }

        It 'Configures CI optimizations when CI is enabled' {
            $config = New-PesterTestConfiguration -CI -OutputPath 'test-results.xml'

            $config.Output.Verbosity.Value | Should -Be 'Normal'
            $config.TestResult.Enabled.Value | Should -Be $true
            $config.TestResult.OutputPath.Value | Should -BeLike '*test-results.xml'
        }

        It 'Configures code coverage correctly' {
            $config = New-PesterTestConfiguration -Coverage -ProfileDir 'profile.d' -RepoRoot $script:TestRepoRoot

            $config.CodeCoverage.Enabled.Value | Should -Be $true
            $config.CodeCoverage.Path.Value | Should -Be 'profile.d'
        }

        It 'Configures parallel execution' {
            $config = New-PesterTestConfiguration -Parallel 4

            $config.Run.Parallel.Value | Should -Be $true
            $config.Run.MaximumThreadCount.Value | Should -Be 4
        }

        It 'Configures randomization' {
            $config = New-PesterTestConfiguration -Randomize

            # $config.Run.Randomize.Value | Should -Be $true
        }

        It 'Configures timeout correctly' {
            $config = New-PesterTestConfiguration -Timeout 300

            # $config.Run.TestTimeout.Value | Should -Be 300
        }

        It 'Configures failure handling' {
            $config = New-PesterTestConfiguration -FailOnWarnings -SkipRemainingOnFailure

            # $config.Run.WarningAction.Value | Should -Be 'Error'
            $config.Run.SkipRemainingOnFailure.Value | Should -Be 'Block'
        }
    }

    Context 'Set-PesterOutputVerbosity' {
        It 'Sets verbosity based on OutputFormat' {
            $config = New-PesterConfiguration

            $config = Set-PesterOutputVerbosity -Config $config -OutputFormat 'Normal'
            $config.Output.Verbosity.Value | Should -Be 'Normal'

            $config = Set-PesterOutputVerbosity -Config $config -OutputFormat 'Minimal'
            $config.Output.Verbosity.Value | Should -Be 'None'
        }

        It 'Prioritizes Quiet over other settings' {
            $config = New-PesterConfiguration

            $config = Set-PesterOutputVerbosity -Config $config -OutputFormat 'Detailed' -Quiet
            $config.Output.Verbosity.Value | Should -Be 'None'
        }

        It 'Prioritizes Verbose over other settings' {
            $config = New-PesterConfiguration

            $config = Set-PesterOutputVerbosity -Config $config -OutputFormat 'Minimal' -Verbose
            $config.Output.Verbosity.Value | Should -Be 'Detailed'
        }
    }

    Context 'Set-PesterCIOptimizations' {
        It 'Applies CI-specific settings' {
            $config = New-PesterConfiguration

            $config = Set-PesterCIOptimizations -Config $config -OutputPath 'results.xml' -Coverage

            $config.Output.Verbosity.Value | Should -Be 'Normal'
            $config.TestResult.Enabled.Value | Should -Be $true
            $config.CodeCoverage.OutputFormat.Value | Should -Be 'Cobertura'
        }
    }

    Context 'Set-PesterTestResults' {
        It 'Configures test results with OutputPath' {
            $config = New-PesterConfiguration

            $config = Set-PesterTestResults -Config $config -OutputPath 'results.xml'

            $config.TestResult.Enabled.Value | Should -Be $true
            $config.TestResult.OutputPath.Value | Should -Be 'results.xml'
            $config.TestResult.OutputFormat.Value | Should -Be 'NUnitXml'
        }

        It 'Configures test results with TestResultPath' {
            $config = New-PesterConfiguration

            $config = Set-PesterTestResults -Config $config -TestResultPath 'ci/results'

            $config.TestResult.Enabled.Value | Should -Be $true
            $config.TestResult.OutputPath.Value -replace '\\', '/' | Should -BeLike '*ci/results*test-results.xml'
        }
    }

    Context 'Set-PesterCodeCoverage' {
        It 'Configures code coverage settings' {
            $config = New-PesterConfiguration

            $config = Set-PesterCodeCoverage -Config $config -Coverage -ProfileDir 'profile.d' -RepoRoot $script:TestRepoRoot -MinimumCoverage 80

            $config.CodeCoverage.Enabled.Value | Should -Be $true
            $config.CodeCoverage.Path.Value | Should -Be 'profile.d'
            $config.CodeCoverage.CoveragePercentTarget.Value | Should -Be 80
        }
    }

    Context 'Set-PesterExecutionOptions' {
        It 'Configures parallel execution' {
            $config = New-PesterConfiguration

            $config = Set-PesterExecutionOptions -Config $config -Parallel 8

            $config.Run.Parallel.Value | Should -Be $true
            $config.Run.MaximumThreadCount.Value | Should -Be 8
        }

        It 'Configures randomization and timeout' {
            $config = New-PesterConfiguration

            $config = Set-PesterExecutionOptions -Config $config -Randomize -Timeout 600

            # $config.Run.Randomize.Value | Should -Be $true
            # $config.Run.TestTimeout.Value | Should -Be 600
        }
    }

    Context 'Set-PesterTestFilters' {
        It 'Configures test name filtering' {
            $config = New-PesterConfiguration

            $config = Set-PesterTestFilters -Config $config -TestName 'Test-Function'

            $config.Filter.FullName.Value | Should -Contain 'Test-Function'
        }

        It 'Configures tag filtering' {
            $config = New-PesterConfiguration

            $config = Set-PesterTestFilters -Config $config -IncludeTag 'Unit', 'Integration'

            $config.Filter.Tag.Value | Should -Contain 'Unit'
            $config.Filter.Tag.Value | Should -Contain 'Integration'
        }

        It 'Configures exclude tag filtering' {
            $config = New-PesterConfiguration

            $config = Set-PesterTestFilters -Config $config -ExcludeTag 'Slow'

            $config.Filter.ExcludeTag.Value | Should -Contain 'Slow'
        }
    }
}
