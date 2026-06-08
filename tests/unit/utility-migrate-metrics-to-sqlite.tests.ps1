<#
tests/unit/utility-migrate-metrics-to-sqlite.tests.ps1

.SYNOPSIS
    Behavioral unit tests for migrate-metrics-to-sqlite.ps1 setup validation.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:MigrateMetricsScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'database' 'migrate-metrics-to-sqlite.ps1'
    $ConfirmPreference = 'None'
}

Describe 'migrate-metrics-to-sqlite.ps1 execution' {
    It 'Reports setup error when PerformanceMetricsDatabase module is unavailable' {
        $result = Invoke-TestScriptFile -ScriptPath $script:MigrateMetricsScript

        $result.ExitCode | Should -BeIn @(1, 2, 3)
        $result.Output | Should -Match 'Performance Metrics Database|PerformanceMetricsDatabase|not found'
    }
}
