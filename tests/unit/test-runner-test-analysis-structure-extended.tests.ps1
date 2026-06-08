<#
tests/unit/test-runner-test-analysis-structure-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestAnalysis.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestAnalysis.psm1 structure extended scenarios' {
    It 'Documents test analysis utilities module' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TestAnalysis.psm1'
        $c | Should -Match 'analysis'
    }
    It 'Defines Analyze-TestTrends helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Analyze-TestTrends'
    }
    It 'Defines Get-ComprehensiveRecommendations helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-ComprehensiveRecommendations'
        $c | Should -Match 'Export-ModuleMember'
    }
}

