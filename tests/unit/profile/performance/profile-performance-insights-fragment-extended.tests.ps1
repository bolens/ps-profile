<#
tests/unit/profile-performance-insights-fragment-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/performance-insights.ps1'
}
Describe 'profile.d/performance-insights.ps1 extended scenarios' {
    It 'Declares optional tier for command timing diagnostics' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: optional'
        $c | Should -Match 'Dependencies: bootstrap, env'
    }
    It 'Loads diagnostics-performance module from diagnostics-modules/monitoring' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'diagnostics-modules'
        $c | Should -Match 'diagnostics-performance\.ps1'
    }
    It 'Reports module load failures through Write-ProfileError when debug is enabled' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Write-ProfileError'
        $c | Should -Match 'performance-insights'
    }
}
