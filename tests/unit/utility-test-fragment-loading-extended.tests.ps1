<#
tests/unit/utility-test-fragment-loading-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Script = Join-Path $script:TestRepoRoot 'scripts/utils/fragment/test-fragment-loading.ps1'
}
Describe 'test-fragment-loading.ps1 extended scenarios' {
    It 'Smoke-tests migrated fragment loading without errors' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'smoke test'
        $c | Should -Match 'can be loaded without errors'
    }
    It 'Uses Exit-WithCode for validation failures' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'Exit-WithCode'
        $c | Should -Match 'EXIT_VALIDATION_FAILURE'
    }
    It 'Discovers fragments under profile.d' {
        $c = Get-Content -LiteralPath $script:Script -Raw
        $c | Should -Match 'profile\.d'
    }
}
