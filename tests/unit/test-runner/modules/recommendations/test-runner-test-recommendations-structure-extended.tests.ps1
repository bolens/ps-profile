<#
tests/unit/test-runner-test-recommendations-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestRecommendations.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestRecommendations.psm1 structure extended scenarios' {
    It 'Documents test recommendations utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test recommendations utilities'
        $c | Should -Match 'TestRecommendations.psm1'
    }
    It 'Defines Get-TestRecommendations helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-TestRecommendations'
        $c | Should -Match 'FailureAnalysis'
        $c | Should -Match 'PerformanceAnalysis'
    }
    It 'Exports recommendations function' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Export-ModuleMember -Function Get-TestRecommendations'
        $c | Should -Match 'FailedTests'
    }
}
