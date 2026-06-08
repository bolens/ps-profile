<#
tests/unit/profile-diagnostics-performance-extended.tests.ps1
#>
BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/diagnostics-modules/monitoring/diagnostics-performance.ps1'
}
Describe 'profile.d/diagnostics-modules/monitoring/diagnostics-performance.ps1 extended scenarios' {
    It 'Documents command timing and performance insights' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Performance insights diagnostic functions'
        $c | Should -Match 'Command timing, performance tracking'
    }
    It 'Defines Start-CommandTimer and Show-PerformanceInsights with global tracking' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Start-CommandTimer'
        $c | Should -Match 'Show-PerformanceInsights'
        $c | Should -Match 'PSProfileCommandTimings'
        $c | Should -Match 'PerformanceInsightsLoaded'
    }
    It 'Defines Update-PerformanceInsightsPrompt to wrap prompt timing' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Update-PerformanceInsightsPrompt'
        $c | Should -Match 'Test-PerformanceHealth'
        $c | Should -Match 'Clear-PerformanceData'
    }
}
