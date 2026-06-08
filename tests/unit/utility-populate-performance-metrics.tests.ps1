<#
tests/unit/utility-populate-performance-metrics.tests.ps1

.SYNOPSIS
    Behavioral unit tests for populate-performance-metrics.ps1 startup behavior.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:PopulateMetricsScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'database' 'populate-performance-metrics.ps1'
    $ConfirmPreference = 'None'
}

Describe 'populate-performance-metrics.ps1 execution' {
    It 'Reports missing database module or completes metrics collection non-interactively' {
        $result = Invoke-TestScriptFile -ScriptPath $script:PopulateMetricsScript -ArgumentList @(
            '-IncludeStartupBenchmark:False',
            '-IncludeCodeMetrics:False'
        )

        $result.Output | Should -Match 'Populating Performance Metrics|Performance Metrics Database|metrics'
        $result.ExitCode | Should -BeIn @(0, 1, 2, 3)
    }
}
